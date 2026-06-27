import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Bottom watermark on the social card. Kept deliberately subtle — the
/// wordmark and tagline read once and stay out of the way of the
/// analytics above. The brand sets the context, not the focus.
class InsightsBrandFooter extends StatelessWidget {
  const InsightsBrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            AppStrings.appName,
            style: AppTextStyles.brandLogo.copyWith(
              fontSize: 14,
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
      ),
    );
  }
}
