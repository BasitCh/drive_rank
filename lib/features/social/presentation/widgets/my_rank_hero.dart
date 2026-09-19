import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_tier.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/competition_progress_bar.dart';
import 'package:drive_rank/features/social/presentation/widgets/week_streak_dots.dart';
import 'package:flutter/material.dart';

/// The viewer's own standing — the emotional centre of the screen.
///
/// A bare "#4" tells the user nothing they can act on, so this always
/// answers "how close am I?": the gap to the position above, who holds
/// it, and a bar showing how far along that gap they are. Being one
/// good drive away from passing someone is a far stronger pull than
/// knowing your position.
///
/// At the top of the board it flips to what they're defending instead,
/// so first place still has stakes.
class MyRankHero extends StatelessWidget {
  const MyRankHero({
    required this.board,
    required this.formattedValue,
    required this.unitLabel,
    required this.formatGap,
    this.tier,
    this.countdownLabel,
    this.weekDays,
    super.key,
  });

  final Leaderboard board;
  final String formattedValue;
  final String unitLabel;
  final String Function(double) formatGap;

  /// Where the viewer sits on the benchmark ladder. Named on screen so
  /// the six published paces read as a ladder to climb rather than as
  /// six rows that happen to be sorted.
  final BenchmarkTier? tier;

  /// "Ends Sunday · 2 days left", already formatted by the caller from
  /// the window the domain produced. Null for all-time, which has no
  /// end — a countdown there would be inventing a deadline.
  final String? countdownLabel;

  /// Seven Monday-first booleans for the weekly board, null otherwise.
  final List<bool>? weekDays;

  @override
  Widget build(BuildContext context) {
    final me = board.me;
    if (me == null) return const SizedBox.shrink();

    final above = board.nextAbove;
    final gap = board.gapToNextAbove;
    final chasing = above != null && gap != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        // A teal-tinted gradient rather than a plain card: this is the
        // one block on the screen that is about the viewer.
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.10),
            AppColors.teal.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.rankingsYourRank,
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppStrings.rankingsRankPrefix}${me.rank}',
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 56,
                  height: 0.9,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 34,
                        height: 1,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unitLabel,
                      style: AppTextStyles.microLabel.copyWith(
                        fontSize: 11,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (chasing) ...[
            const SizedBox(height: AppSpacing.md),
            CompetitionProgressBar(
              progress: _progressToNext(
                mine: me.entry.value,
                target: above.entry.value,
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: AppSpacing.sm),
          Text(
            _message(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (tier != null || countdownLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (tier != null) _TierChip(tier: tier!),
                if (tier != null && countdownLabel != null)
                  const SizedBox(width: 10),
                if (countdownLabel != null)
                  Flexible(
                    child: Text(
                      countdownLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
          if (weekDays != null) ...[
            const SizedBox(height: AppSpacing.md),
            WeekStreakDots(days: weekDays!),
          ],
        ],
      ),
    );
  }

  /// How far along the viewer is toward the value above them. Zero
  /// target (nobody has driven anything yet) reads as no progress
  /// rather than a divide-by-zero full bar.
  double _progressToNext({required double mine, required double target}) {
    if (target <= 0) return 0;
    return (mine / target).clamp(0.0, 1.0);
  }

  String _message() {
    final above = board.nextAbove;
    final gap = board.gapToNextAbove;
    if (above != null && gap != null) {
      return AppStrings.rankingsToBeat(
        formatGap(gap),
        above.entry.isCurrentUser
            ? AppStrings.leaderboardYou
            : above.entry.displayName,
      );
    }
    final below = board.nextBelow;
    final mine = board.me?.entry.value ?? 0;
    if (below != null) {
      return AppStrings.rankingsAheadOf(
        formatGap(mine - below.entry.value),
        below.entry.displayName,
      );
    }
    return AppStrings.rankingsLeadingAlone;
  }
}

/// "TIER 4 / 6", or the cleared state once the whole ladder is behind
/// you — at which point a fraction reading "6 / 6" forever would be
/// less informative than saying so.
class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});

  final BenchmarkTier tier;

  @override
  Widget build(BuildContext context) {
    final topped = tier.isTopped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: topped
            ? AppColors.yellow.withValues(alpha: 0.12)
            : AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: (topped ? AppColors.yellow : AppColors.teal)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        topped
            ? AppStrings.rankingsTierTopped
            : AppStrings.rankingsTier(tier.cleared, tier.total),
        style: AppTextStyles.label.copyWith(
          fontSize: 9,
          color: topped ? AppColors.yellow : AppColors.teal,
        ),
      ),
    );
  }
}
