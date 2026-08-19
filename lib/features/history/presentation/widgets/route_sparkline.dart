import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:flutter/material.dart';

/// Small route-shape icon for a History row — a speed-coloured
/// polyline sketch of the trip's path, matching the colour language
/// used everywhere else a speed is drawn (`SpeedBucket.color`).
///
/// Lazily fetches and downsamples the trip's waypoints on first
/// build. `History` renders these inside a lazy `ListView.separated`,
/// so only on-screen rows ever trigger a fetch.
class RouteSparkline extends StatefulWidget {
  const RouteSparkline({
    required this.tripId,
    this.size = const Size(48, 40),
    super.key,
  });

  final int tripId;
  final Size size;

  @override
  State<RouteSparkline> createState() => _RouteSparklineState();
}

class _RouteSparklineState extends State<RouteSparkline> {
  late final Future<List<TripPoint>> _future;

  /// Downsampled point cap — a row icon doesn't need full resolution,
  /// and capping keeps the fetch+paint cheap even for a long trip.
  static const int _maxPoints = 40;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TripPoint>> _load() async {
    final points = await getIt<TripRepository>().getWaypoints(widget.tripId);
    if (points.length <= _maxPoints) return points;
    final stride = points.length / _maxPoints;
    return [
      for (var i = 0; i < _maxPoints; i++) points[(i * stride).floor()],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: FutureBuilder<List<TripPoint>>(
        future: _future,
        builder: (context, snap) {
          final points = snap.data;
          if (points == null || points.length < 2) {
            return const SizedBox.shrink();
          }
          return CustomPaint(painter: _SparklinePainter(points: points));
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<TripPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    final spanLat = (maxLat - minLat) == 0 ? 1e-6 : (maxLat - minLat);
    final spanLng = (maxLng - minLng) == 0 ? 1e-6 : (maxLng - minLng);

    const pad = 4.0;
    Offset toScreen(TripPoint p) {
      final x = pad + ((p.lng - minLng) / spanLng) * (size.width - 2 * pad);
      final y =
          pad + (1 - (p.lat - minLat) / spanLat) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var prev = toScreen(points.first);
    for (var i = 1; i < points.length; i++) {
      final curr = toScreen(points[i]);
      final bucket = SpeedBucket.from(points[i].speedKmh);
      canvas.drawLine(prev, curr, paint..color = bucket.color);
      prev = curr;
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.points != points;
}
