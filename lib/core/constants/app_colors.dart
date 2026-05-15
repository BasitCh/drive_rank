import 'package:flutter/material.dart';

/// Design tokens for DriveRank.
///
/// Mirrors the CSS `:root` variables in the source-of-truth HTML mock.
/// See `assets/data/` README or memory for the mock path.
class AppColors {
  const AppColors._();

  // Backgrounds (dark-only for v1).
  static const Color bg = Color(0xFF050508);
  static const Color bg2 = Color(0xFF0D0D12);
  static const Color bg3 = Color(0xFF141419);
  static const Color card = Color(0xFF1A1A22);
  static const Color card2 = Color(0xFF202028);

  // Brand accent.
  static const Color teal = Color(0xFF3ECFBF);
  static const Color tealLight = Color(0x263ECFBF); // ~15% alpha
  static const Color tealDim = Color(0x0F3ECFBF); // ~6% alpha

  // Semantic.
  static const Color orange = Color(0xFFFF6B2B);
  static const Color blue = Color(0xFF4B9EFF);
  static const Color red = Color(0xFFFF3B3B);
  static const Color green = Color(0xFF30D158);
  static const Color yellow = Color(0xFFF5E642);

  // Text.
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E9A);
  static const Color textTertiary = Color(0xFF48484F);

  // Borders.
  static const Color border = Color(0x0FFFFFFF); // ~6% white
  static const Color border2 = Color(0x1FFFFFFF); // ~12% white
}
