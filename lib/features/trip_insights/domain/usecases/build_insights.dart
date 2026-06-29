import 'dart:math' as math;

import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_segment.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

/// Single precomputation pass: trip + waypoints + history → `InsightsBundle`.
///
/// All math lives here. Called once per page load by the bloc; widgets
/// then render off the cached result with zero work in `build()`.
///
/// Inputs are kept dumb (raw rows + raw point list) so this is trivially
/// unit-testable — no Drift, no platform, no injection.
@injectable
class BuildInsights {
  const BuildInsights(this._locale);

  final LocaleService _locale;

  /// Minimum waypoints for the speed-over-time chart to be meaningful.
  /// Below this, a single GPS hiccup dominates the smoothed line and
  /// the screenshot looks broken.
  static const int _chartMinWaypoints = 20;

  /// Below 60 s of recorded duration the bucket-time histogram divides
  /// down to noise — most trips that short are tap-tap-tap mistakes.
  static const int _breakdownMinDurationSeconds = 60;

  /// Centred moving-average window. Wider = smoother but loses peaks.
  ///
  /// Tuned for the Performance card aesthetic: the chart must look
  /// energetic — many peaks, frequent dips, a feeling that the trip
  /// was *fast*. A 2-point window damps single-sample GPS spikes but
  /// preserves the natural waveform. 5-point flattened too much and
  /// the share screenshot looked tame.
  static const int _smoothingWindow = 2;

  /// Hard cap on the number of bucket pairs produced by min-max
  /// decimation. With both a min and a max kept per bucket, the chart
  /// receives up to 2 * buckets points — `400` → ~800 points max. fl_chart
  /// renders a 5000-point polyline slowly enough on lower-end Android
  /// to make the back button feel broken (every back-tap queues behind
  /// the next paint frame). 800 points renders in a few ms.
  static const int _chartTargetBuckets = 400;

  /// Distance / duration / month thresholds for individual badges.
  static const double _longestRideMinKm = 5;
  static const int _fastestMonthlyMinDurationSeconds = 5 * 60;
  static const int _bestAvgMinDurationSeconds = 10 * 60;

  InsightsBundle call({
    required TripRow trip,
    required List<TripPoint> waypoints,
    required List<TripRow> otherTrips,
  }) {
    final rawSpeeds = waypoints
        .map((p) => p.speedKmh)
        .toList(growable: false);
    final smoothedSpeeds = _smooth(rawSpeeds);
    final smoothedSeconds = _secondsFromStart(waypoints);
    final (decimatedSpeeds, decimatedSeconds) = _decimate(
      smoothedSpeeds,
      smoothedSeconds,
      targetBuckets: _chartTargetBuckets,
    );
    final segments = _groupSegments(waypoints);
    final breakdown = _bucketTimes(waypoints);
    final records = _records(trip: trip, otherTrips: otherTrips);

    return InsightsBundle(
      trip: trip,
      smoothedSpeedKmh: decimatedSpeeds,
      smoothedSecondsFromStart: decimatedSeconds,
      segments: segments,
      breakdown: breakdown,
      records: records,
      bestAchievement: records.isEmpty ? null : records.first,
      chartEligible: waypoints.length >= _chartMinWaypoints,
      breakdownEligible:
          trip.durationSeconds >= _breakdownMinDurationSeconds &&
              breakdown.any((slice) => slice.secondsInBucket > 0),
      // User adjustment: records show as soon as there is even one
      // previous trip to compare against (was previously <2).
      recordsEligible: otherTrips.isNotEmpty,
    );
  }

