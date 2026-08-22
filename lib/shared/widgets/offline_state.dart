import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Full "no internet" state for a single network-dependent screen (e.g.
/// `CloudSignInPage`) — as opposed to `ConnectivityBanner`, which is a
/// small persistent strip shown app-wide. Used only where the screen
/// genuinely cannot do anything without a connection; local-only features
/// (Drive, History, trip recording) never show this.
class OfflineState extends StatelessWidget {
  const OfflineState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.textTertiary,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          AppStrings.errorNoInternetTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.errorNoInternetBody,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
