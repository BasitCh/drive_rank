import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// One of the six map themes the user can pick during onboarding (and later
/// change in settings). Each theme renders the route map differently — by
/// swapping the tile provider URL and an optional colour filter — but for
/// preview thumbnails and the live-tracking strip we use a gradient that
/// echoes the theme's character.
enum MapTheme {
  regular,
  pixel,
  cyber,
  gta,
  west,
  dark;

  /// Persistence key used in the `UserSettings` table. Stable across renames.
  String get id => name;

  /// Display label.
  String get label => switch (this) {
    MapTheme.regular => AppStrings.mapThemeRegular,
    MapTheme.pixel => AppStrings.mapThemePixel,
    MapTheme.cyber => AppStrings.mapThemeCyber,
    MapTheme.gta => AppStrings.mapThemeGta,
    MapTheme.west => AppStrings.mapThemeWest,
    MapTheme.dark => AppStrings.mapThemeDark,
  };

  /// Emoji used in the picker chip thumbnails.
  String get glyph => switch (this) {
    MapTheme.regular => '🗺️',
    MapTheme.pixel => '🌿',
    MapTheme.cyber => '🌆',
    MapTheme.gta => '🎮',
    MapTheme.west => '🤠',
    MapTheme.dark => '🌑',
  };

  /// The gradient used for the preview strip and chip thumbnail. Real OSM
  /// tile rendering replaces this on the trip-summary route map in Session 3.
  LinearGradient get gradient => switch (this) {
    MapTheme.regular => const LinearGradient(
      colors: [Color(0xFF1A3A4A), Color(0xFF2E5E72)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    MapTheme.pixel => const LinearGradient(
      colors: [Color(0xFF5D8A3C), Color(0xFF7AB54A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    MapTheme.cyber => const LinearGradient(
      colors: [Color(0xFF1A0A2E), Color(0xFF8B00FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    MapTheme.gta => const LinearGradient(
      colors: [Color(0xFFFF6600), Color(0xFFCC3300), Color(0xFF8B0000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    MapTheme.west => const LinearGradient(
      colors: [Color(0xFF8B7355), Color(0xFFD4A76A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    MapTheme.dark => const LinearGradient(
      colors: [Color(0xFF111111), Color(0xFF222222)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  /// Colour for the route polyline drawn over the gradient (white-ish for
  /// dark themes, dark for light themes).
  Color get routeColor => switch (this) {
    MapTheme.pixel || MapTheme.west => AppColors.bg,
    _ => Colors.white.withValues(alpha: 0.85),
  };

  static MapTheme fromId(String id) =>
      MapTheme.values.firstWhere((t) => t.id == id, orElse: () => regular);
}
