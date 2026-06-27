import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// A run of consecutive waypoints that fell into the same [SpeedBucket].
///
/// One [SpeedSegment] → one `Polyline` on the intensity map. Grouping
/// thousands of waypoints into a few dozen segments is how the map stays
/// smooth: a 5000-point trip becomes ~30–80 polylines, which flutter_map
/// renders in a single frame without stutter.
///
/// Each segment shares a boundary point with the next (the join vertex
/// is the same `LatLng` in both lists). That's a deliberate seam-hider —
/// without it the colour transitions render with a 1-pixel gap.
@immutable
class SpeedSegment {
  const SpeedSegment({required this.bucket, required this.points});

  final SpeedBucket bucket;
  final List<LatLng> points;
}
