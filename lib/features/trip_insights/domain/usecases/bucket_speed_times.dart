import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';

/// Time-in-bucket histogram from consecutive-pair durations.
///
/// Pairs with a delta over 60 s are skipped — they're either GPS
/// dropouts or paused-and-resumed segments (or, for a lifetime
/// aggregate walking concatenated trips, a trip boundary — every one of
/// those exceeds 60s too), both of which would inflate the bucket the
/// user happened to be in when paused. Pairs where both samples are at
/// the GPS noise floor (zero speed, no distance covered — a red light,
/// a stop sign, standing still) are skipped too: that's idle time, not
/// a speed the driver was doing, and counting it as "under 40 km/h"
/// skews the whole distribution toward a bucket that's really just
/// "not moving".
///
/// Shared between `BuildInsights` (per-trip, in its own isolate) and
/// `TripStatsService.lifetimeSpeedBreakdown` (all trips concatenated, in
/// its own isolate) — same contract, same `SpeedBucket` definitions.
List<SpeedBreakdownSlice> bucketSpeedTimes(List<TripPoint> waypoints) {
  final acc = <SpeedBucket, double>{for (final b in SpeedBucket.values) b: 0};
  for (var i = 0; i < waypoints.length - 1; i++) {
    final a = waypoints[i];
    final b = waypoints[i + 1];
    final dt = b.timestamp.difference(a.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0 || dt > 60) continue;
    if (a.speedKmh <= 0 && b.speedKmh <= 0) continue;
    final mean = (a.speedKmh + b.speedKmh) / 2;
    final bucket = SpeedBucket.from(mean);
    acc[bucket] = (acc[bucket] ?? 0) + dt;
  }
  final total = acc.values.fold<double>(0, (s, v) => s + v);
  if (total <= 0) {
    return [
      for (final b in SpeedBucket.values)
        SpeedBreakdownSlice(bucket: b, secondsInBucket: 0, percentage: 0),
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
