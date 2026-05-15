import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter/material.dart';

/// 100dp themed header on the stat card with the trip's route drawn on top.
///
/// Uses the same gradient-and-painter approach as the live tracking strip
/// — the trade-off vs flutter_map tiles is intentional: this widget must
/// render reliably inside a `RepaintBoundary` at 3× pixel ratio for export,
/// which live tiles can't guarantee (network, attribution placement). The
/// trip summary page renders a fuller OSM-tiled map below the card when
/// online; the card itself stays bulletproof.
class RouteMapHeader extends StatelessWidget {
  const RouteMapHeader({
    required this.theme,
    required this.points,
    required this.carTag,
    super.key,
    this.weatherTag,
    this.height = 100,
  });

  final MapTheme theme;
  final List<TripPoint> points;
  final String carTag;
  final String? weatherTag;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: theme.gradient),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(
                points: points,
                color: theme.routeColor,
              ),
            ),
          ),
          // Bottom-blend overlay — fades the gradient into the card body.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1.0],
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0E0E18).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 10,
            child: _PillTag(text: carTag),
          ),
          if (weatherTag != null)
            Positioned(
              top: 8,
              right: 10,
              child: _PillTag(
                text: weatherTag!,
                textOpacity: 0.8,
              ),
            ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.text, this.textOpacity = 1.0});

  final String text;
  final double textOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: textOpacity),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.points, required this.color});

  final List<TripPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      _paintPlaceholder(canvas, size);
      return;
    }

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

    const pad = 12.0;
    Offset toScreen(TripPoint p) {
      final x = pad + ((p.lng - minLng) / spanLng) * (size.width - 2 * pad);
      final y =
          pad + (1 - (p.lat - minLat) / spanLat) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final path = Path();
    final first = toScreen(points.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final o = toScreen(points[i]);
      path.lineTo(o.dx, o.dy);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(path, strokePaint)
      ..drawCircle(
        toScreen(points.first),
        3.5,
        Paint()..color = color.withValues(alpha: 0.5),
      )
      ..drawCircle(
        toScreen(points.last),
        5,
        Paint()..color = AppColors.textPrimary,
      );
  }

  void _paintPlaceholder(Canvas canvas, Size size) {
    final path = Path()..moveTo(10, size.height - 20);
    final pts = <Offset>[
      Offset(size.width * 0.25, size.height * 0.62),
      Offset(size.width * 0.45, size.height * 0.42),
      Offset(size.width * 0.65, size.height * 0.48),
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width - 10, size.height * 0.36),
    ];
    for (final p in pts) {
      path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(path, paint)
      ..drawCircle(pts.last, 5, Paint()..color = AppColors.textPrimary);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.points.length != points.length || old.color != color;
}
