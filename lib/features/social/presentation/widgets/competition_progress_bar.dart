import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

/// The "how close am I" bar, shared by everything in this feature that
/// shows progress toward a number: the rank hero's gap to the position
/// above, a target's progress, and the trip card.
///
/// Lifted out of `MyRankHero` when targets needed the same bar — the
/// same de-duplication `RankingPills` made against History's
/// `FilterPills`, so there's one definition of what progress looks like
/// rather than three that drift.
///
/// Deliberately carries no percentage label. The number that matters is
/// the gap itself — kilometres or days — stated in words next to it;
/// the bar is only the shape of it.
class CompetitionProgressBar extends StatelessWidget {
  const CompetitionProgressBar({
    required this.progress,
    this.color = AppColors.teal,
    super.key,
  });

  /// Clamped by the caller; values outside `[0, 1]` are clamped again
  /// here so a bad input can't paint outside the track.
  final double progress;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.border),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              // The head of the bar, so a small amount of progress still
              // reads as "started" rather than as an empty track.
              Positioned(
                left: (width * fraction) - 5,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: AppColors.bg, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
