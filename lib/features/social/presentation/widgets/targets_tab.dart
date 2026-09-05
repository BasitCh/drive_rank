import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/presentation/widgets/target_card.dart';
import 'package:flutter/material.dart';

/// Your personal targets.
///
/// Active ones first — the thing you're chasing matters more than the
/// thing you finished — then a completed section, so the screen doubles
/// as a record of what's been achieved.
///
/// Targets need no friends by design, which is why this surface is
/// complete today while the head-to-head half of the feature waits for
/// the remote layer.
class TargetsTab extends StatelessWidget {
  const TargetsTab({
    required this.targets,
    required this.onCreate,
    required this.onCancel,
    required this.metricLabelFor,
    required this.formatTarget,
    required this.formatRemaining,
    required this.windowLabelFor,
    super.key,
  });

  final List<Target> targets;
  final VoidCallback onCreate;
  final ValueChanged<Target> onCancel;

  /// "Distance · This week" — assembled by the caller so this widget
  /// never touches enums.
  final String Function(Target) metricLabelFor;

  final String Function(Target) formatTarget;
  final String Function(Target) formatRemaining;
  final String Function(Target) windowLabelFor;

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) return _TargetsEmpty(onCreate: onCreate);

    final active = targets.where((t) => !t.isComplete).toList();
    final done = targets.where((t) => t.isComplete).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      children: [
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
        const SizedBox(height: AppSpacing.sm),
        TealButton(label: AppStrings.targetsCreateCta, onPressed: onCreate),
      ],
    );
  }

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
