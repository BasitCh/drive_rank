import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Seven dots, Monday first, filled for each day with a qualifying drive.
///
/// The most game-like thing on the screen, and it invents nothing: a dot
/// is filled by exactly the rule that scores the consistency metric
/// (`ConsistencyQualificationPolicy` — at least a kilometre and five
/// minutes of moving), so the strip and the board can never disagree
/// about what counted.
///
/// Shown for the weekly window only. Seven dots under a monthly board
/// would imply a month is seven days long.
class WeekStreakDots extends StatelessWidget {
  const WeekStreakDots({required this.days, super.key});

  /// Exactly seven, Monday → Sunday.
  final List<bool> days;

  /// Single letters rather than "Mon/Tue" — at this size the row has to
  /// stay under the rank card's width without wrapping.
  static const List<String> _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    assert(days.length == 7, 'a week has seven days');
    final driven = days.where((d) => d).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.rankingsStreakLabel,
              style: AppTextStyles.label.copyWith(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              AppStrings.rankingsStreakDays(driven),
              style: AppTextStyles.microLabel.copyWith(
                fontSize: 10,
                color: driven > 0 ? AppColors.teal : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _Dot(filled: days[i], initial: _initials[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.initial});

  final bool filled;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: filled ? AppColors.teal : AppColors.border2,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          initial,
          textAlign: TextAlign.center,
          style: AppTextStyles.microLabel.copyWith(
            fontSize: 9,
            color: filled ? AppColors.textSecondary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
