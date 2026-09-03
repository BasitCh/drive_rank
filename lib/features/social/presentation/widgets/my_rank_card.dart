import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:flutter/material.dart';

/// The "where do I stand" header card.
///
/// Always says something actionable. With somebody above the viewer it's
/// the gap to overtake; at the top of the board it names who's closest
/// behind, so being first still has stakes; alone on a fresh board it
/// explains what to do instead of showing a hollow `#1`.
class MyRankCard extends StatelessWidget {
  const MyRankCard({
    required this.board,
    required this.formattedValue,
    required this.unitLabel,
    required this.formatGap,
    super.key,
  });

  final Leaderboard board;

  /// The viewer's own value, pre-formatted through `LocaleService`.
  final String formattedValue;
  final String unitLabel;

  /// Formats a metric delta (e.g. `12 km`, `2 days`) — passed in so this
  /// widget stays unit-system agnostic.
  final String Function(double) formatGap;

  @override
  Widget build(BuildContext context) {
    final me = board.me;
    if (me == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.rankingsYourRank,
            style: AppTextStyles.label.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppStrings.rankingsRankPrefix}${me.rank}',
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 48,
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 26,
                        height: 1,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unitLabel,
                      style: AppTextStyles.microLabel.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_subtitle(), style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  String _subtitle() {
    final above = board.nextAbove;
    final gap = board.gapToNextAbove;
    if (above != null && gap != null) {
      return AppStrings.rankingsBehindNext(formatGap(gap), above.rank);
    }
    final below = board.nextBelow;
    if (below != null) {
      return AppStrings.rankingsDefending(
        below.entry.displayName,
        formatGap(
          (board.me?.entry.value ?? 0) - below.entry.value,
        ),
      );
    }
    return AppStrings.rankingsLeadingAlone;
  }
}
