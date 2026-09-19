import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/painting.dart';

/// The Rankings screen's display type: Unbounded, a wide heavy face, for
/// the title and every rank numeral — so a place reads as a place, not
/// as another figure beside the distance.
abstract final class RankType {
  static const String family = 'Unbounded';

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation('wght', 800)],
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle numeral({required double size, required Color color}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
        color: color,
      );
}

/// Medal colours, shared by a podium place's ring, figure and pedestal.
abstract final class MedalColors {
  static const Color gold = Color(0xFFF5C542);
  static const Color silver = Color(0xFFC7CBD4);
  static const Color bronze = Color(0xFFD9904F);
}
