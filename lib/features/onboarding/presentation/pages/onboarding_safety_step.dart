import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 7 — safety reminders + acknowledgement checkbox + final CTA.
class OnboardingSafetyStep extends StatelessWidget {
  const OnboardingSafetyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) => a.safetyAccepted != b.safetyAccepted,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const Center(
                      child: Text('⚠️', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        AppStrings.onboardSafetyTitle,
                        style: AppTextStyles.headingLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        AppStrings.onboardSafetySub,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SafetyItem(
                      emoji: '🏁',
                      text: AppStrings.onboardSafetyItem1,
                    ),
                    const _SafetyItem(
                      emoji: '🅿',
                      text: AppStrings.onboardSafetyItem2,
                    ),
                    const _SafetyItem(
                      emoji: '📱',
                      text: AppStrings.onboardSafetyItem3,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.read<OnboardingBloc>().add(
                          OnboardingSafetyToggled(
                            accepted: !state.safetyAccepted,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Checkbox(checked: state.safetyAccepted),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  AppStrings.onboardSafetyAccept,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TealButton(
              label: AppStrings.onboardSafetyCta,
              enabled: state.safetyAccepted,
              onPressed: () => context.read<OnboardingBloc>().add(
                const OnboardingStepNext(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SafetyItem extends StatelessWidget {
  const _SafetyItem({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.teal : Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.teal : AppColors.textTertiary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.bg)
          : null,
    );
  }
}
