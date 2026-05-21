import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter/material.dart';

/// The themed route preview strip on the live tracking screen.
///
/// 108dp tall, gradient background per [MapTheme], the trip's polyline
/// drawn on top, a tiny theme chip in the corner. Real OSM tiles arrive on
/// the trip-summary route map in Session 3 — for the live strip, a stylised
/// gradient is closer to the mock and noticeably faster on weak networks.
class RouteStrip extends StatelessWidget {
  const RouteStrip({required this.theme, required this.points, super.key});

  final MapTheme theme;
  final List<TripPoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg - 2,
        vertical: 6,
      ),
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(points: points, color: theme.routeColor),
            ),
          ),
          Positioned(
            top: 7,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${theme.glyph} ${theme.label.toUpperCase()}',
                style: AppTextStyles.microLabel.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 8,
                ),
              ),
            ),
          ),
        ],
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
    // While we have fewer than two fixes, draw a synthetic placeholder curve
    // so the strip never looks empty — mirrors the mock's GTA preview path.
    if (points.length < 2) {
      _paintPlaceholder(canvas, size);
      return;
    }

    final minLat = points.map((p) => p.lat).reduce((a, b) => a < b ? a : b);
    final maxLat = points.map((p) => p.lat).reduce((a, b) => a > b ? a : b);
    final minLng = points.map((p) => p.lng).reduce((a, b) => a < b ? a : b);
    final maxLng = points.map((p) => p.lng).reduce((a, b) => a > b ? a : b);

    final spanLat = (maxLat - minLat) == 0 ? 1e-6 : (maxLat - minLat);
    final spanLng = (maxLng - minLng) == 0 ? 1e-6 : (maxLng - minLng);

    const pad = 10.0;
    Offset toScreen(TripPoint p) {
      // Lat is north-positive; screen y is south-positive — flip it.
      final x = pad + ((p.lng - minLng) / spanLng) * (size.width - 2 * pad);
      final y =
          pad + (1 - (p.lat - minLat) / spanLat) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(toScreen(points.first).dx, toScreen(points.first).dy);
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
    canvas.drawPath(path, strokePaint);

    // Endpoint markers.
    final start = toScreen(points.first);
    final end = toScreen(points.last);
    canvas
      ..drawCircle(start, 3.5, Paint()..color = color.withValues(alpha: 0.5))
      ..drawCircle(end, 5, Paint()..color = AppColors.textPrimary);
  }

  void _paintPlaceholder(Canvas canvas, Size size) {
    final path = Path()..moveTo(10, size.height - 25);
    final pts = <Offset>[
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.45, size.height * 0.40),
      Offset(size.width * 0.65, size.height * 0.45),
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width - 10, size.height * 0.38),
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
