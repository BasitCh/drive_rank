import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Bottom watermark on the social cards. Deliberately understated so
/// the chart / map stay the hero — the wordmark sets brand context,
/// not focus. The tagline "Every drive has a story." reads once and
/// stays out of the way.
class CardBrandFooter extends StatelessWidget {
  const CardBrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.appName.toUpperCase(),
          style: AppTextStyles.brandLogo.copyWith(
            fontSize: 12,
            letterSpacing: 3,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Every drive has a story.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
