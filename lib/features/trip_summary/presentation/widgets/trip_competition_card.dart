import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/rank_change.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/presentation/widgets/competition_progress_bar.dart';
import 'package:flutter/material.dart';

/// What this trip did to your competitive standing.
///
/// Shows **one** headline, chosen by priority — rank movement, then a
/// completed target, then a trophy, then target progress — because five
/// things announced at once is five things ignored. Everything else the
/// trip achieved is still reachable on the Rankings tab.
///
/// Uses the teal-gradient chrome `MyRankHero` established for "this
/// block is about you", which also keeps it clearly distinct from the
/// flat `Next Goal` card beside it: *Goal* is the speed/distance
/// personal-best mechanic, *Target* is the social one, and they must
/// not read as the same feature.
class TripCompetitionCard extends StatelessWidget {
  const TripCompetitionCard({
    required this.rankChange,
    required this.completedTargets,
    required this.activeTargets,
    required this.unlockedTrophies,
    required this.isIneligible,
    required this.formatTargetRemaining,
    this.onViewRankings,
    super.key,
  });

  final RankChange? rankChange;
  final List<Target> completedTargets;
  final List<Target> activeTargets;
  final List<Trophy> unlockedTrophies;
  final bool isIneligible;

  /// Formats a target's remaining amount — the caller owns units.
  final String Function(Target) formatTargetRemaining;

  final VoidCallback? onViewRankings;

  @override
  Widget build(BuildContext context) {
    // An excluded trip explains itself rather than showing nothing,
    // which would leave the user wondering why their drive did nothing.
    if (isIneligible) {
      return _Frame(
        accent: AppColors.textTertiary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.tripNotEligibleTitle,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              AppStrings.tripNotEligibleBody,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    final change = rankChange;
    if (change != null) return _rankMoved(change);
    if (completedTargets.isNotEmpty) return _targetDone(completedTargets.first);
    if (unlockedTrophies.isNotEmpty) return _trophy(unlockedTrophies.first);
    if (activeTargets.isNotEmpty) return _progress(activeTargets.first);
    return const SizedBox.shrink();
  }

  Widget _rankMoved(RankChange change) => _Frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(AppStrings.tripCompetitionTitle),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppStrings.tripRankMoved(change.previousRank, change.newRank),
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 40,
                height: 1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                AppStrings.tripRankPlaces(change.positionsMoved),
                style: AppTextStyles.title.copyWith(color: AppColors.teal),
              ),
            ),
          ],
        ),
        if (change.passedNames.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            change.passedNames.length == 1
                ? AppStrings.tripPassed(change.passedNames.first)
                : AppStrings.tripPassedMore(
                    change.passedNames.first,
                    change.passedNames.length - 1,
                  ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (onViewRankings != null) _ViewRankings(onTap: onViewRankings!),
      ],
    ),
  );

  Widget _targetDone(Target target) => _Frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(AppStrings.tripCompetitionTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.teal,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.tripTargetCompleted,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.tripTargetCompletedBody,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        if (onViewRankings != null) _ViewRankings(onTap: onViewRankings!),
      ],
    ),
  );

  Widget _trophy(Trophy trophy) => _Frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(AppStrings.tripCompetitionTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(trophy.type.icon, size: 20, color: AppColors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                trophy.type.title,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.tripTrophyUnlocked,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        if (onViewRankings != null) _ViewRankings(onTap: onViewRankings!),
      ],
    ),
  );

  Widget _progress(Target target) => _Frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(AppStrings.tripCompetitionTitle),
        const SizedBox(height: AppSpacing.sm),
        CompetitionProgressBar(progress: target.progress),
        const SizedBox(height: 8),
        Text(
          AppStrings.targetsRemaining(formatTargetRemaining(target)),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onViewRankings != null) _ViewRankings(onTap: onViewRankings!),
      ],
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.accent = AppColors.teal});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.teal),
  );
}

class _ViewRankings extends StatelessWidget {
  const _ViewRankings({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.tripViewRankingsCta,
              style: AppTextStyles.microLabel.copyWith(
                fontSize: 11,
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