  /// Min-max decimation: walk the smoothed series in buckets and keep
  /// the min + max from each bucket, in chronological order. Cuts a
  /// 5000-point series to ~800 points without erasing peaks — fl_chart
  /// renders fast and the silhouette of the trip stays intact, which
  /// is what makes the share screenshot read as energetic.
  (List<double>, List<int>) _decimate(
    List<double> speeds,
    List<int> seconds, {
    required int targetBuckets,
  }) {
    if (speeds.length <= targetBuckets * 2) return (speeds, seconds);
    final stride = math.max(1, speeds.length ~/ targetBuckets);
    final outSpeeds = <double>[];
    final outSeconds = <int>[];
    for (var i = 0; i < speeds.length; i += stride) {
      final end = math.min(i + stride, speeds.length);
      var minIdx = i;
      var maxIdx = i;
      for (var j = i + 1; j < end; j++) {
        if (speeds[j] < speeds[minIdx]) minIdx = j;
        if (speeds[j] > speeds[maxIdx]) maxIdx = j;
      }
      if (minIdx == maxIdx) {
        outSpeeds.add(speeds[minIdx]);
        outSeconds.add(seconds[minIdx]);
      } else if (minIdx < maxIdx) {
        outSpeeds
          ..add(speeds[minIdx])
          ..add(speeds[maxIdx]);
        outSeconds
          ..add(seconds[minIdx])
          ..add(seconds[maxIdx]);
      } else {
        outSpeeds
          ..add(speeds[maxIdx])
          ..add(speeds[minIdx]);
        outSeconds
          ..add(seconds[maxIdx])
          ..add(seconds[minIdx]);
      }
    }
    return (outSpeeds, outSeconds);
  }

