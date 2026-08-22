import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';

/// Fastest 0→100 km/h run: for each near-standstill sample (≤5 km/h,
/// the "start line"), the elapsed time to the next sample reaching
/// 100 km/h. Reports the minimum across every such run in the trip —
/// a spirited trip usually has several accelerations from a stop.
///
/// Shared between `BuildInsights` (per-trip display, computed on the fly
/// in an isolate) and `TripRepository.saveTrip` (persisted once at save
/// time so lifetime "best 0-100" aggregation doesn't need to re-walk
/// every trip's waypoints on every Profile load).
double? zeroToHundredSecondsFrom(List<TripPoint> waypoints) {
  double? best;
  DateTime? startLine;
  for (final p in waypoints) {
    if (p.speedKmh <= 5) {
      startLine = p.timestamp;
    } else if (p.speedKmh >= 100 && startLine != null) {
      final dt = p.timestamp.difference(startLine).inMilliseconds / 1000.0;
      if (dt > 0 && (best == null || dt < best)) best = dt;
      startLine = null;
    }
  }
  return best;
}
