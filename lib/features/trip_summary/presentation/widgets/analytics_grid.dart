import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 2-column analytics block shown below the stat card on the trip summary
/// page. Mirrors the mock's `.analytics-2col` grid.
class AnalyticsGrid extends StatelessWidget {
  const AnalyticsGrid({
    required this.hardCorners,
    required this.hardBrakes,
    required this.fuelCostFormatted,
    required this.rankLabel,
    super.key,
  });

  final int hardCorners;
  final int hardBrakes;

  /// Pre-formatted via `LocaleService.formatCurrency`, or `—` if the user
  /// hasn't configured fuel.
  final String fuelCostFormatted;

  /// e.g. "#12 PK" — pre-formatted by the caller.
  final String rankLabel;

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
              value: hardCorners.toString(),
              label: AppStrings.tripSummaryHardCorners,
              color: AppColors.orange,
            ),
            const SizedBox(width: 6),
            _Item(
              value: hardBrakes.toString(),
              label: AppStrings.tripSummaryHardBrakes,
              color: AppColors.blue,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Item(
              value: fuelCostFormatted,
              label: AppStrings.trackingFuelCost,
              color: AppColors.green,
            ),
            const SizedBox(width: 6),
            _Item(
              value: rankLabel,
              label: AppStrings.tripSummaryYourRank,
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.microLabel.copyWith(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}
