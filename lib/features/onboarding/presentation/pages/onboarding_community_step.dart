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

/// Step 4 — "X drivers of your car on DriveRank" social-proof screen.
///
/// V1 uses stable per-make seed numbers so the screen never looks empty
/// before any real data exists. Session 5 swaps in Firestore `car_stats/...`.
class OnboardingCommunityStep extends StatelessWidget {
  const OnboardingCommunityStep({super.key});

  // Stable per-make estimated counts. Seeded deterministically — once the
  // user has been here once we don't want the number jumping around. Real
  // numbers replace these via Firestore in Session 5.
  static int _seedFor(String? makeId, String countryCode) {
    if (makeId == null) return 1200;
    final hash = '$makeId-$countryCode'.hashCode.abs();
    // Range 1.2k .. 9.4k — feels populated without being absurd.
    return 1200 + (hash % 8200);
  }

  static List<_Bar> _topBars(String? userMake) {
    // Generic global top-5 — illustrative, will be replaced by real data
    // from `car_stats/{country}` in Session 5.
    return [
      const _Bar(rank: 2, name: 'Suzuki', pct: 4.2),
      const _Bar(rank: 3, name: 'Honda Civic', pct: 3.8),
      _Bar(rank: 4, name: userMake ?? 'Your Car', pct: 3.2, highlight: true),
      const _Bar(rank: 5, name: 'Honda City', pct: 2.9),
      const _Bar(rank: 6, name: 'Kia Sportage', pct: 2.4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) =>
          a.carMake != b.carMake ||
          a.carModel != b.carModel ||
          a.country != b.country,
      builder: (context, state) {
        final make = state.carMake?.name;
        final model = state.carModel;
        final country = state.country;
        final count = _seedFor(state.carMake?.id, country?.code ?? '');
        final bars = _topBars('${make ?? ''}${model == null ? '' : ' $model'}');

        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatThousands(count),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${make ?? 'Your car'}${model != null ? ' $model' : ''} '
                    '${AppStrings.onboardCommunityCountSuffix.trim()}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${AppStrings.onboardCommunityMostPopularPrefix}4'
                      '${AppStrings.onboardCommunityMostPopularSuffix}'
                      ' ${country?.flag ?? ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < bars.length; i++)
                          _BrandRow(bar: bars[i], isLast: i == bars.length - 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3.2% of all DriveRank '
                    '${country?.name ?? "global"} drivers',
                    style: AppTextStyles.label.copyWith(fontSize: 10),
                  ),
                ],
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
      },
    );
  }

  static String _formatThousands(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _Bar {
  const _Bar({
    required this.rank,
    required this.name,
    required this.pct,
    this.highlight = false,
  });

  final int rank;
  final String name;
  final double pct;
  final bool highlight;

  /// Bar width as a 0..1 fraction of the row max. Scales pct so the leader
  /// (4.2%) ≈ 85% wide — matches the mock's visual rhythm.
  double get fillRatio => (pct / 5.0).clamp(0.0, 1.0);
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.bar, required this.isLast});

  final _Bar bar;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isHl = bar.highlight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHl
            ? AppColors.teal.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${bar.rank}',
              style: AppTextStyles.microLabel.copyWith(
                fontSize: 11,
                color: isHl ? AppColors.teal : AppColors.textTertiary,
                fontWeight: isHl ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bar.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: isHl ? Colors.white : AppColors.textPrimary,
                fontWeight: isHl ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  FractionallySizedBox(
                    widthFactor: bar.fillRatio,
                    child: Container(
                      height: 6,
                      color: AppColors.teal.withValues(alpha: isHl ? 1.0 : 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${bar.pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: isHl ? AppColors.teal : AppColors.textSecondary,
                fontWeight: isHl ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
