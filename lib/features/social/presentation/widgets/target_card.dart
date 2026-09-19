import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/presentation/widgets/competition_progress_bar.dart';
import 'package:flutter/material.dart';

/// One personal target.
///
/// An active target leads with what's left to do rather than what's
/// been done — "58 km to go" is something you can act on today, where
/// "192 of 250 km" is a readout. A completed one swaps to a teal
/// promotion and the date it was finished, so the list reads as a
/// record of things achieved rather than a graveyard of full bars.
///
/// Deliberately distinct chrome from Trip Summary's `_GoalNudge`: that
/// card is the speed/distance *goal* mechanic, and the two must not
/// look like the same feature.
class TargetCard extends StatelessWidget {
  const TargetCard({
    required this.target,
    required this.metricLabel,
    required this.formattedTarget,
    required this.formattedRemaining,
    required this.windowLabel,
    this.onCancel,
    super.key,
  });

  final Target target;

  /// e.g. "Distance · This week" — assembled by the caller so this
  /// widget never touches enums or the locale.
  final String metricLabel;

  final String formattedTarget;
  final String formattedRemaining;

  /// When the target's window closes, e.g. "Ends Sunday".
  final String windowLabel;

  /// Absent for a completed target — a finished result is history and
  /// isn't cancellable.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final done = target.isComplete;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: done ? AppColors.teal.withValues(alpha: 0.06) : AppColors.card,
        border: Border.all(
          color: done
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metricLabel,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: done ? AppColors.teal : AppColors.textTertiary,
                  ),
                ),
              ),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.teal,
                )
              else if (onCancel != null)
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTarget,
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 34,
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CompetitionProgressBar(progress: target.progress),
          const SizedBox(height: 8),
          Text(
            done
                ? AppStrings.targetsDone
                : AppStrings.targetsRemaining(formattedRemaining),
            style: AppTextStyles.bodySmall.copyWith(
              color: done ? AppColors.teal : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            windowLabel,
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
