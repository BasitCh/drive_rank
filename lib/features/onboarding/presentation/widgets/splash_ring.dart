import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// The 200dp animated speedometer ring on the splash screen.
///
/// Two concentric stroked circles, 18 tick marks around the perimeter, and
/// a teal arc that fills proportionally to the speed value. The `value`
/// parameter is normalised 0..1 (animated by the parent on screen entry).
class SplashRing extends StatelessWidget {
  const SplashRing({
    required this.child,
    required this.value,
    super.key,
  });

  /// 0..1 — controls how far the teal arc has swept.
  final double value;

  /// Centre content — typically the BebasNeue number + "km/h" stack.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.10),
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          CustomPaint(
            size: const Size.square(200),
            painter: _RingPainter(value: value),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final majorPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.60)
      ..strokeWidth = 2;
    final minorPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (var i = 0; i < 18; i++) {
      final angle = (i * 20) * math.pi / 180 - math.pi / 2;
      final isMajor = i.isEven;
      final p = isMajor ? majorPaint : minorPaint;
      final inner = isMajor ? radius - 18 : radius - 14;
      final outer = radius - 8;
      final c = math.cos(angle);
      final s = math.sin(angle);
      canvas.drawLine(
        centre + Offset(c * inner, s * inner),
        centre + Offset(c * outer, s * outer),
        p,
      );
    }

    final arcPaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2 + math.pi / 4;
    final sweep = (2 * math.pi - math.pi / 2) * value.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius - 6),
      start,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