  /// Centred 5-point moving average. Edge points use the available
  /// window (no truncation) so the output line has the same length as
  /// the input — fl_chart needs paired x/y arrays of equal length.
  List<double> _smooth(List<double> speeds) {
    if (speeds.length < _smoothingWindow) return List.of(speeds);
    const half = _smoothingWindow ~/ 2;
    final result = List<double>.filled(speeds.length, 0);
    for (var i = 0; i < speeds.length; i++) {
      final start = math.max(0, i - half);
      final end = math.min(speeds.length, i + half + 1);
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += speeds[j];
      }
      result[i] = sum / (end - start);
    }
    return result;
  }

  List<int> _secondsFromStart(List<TripPoint> waypoints) {
    if (waypoints.isEmpty) return const <int>[];
    final t0 = waypoints.first.timestamp;
    return waypoints
        .map((p) => p.timestamp.difference(t0).inSeconds)
        .toList(growable: false);
  }

  /// Walks the waypoints once, collapsing consecutive points whose
  /// speeds fall in the same `SpeedBucket` into one `SpeedSegment`.
  /// Each segment shares its boundary point with the next so the
  /// polyline colours touch instead of leaving a 1-pixel gap on the
  /// map render.
  List<SpeedSegment> _groupSegments(List<TripPoint> waypoints) {
    if (waypoints.length < 2) return const <SpeedSegment>[];
    final segments = <SpeedSegment>[];
    var currentBucket = SpeedBucket.from(waypoints.first.speedKmh);
    var currentPoints = <LatLng>[
      LatLng(waypoints.first.lat, waypoints.first.lng),
    ];

    for (var i = 1; i < waypoints.length; i++) {
      final w = waypoints[i];
      final bucket = SpeedBucket.from(w.speedKmh);
      final point = LatLng(w.lat, w.lng);
      if (bucket == currentBucket) {
        currentPoints.add(point);
        continue;
      }
      // Boundary crossing — close out the current segment with the
      // upcoming point as its terminal vertex so the colour transition
      // is gap-free, then start the new segment at the same vertex.
      currentPoints.add(point);
      segments.add(
        SpeedSegment(bucket: currentBucket, points: currentPoints),
      );
      currentBucket = bucket;
      currentPoints = <LatLng>[point];
    }
    if (currentPoints.length >= 2) {
      segments.add(
        SpeedSegment(bucket: currentBucket, points: currentPoints),
      );
    }
    return segments;
  }

  /// Time-in-bucket histogram from consecutive-pair durations.
  ///
  /// Pairs with a delta over 60 s are skipped — they're either GPS
  /// dropouts or paused-and-resumed segments, both of which would
  /// inflate the bucket the user happened to be in when paused.
  List<SpeedBreakdownSlice> _bucketTimes(List<TripPoint> waypoints) {
    final acc = <SpeedBucket, double>{
      for (final b in SpeedBucket.values) b: 0,
    };
    for (var i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final dt =
          b.timestamp.difference(a.timestamp).inMilliseconds / 1000.0;
      if (dt <= 0 || dt > 60) continue;
      final mean = (a.speedKmh + b.speedKmh) / 2;
      final bucket = SpeedBucket.from(mean);
      acc[bucket] = (acc[bucket] ?? 0) + dt;
    }
    final total = acc.values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) {
      return [
        for (final b in SpeedBucket.values)
          SpeedBreakdownSlice(
            bucket: b,
            secondsInBucket: 0,
            percentage: 0,
          ),
      ];
    }
    return [
      for (final b in SpeedBucket.values)
        SpeedBreakdownSlice(
          bucket: b,
          secondsInBucket: acc[b] ?? 0,
          percentage: (acc[b] ?? 0) / total,
        ),
    ];
  }

  /// Compares `trip` against `otherTrips` and returns the records it
  /// earned, most-impressive first. Empty list = strong-but-not-best
  /// drive; the widget shows an empty-state hint instead of a stub.
  List<PersonalRecord> _records({
    required TripRow trip,
    required List<TripRow> otherTrips,
  }) {
    final records = <PersonalRecord>[];

    final bestTopSpeed = _maxOrZero(otherTrips.map((t) => t.topSpeedKmh));
    final bestDistance = _maxOrZero(otherTrips.map((t) => t.distanceKm));
    final bestAvgSpeed = _maxOrZero(
      otherTrips.where(
        (t) => t.durationSeconds >= _bestAvgMinDurationSeconds,
      ).map((t) => t.avgSpeedKmh),
    );

    if (trip.topSpeedKmh > bestTopSpeed) {
      records.add(
        PersonalRecord(
          kind: RecordKind.newPersonalBest,
          valueDisplay: _locale.formatSpeed(trip.topSpeedKmh),
        ),
      );
    }
    if (trip.distanceKm >= _longestRideMinKm &&
        trip.distanceKm > bestDistance) {
      records.add(
        PersonalRecord(
          kind: RecordKind.longestRide,
          valueDisplay: _locale.formatDistance(trip.distanceKm),
        ),
      );
    }
    if (trip.durationSeconds >= _bestAvgMinDurationSeconds &&
        trip.avgSpeedKmh > bestAvgSpeed) {
      records.add(
        PersonalRecord(
          kind: RecordKind.bestAverageSpeed,
          valueDisplay: _locale.formatSpeed(trip.avgSpeedKmh),
        ),
      );
    }
    if (trip.durationSeconds >= _fastestMonthlyMinDurationSeconds) {
      final monthBest = _maxOrZero(
        otherTrips
            .where((t) => _isSameLocalMonth(t.startedAt, trip.startedAt))
            .map((t) => t.topSpeedKmh),
      );
      if (trip.topSpeedKmh > monthBest) {
        records.add(
          PersonalRecord(
            kind: RecordKind.fastestThisMonth,
            valueDisplay: _locale.formatSpeed(trip.topSpeedKmh),
          ),
        );
      }
    }
    // Fallback "Personal Record" — only when nothing above fired, but
    // the trip still ranks in the user's top 3 by some metric. Keeps
    // the section from going empty for a strong drive.
    if (records.isEmpty && otherTrips.length >= 3) {
      final topSpeedRank = _rank(
        trip.topSpeedKmh,
        otherTrips.map((t) => t.topSpeedKmh),
      );
      final distanceRank = _rank(
        trip.distanceKm,
        otherTrips.map((t) => t.distanceKm),
      );
      if (topSpeedRank <= 3 || distanceRank <= 3) {
        records.add(
          PersonalRecord(
            kind: RecordKind.personalRecord,
            valueDisplay: _locale.formatSpeed(trip.topSpeedKmh),
          ),
        );
      }
    }
    return records;
  }

  double _maxOrZero(Iterable<double> values) {
    var best = 0.0;
    for (final v in values) {
      if (v > best) best = v;
    }
    return best;
  }

  /// 1-indexed rank of `value` among `others` (treats `value` itself as
  /// not present). Used by the catch-all "Personal Record" fallback.
  int _rank(double value, Iterable<double> others) {
    var beaten = 0;
    for (final v in others) {
      if (v >= value) beaten += 1;
    }
    return beaten + 1;
  }

  bool _isSameLocalMonth(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month;
  }
}
