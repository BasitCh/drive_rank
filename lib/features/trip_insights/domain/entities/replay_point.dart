import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// One full-resolution sample for the Journey card's animated route
/// replay — position paired with the live stats the replay overlay
/// steps through (speed, cumulative distance, elapsed time).
///
/// Deliberately *not* decimated like the speed/elevation chart series:
/// the replay steps the vehicle marker through the actual recorded
/// waypoints, so skipping samples would make the marker "teleport"
/// across dense corners.
@immutable
class ReplayPoint {
  const ReplayPoint({
    required this.position,
    required this.speedKmh,
    required this.cumulativeDistanceKm,
    required this.secondsFromStart,
  });

  final LatLng position;
  final double speedKmh;
  final double cumulativeDistanceKm;
  final int secondsFromStart;
}
