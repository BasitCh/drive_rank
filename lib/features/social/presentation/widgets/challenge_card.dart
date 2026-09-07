import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/usecases/get_challenges.dart';
import 'package:flutter/material.dart';

/// One head-to-head challenge, both sides.
///
/// **Three states, and never a fourth.** The card is where a wrong
/// finalization boundary would be most visible, so the copy maps one to
/// one onto [ChallengeOutcome]:
///
///  * driving still to come — both figures, and who is ahead;
///  * the window closed but the figures not yet frozen — both figures,
///    and `Finalizing…`. **No winner.** An honest late publish can
///    still overtake, and a card that named a winner here would
///    contradict itself hours later;
///  * frozen — the result.
///
/// The two bars grow from a shared centre, the same treatment
/// `CompareSheet` uses for the head-to-head sheet, so the two surfaces
/// agree about what "ahead" looks like.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    required this.view,
    required this.metricLabel,
    required this.formatValue,
    required this.deadlineLabel,
    required this.remainingLabel,
    this.onAccept,
    this.onDecline,
    this.onWithdraw,
    super.key,
  });

  final ChallengeView view;

  /// "Distance · This week" — assembled by the caller, so this widget
  /// never touches enums or locales.
  final String metricLabel;
  final String Function(double) formatValue;

  /// When the competition ends — not when the result becomes final.
  final String deadlineLabel;

  /// How long until the figures freeze, for the finalizing state.
  final String remainingLabel;

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final settlement = view.settlement;
    final outcome = settlement.outcome;
    final won = outcome == ChallengeOutcome.won;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: won ? AppColors.tealDim : AppColors.card,
        border: Border.all(
          color: won
              ? AppColors.teal.withValues(alpha: 0.4)
              : view.needsMyAnswer
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.challengeVsPrefix}${view.opponentName}'
                  '  ·  $metricLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                ),
              ),
              if (onWithdraw != null)
                _TextAction(
                  label: AppStrings.challengeWithdraw,
                  onTap: onWithdraw!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Figures(
            mine: settlement.mine,
            theirs: settlement.theirs,
            opponentName: view.opponentName,
            formatValue: formatValue,
            emphasiseMine: outcome != ChallengeOutcome.trailing &&
                outcome != ChallengeOutcome.lost,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _headline(outcome),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: switch (outcome) {
                ChallengeOutcome.won ||
                ChallengeOutcome.leading => AppColors.teal,
                ChallengeOutcome.lost ||
                ChallengeOutcome.trailing => AppColors.textSecondary,
                _ => AppColors.textSecondary,
              },
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _subline(outcome),
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
          if (view.needsMyAnswer) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onDecline != null)
                  _TextAction(
                    label: AppStrings.challengeDecline,
                    onTap: onDecline!,
                  ),
                const Spacer(),
                if (onAccept != null)
                  _TextAction(
                    label: AppStrings.challengeAccept,
                    onTap: onAccept!,
                    accent: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _headline(ChallengeOutcome outcome) => switch (outcome) {
    ChallengeOutcome.leading => AppStrings.challengeLeading,
    ChallengeOutcome.trailing => AppStrings.challengeTrailing,
    ChallengeOutcome.tied => AppStrings.challengeTied,
    // Deliberately names nobody: the figures can still move.
    ChallengeOutcome.finalizing => AppStrings.challengeFinalizing,
    ChallengeOutcome.won => AppStrings.challengeWon,
    ChallengeOutcome.lost => AppStrings.challengeLost,
    ChallengeOutcome.drew => AppStrings.challengeDrew,
    ChallengeOutcome.undecided => AppStrings.challengeUndecided,
    ChallengeOutcome.expired => AppStrings.challengeExpired,
  };

  String _subline(ChallengeOutcome outcome) => switch (outcome) {
    // While the competition runs, the deadline that matters is when
    // driving stops counting.
    ChallengeOutcome.leading ||
    ChallengeOutcome.trailing ||
    ChallengeOutcome.tied => view.awaitingTheirAnswer
        ? AppStrings.challengeAwaitingReply
        : deadlineLabel,
    // Once it has closed, the one that matters is when the figures
    // freeze — a different moment, and saying so is the whole point.
    ChallengeOutcome.finalizing =>
      AppStrings.challengeFinalIn(remainingLabel),
    ChallengeOutcome.undecided => AppStrings.challengeUndecidedBody,
    ChallengeOutcome.expired => AppStrings.challengeExpiredBody,
    ChallengeOutcome.won ||
    ChallengeOutcome.lost ||
    ChallengeOutcome.drew => deadlineLabel,
  };
}

/// Both figures, and two bars on one shared scale.
class _Figures extends StatelessWidget {
  const _Figures({
    required this.mine,
    required this.theirs,
    required this.opponentName,
    required this.formatValue,
    required this.emphasiseMine,
  });

  final double mine;
  final double? theirs;
  final String opponentName;
  final String Function(double) formatValue;
  final bool emphasiseMine;

  @override
  Widget build(BuildContext context) {
    // A missing figure draws no bar at all rather than an empty one at
    // zero: the opponent has not reported, which is not the same as
    // having reported nothing.
    final them = theirs;
    final total = mine + (them ?? 0);
    final myShare = total <= 0 ? 0.5 : mine / total;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _Side(
                label: AppStrings.challengeYou,
                value: formatValue(mine),
                emphasised: emphasiseMine,
              ),
            ),
            Expanded(
              child: _Side(
                label: opponentName.toUpperCase(),
                value: them == null ? '—' : formatValue(them),
                emphasised: !emphasiseMine && them != null,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: Row(
            children: [
              Expanded(
                flex: (myShare * 1000).round().clamp(1, 1000),
                child: Container(
                  decoration: BoxDecoration(
                    color: emphasiseMine ? AppColors.teal : AppColors.border2,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                flex: ((1 - myShare) * 1000).round().clamp(1, 1000),
                child: Container(
                  decoration: BoxDecoration(
                    color: them == null
                        ? AppColors.card2
                        : emphasiseMine
                        ? AppColors.border2
                        : AppColors.textTertiary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.value,
    required this.emphasised,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool emphasised;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.microLabel.copyWith(fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            height: 1,
            color: emphasised ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? AppColors.teal : AppColors.textSecondary,
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
