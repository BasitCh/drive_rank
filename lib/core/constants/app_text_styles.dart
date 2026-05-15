import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Typography tokens. Three font families:
///
/// - BebasNeue: display (big speed numbers, headers, brand wordmark)
/// - Outfit:    body (buttons, labels, paragraphs)
/// - JetBrainsMono: metadata (units, timestamps, tags, mono values)
///
/// Sizes match the HTML mock's px values for a 300dp-wide phone shell.
class AppTextStyles {
  const AppTextStyles._();

  static const String _display = 'BebasNeue';
  static const String _body = 'Outfit';
  static const String _mono = 'JetBrainsMono';

  // ----- DISPLAY (BebasNeue) -----

  /// Live tracking speed hero (96dp).
  static const TextStyle speedDisplay = TextStyle(
    fontFamily: _display,
    fontSize: 96,
    color: AppColors.textPrimary,
    letterSpacing: -1,
    height: 1,
  );

  /// Stat card top-speed number (60dp).
  static const TextStyle statCardSpeed = TextStyle(
    fontFamily: _display,
    fontSize: 60,
    color: AppColors.textPrimary,
    height: 1,
  );

  /// Splash screen ring number (80dp).
  static const TextStyle splashNumber = TextStyle(
    fontFamily: _display,
    fontSize: 80,
    color: Colors.white,
    height: 1,
  );

  /// Section headings on tab screens (32dp, e.g. "RANKINGS").
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _display,
    fontSize: 32,
    color: AppColors.textPrimary,
    letterSpacing: 1,
    height: 1,
  );

  /// Logo/wordmark in the live header (22dp).
  static const TextStyle brandLogo = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    color: AppColors.teal,
    letterSpacing: 1,
    height: 1,
  );

  /// Stat-card footer brand (16dp, half-opacity teal).
  static const TextStyle cardBrand = TextStyle(
    fontFamily: _display,
    fontSize: 16,
    color: AppColors.teal,
    letterSpacing: 1,
    height: 1,
  );

  // ----- BODY (Outfit) -----

  static const TextStyle headingLarge = TextStyle(
    fontFamily: _body,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _body,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.bg,
  );

  // ----- METADATA / MONO (JetBrainsMono) -----

  /// Tiny labels under stat cells (~8-9dp), all-caps, low contrast.
  static const TextStyle microLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 9,
    color: AppColors.textTertiary,
    letterSpacing: 0.08 * 9,
  );

  /// Slightly larger mono label (~10dp, e.g. section labels in analytics).
  static const TextStyle label = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    color: AppColors.textTertiary,
    letterSpacing: 0.06 * 10,
  );

  /// Teal-coloured mono tag (11dp), e.g. "BEST VALUE" or chips.
  static const TextStyle tag = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.teal,
  );

  /// The "km/h" / "mph" unit label under the speed hero (11dp, teal).
  static const TextStyle speedUnit = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    color: AppColors.teal,
  );
}
