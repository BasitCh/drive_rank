import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Analytics block shown below the stat card on the trip summary page.
///
/// MVP scope dropped the leaderboard — the old "your rank" tile was a
/// dead `—` placeholder confusing users, so it's gone. Three tiles in
/// a single row reads cleaner than 2x2 with one dead cell.
///
/// Both counter tiles run through [_sanityCap] before rendering. Trips
/// recorded before v1.1.6 hold physically impossible values (10 000+
/// hard corners on a 5-minute drive from a 100 Hz noisy sensor stream);
/// the raw rows aren't rewritten, but at display time we cap anything
/// whose per-minute rate is above the "clearly broken" threshold at
/// a plausible-driving rate. New trips post-v1.1.6 come in well under
/// the threshold and render as-is.
class AnalyticsGrid extends StatelessWidget {
  const AnalyticsGrid({
    required this.hardCorners,
    required this.hardBrakes,
    required this.durationSeconds,
    required this.fuelCostFormatted,
    super.key,
  });

  final int hardCorners;
  final int hardBrakes;

  /// Trip duration — the denominator for the rate-based sanity cap.
  final int durationSeconds;

  /// Pre-formatted via `LocaleService.formatCurrency`, or `—` if the user
  /// hasn't configured fuel.
  final String fuelCostFormatted;

  /// Duration-aware sanity cap. Real drivers, even aggressive ones,
  /// stay well below `hardEventBrokenThresholdPerMinute` events per
  /// minute. Anything past that was produced by the pre-v1.1.6 counter
  /// bug — replace with the plausible-driving cap so testers stop
  /// screenshotting the taunt.
  int _sanityCap(int count) {
    final minutes = math.max(1, durationSeconds / 60.0);
    final ratePerMinute = count / minutes;
    if (ratePerMinute <= AppConstants.hardEventBrokenThresholdPerMinute) {
      return count;
    }
    return (minutes * AppConstants.hardEventDisplayCapPerMinute).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tripSummaryDriveAnalytics,
          style: AppTextStyles.label.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Item(
              value: _sanityCap(hardCorners).toString(),
              label: AppStrings.tripSummaryHardCorners,
              color: AppColors.orange,
            ),
            const SizedBox(width: 6),
            _Item(
              value: _sanityCap(hardBrakes).toString(),
              label: AppStrings.tripSummaryHardBrakes,
              color: AppColors.blue,
            ),
            const SizedBox(width: 6),
            _Item(
              value: fuelCostFormatted,
              label: AppStrings.trackingFuelCost,
              color: AppColors.green,
            ),
          ],
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.microLabel.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
