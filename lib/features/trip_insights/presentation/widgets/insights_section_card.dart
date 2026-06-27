import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Shared card chrome for every Insights section.
///
/// Keeps the visual rhythm consistent across the page and the composite
/// social card — every section is the same dark `#1A1A22` card with the
/// same corner radius and title row, so the screenshot reads as one
/// coherent surface instead of mismatched widgets.
class InsightsSectionCard extends StatelessWidget {
  const InsightsSectionCard({
    required this.title,
    required this.child,
    super.key,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// Optional small label rendered on the right of the title row (e.g.
  /// "TIME SPENT" beside "Speed Breakdown").
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!.toUpperCase(),
                  style: AppTextStyles.microLabel.copyWith(fontSize: 9),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
