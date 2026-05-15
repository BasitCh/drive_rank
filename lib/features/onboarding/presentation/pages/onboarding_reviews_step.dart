import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 6 — 4.8 star rating display + two seed review cards.
class OnboardingReviewsStep extends StatelessWidget {
  const OnboardingReviewsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '10K+ ${AppStrings.onboardReviewsRatingSuffix}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⭐⭐⭐⭐⭐',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(height: 2),
                          Text(
                            AppStrings.reviewsAppStoreSource,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Text(
                  AppStrings.onboardReviewsTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _ReviewCard(
                  avatar: '🚗',
                  name: AppStrings.reviewerOneName,
                  text: AppStrings.reviewerOneText,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _ReviewCard(
                  avatar: '🏎️',
                  name: AppStrings.reviewerTwoName,
                  text: AppStrings.reviewerTwoText,
                ),
              ],
            ),
          ),
        ),
        TealButton(
          label: AppStrings.continueAction,
          onPressed: () => context.read<OnboardingBloc>().add(
            const OnboardingStepNext(),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.avatar,
    required this.name,
    required this.text,
  });

  final String avatar;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                '★★★★★',
                style: TextStyle(fontSize: 12, color: Color(0xFFF5A623)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
