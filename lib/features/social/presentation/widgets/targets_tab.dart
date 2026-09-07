import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_challenges.dart';
import 'package:drive_rank/features/social/presentation/widgets/challenge_card.dart';
import 'package:drive_rank/features/social/presentation/widgets/target_card.dart';
import 'package:flutter/material.dart';

/// Your targets, and your challenges.
///
/// Both live here because a target *is* a challenge with no opponent —
/// one table, one surface — and because a fourth segment in the tab
/// bar would undo the vertical space 3c reclaimed by replacing two rows
/// of pills with it.
///
/// Order follows what needs doing: a challenge waiting on the viewer's
/// answer, then their own targets, then the challenges under way.
/// Answering somebody who is waiting on you matters more than watching
/// a number you cannot affect this second.
class TargetsTab extends StatelessWidget {
  const TargetsTab({
    required this.targets,
    required this.onCreate,
    required this.onCancel,
    required this.metricLabelFor,
    required this.formatTarget,
    required this.formatRemaining,
    required this.windowLabelFor,
    this.challenges = const [],
    this.challengeMetricLabelFor,
    this.formatChallengeValue,
    this.challengeDeadlineFor,
    this.challengeRemainingFor,
    this.onAcceptChallenge,
    this.onDeclineChallenge,
    this.onWithdrawChallenge,
    super.key,
  });

  final List<Target> targets;
  final VoidCallback onCreate;
  final ValueChanged<Target> onCancel;

  /// Head-to-head challenges, already settled by `GetChallenges`.
  final List<ChallengeView> challenges;
  final String Function(ChallengeView)? challengeMetricLabelFor;
  final String Function(ChallengeView, double)? formatChallengeValue;

  /// When driving stops counting.
  final String Function(ChallengeView)? challengeDeadlineFor;

  /// How long until the figures freeze — a different moment, and the
  /// card says so rather than conflating the two.
  final String Function(ChallengeView)? challengeRemainingFor;

  final ValueChanged<ChallengeView>? onAcceptChallenge;
  final ValueChanged<ChallengeView>? onDeclineChallenge;
  final ValueChanged<ChallengeView>? onWithdrawChallenge;

  /// "Distance · This week" — assembled by the caller so this widget
  /// never touches enums.
  final String Function(Target) metricLabelFor;

  final String Function(Target) formatTarget;
  final String Function(Target) formatRemaining;
  final String Function(Target) windowLabelFor;

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty && challenges.isEmpty) {
      return _TargetsEmpty(onCreate: onCreate);
    }

    final active = targets.where((t) => !t.isComplete).toList();
    final done = targets.where((t) => t.isComplete).toList();
    final waiting = challenges.where((c) => c.needsMyAnswer).toList();
    final running = challenges.where((c) => !c.needsMyAnswer).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      children: [
        if (waiting.isNotEmpty) ...[
          const _SectionLabel(AppStrings.challengesIncomingLabel),
          for (final view in waiting) ...[
            _challengeCard(view),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
        if (active.isNotEmpty) ...[
          const _SectionLabel(AppStrings.targetsActiveLabel),
          for (final target in active) ...[
            _card(target, cancellable: true),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const _SectionLabel(AppStrings.targetsCompletedLabel),
          for (final target in done) ...[
            _card(target, cancellable: false),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (running.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const _SectionLabel(AppStrings.challengesSectionLabel),
          for (final view in running) ...[
            _challengeCard(view),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        TealButton(label: AppStrings.targetsCreateCta, onPressed: onCreate),
      ],
    );
  }

  Widget _challengeCard(ChallengeView view) => ChallengeCard(
    view: view,
    metricLabel: challengeMetricLabelFor?.call(view) ?? '',
    formatValue: (value) =>
        formatChallengeValue?.call(view, value) ?? value.toStringAsFixed(0),
    deadlineLabel: challengeDeadlineFor?.call(view) ?? '',
    remainingLabel: challengeRemainingFor?.call(view) ?? '',
    // Only the person who was asked may answer, and only the person who
    // asked may withdraw — the same split the security rules enforce.
    onAccept: view.needsMyAnswer && onAcceptChallenge != null
        ? () => onAcceptChallenge!(view)
        : null,
    onDecline: view.needsMyAnswer && onDeclineChallenge != null
        ? () => onDeclineChallenge!(view)
        : null,
    onWithdraw: view.awaitingTheirAnswer && onWithdrawChallenge != null
        ? () => onWithdrawChallenge!(view)
        : null,
  );

  Widget _card(Target target, {required bool cancellable}) => TargetCard(
    target: target,
    metricLabel: metricLabelFor(target),
    formattedTarget: formatTarget(target),
    formattedRemaining: formatRemaining(target),
    windowLabel: windowLabelFor(target),
    onCancel: cancellable ? () => onCancel(target) : null,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.sm),
      child: Text(text, style: AppTextStyles.label.copyWith(fontSize: 10)),
    );
  }
}

/// The 72×72 circle formula, same as the other empty states in the app.
class _TargetsEmpty extends StatelessWidget {
  const _TargetsEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                Icons.flag_rounded,
                color: AppColors.teal,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppStrings.targetsEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.targetsEmptyBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TealButton(label: AppStrings.targetsCreateCta, onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
