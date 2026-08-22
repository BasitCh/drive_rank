import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:drive_rank/features/trip_insights/domain/usecases/bucket_speed_times.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';

/// Aggregations over the trips table — distinct from `TripRepository`
/// because these compute roll-ups (sums, maxes, most-active-day) rather
/// than returning rows.
@lazySingleton
class TripStatsService {
  TripStatsService(this._trips);

  final TripRepository _trips;

  /// Aggregates all trips for the given calendar month. Returns an empty
  /// report if there are none.
  Future<MonthlyReport> monthlyReport({
    required String uid,
    required int year,
    required int month,
  }) async {
    final trips = await _trips.getTripsInMonth(
      uid: uid,
      year: year,
      month: month,
    );
    if (trips.isEmpty) return MonthlyReport.empty(year, month);
    return _aggregateMonthly(trips, year, month);
  }

  /// Total distance per calendar month for the last [months] months
  /// (including the current one), oldest first. Months with no trips
  /// are omitted entirely — the caller renders whatever comes back,
  /// no empty bars.
  Future<List<MonthlyDistanceStat>> monthlyDistanceTrend({
    required String uid,
    int months = 6,
  }) async {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month - (months - 1));
    final trips = await _trips.getTripsSince(uid: uid, since: anchor);

    final totals = <String, double>{};
    for (final t in trips) {
      final key = '${t.startedAt.year}-${t.startedAt.month}';
      totals[key] = (totals[key] ?? 0) + t.distanceKm;
    }

    final result = <MonthlyDistanceStat>[];
    for (var i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      final km = totals['${d.year}-${d.month}'];
      if (km != null && km > 0) {
        result.add(
          MonthlyDistanceStat(year: d.year, month: d.month, distanceKm: km),
        );
      }
    }
    return result;
  }

  /// Cross-trip totals for the profile screen.
  Future<LifetimeStats> lifetime({required String uid}) async {
    final all = await _trips.watchAll(uid: uid).first;
    if (all.isEmpty) return LifetimeStats.empty();
    var distance = 0.0;
    var topSpeed = 0.0;
    var bestG = 0.0;
    var duration = 0;
    var stoppedSeconds = 0;
    var stopCount = 0;
    double? bestZeroToHundred;
    var leftTurns = 0;
    var rightTurns = 0;
    var laneChanges = 0;
    var hardBrakes = 0;
    var bestAccel = 0.0;
    var bestDecel = 0.0;
    var bestCorneringSpeed = 0.0;
    for (final t in all) {
      distance += t.distanceKm;
      duration += t.durationSeconds;
      stoppedSeconds += t.stoppedSeconds;
      stopCount += t.stopCount;
      leftTurns += t.leftTurnCount;
      rightTurns += t.rightTurnCount;
      laneChanges += t.laneChangeCount;
      hardBrakes += t.hardBrakesCount;
      if (t.topSpeedKmh > topSpeed) topSpeed = t.topSpeedKmh;
      if (t.maxGforce > bestG) bestG = t.maxGforce;
      if (t.maxAccelerationMps2 > bestAccel) bestAccel = t.maxAccelerationMps2;
      if (t.maxDecelerationMps2 > bestDecel) bestDecel = t.maxDecelerationMps2;
      if (t.topCorneringSpeedKmh > bestCorneringSpeed) {
        bestCorneringSpeed = t.topCorneringSpeedKmh;
      }
      final zth = t.zeroToHundredSeconds;
      if (zth != null && (bestZeroToHundred == null || zth < bestZeroToHundred)) {
        bestZeroToHundred = zth;
      }
    }
    return LifetimeStats(
      tripCount: all.length,
      totalDistanceKm: distance,
      topSpeedKmh: topSpeed,
      bestGforce: bestG,
      totalDurationSeconds: duration,
      totalStoppedSeconds: stoppedSeconds,
      totalStopCount: stopCount,
      bestZeroToHundredSeconds: bestZeroToHundred,
      totalLeftTurns: leftTurns,
      totalRightTurns: rightTurns,
      totalLaneChanges: laneChanges,
      totalHardBrakes: hardBrakes,
      bestMaxAcceleration: bestAccel,
      bestMaxDeceleration: bestDecel,
      bestCorneringSpeedKmh: bestCorneringSpeed,
    );
  }

  /// Lifetime speed-distribution breakdown — same `SpeedBucket` contract
  /// as the per-trip breakdown in `BuildInsights._bucketTimes`, just run
  /// across every trip's waypoints instead of one. Walks every waypoint
  /// of every trip, so this runs in a background isolate via
  /// `_lifetimeSpeedBreakdown` (a pure top-level function — no
  /// `LocaleService`/DI access inside the isolate).
  Future<List<SpeedBreakdownSlice>> lifetimeSpeedBreakdown({
    required String uid,
  }) async {
    final trips = await _trips.watchAll(uid: uid).first;
    final allWaypoints = <TripPoint>[];
    for (final t in trips) {
      // Waypoints are per-trip contiguous sequences — concatenating them
      // is safe for the bucket walk below because it already skips any
      // consecutive pair with `dt > 60s` (which every trip boundary
      // exceeds) or both-stationary, so no cross-trip pair ever
      // contributes a bogus bucket sample.
      allWaypoints.addAll(await _trips.getWaypoints(t.id));
    }
    if (allWaypoints.isEmpty) return const <SpeedBreakdownSlice>[];
    return compute(_lifetimeSpeedBreakdown, allWaypoints);
  }

  MonthlyReport _aggregateMonthly(List<TripRow> trips, int year, int month) {
    var distance = 0.0;
    var duration = 0;
    var topSpeed = 0.0;
    var bestG = 0.0;
    final perWeekday = <int, int>{};
    for (final t in trips) {
      distance += t.distanceKm;
      duration += t.durationSeconds;
      if (t.topSpeedKmh > topSpeed) topSpeed = t.topSpeedKmh;
      if (t.maxGforce > bestG) bestG = t.maxGforce;
      perWeekday.update(t.startedAt.weekday, (n) => n + 1, ifAbsent: () => 1);
    }
    int? mostActive;
    var bestCount = -1;
    perWeekday.forEach((day, count) {
      if (count > bestCount) {
        bestCount = count;
        mostActive = day;
      }
    });
    return MonthlyReport(
      year: year,
      month: month,
      tripCount: trips.length,
      totalDistanceKm: distance,
      totalDurationSeconds: duration,
      topSpeedKmh: topSpeed,
      bestGforce: bestG,
      mostActiveWeekday: mostActive,
    );
  }
}

/// Isolate entry point for `TripStatsService.lifetimeSpeedBreakdown` —
/// a pure top-level function (no `LocaleService`/DI access) so it's
/// safe to run via `compute()`.
List<SpeedBreakdownSlice> _lifetimeSpeedBreakdown(List<TripPoint> waypoints) =>
    bucketSpeedTimes(waypoints);
