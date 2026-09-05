import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Which competition surface the Rankings screen is showing.
///
/// `friends` deliberately isn't here yet — it arrives with the remote
/// layer that can actually supply another driver's values, and this
/// enum is where it will slot in.
enum RankingsTab {
  board,
  targets,
  trophies;

  String get label => switch (this) {
    board => AppStrings.rankingsTabBoard,
    targets => AppStrings.rankingsTabTargets,
    trophies => AppStrings.rankingsTabTrophies,
  };
}

/// The segmented control across the top of Rankings.
///
/// Visually distinct from the metric/period filter pills below it — a
/// filled track with a sliding selection rather than free-standing
/// outlined pills — because these switch *what you're looking at*
/// rather than filter one thing. Confusing the two levels is how a
/// screen ends up with three identical-looking rows of controls.
class RankingsTabBar extends StatelessWidget {
  const RankingsTabBar({
    required this.active,
    required this.onChanged,
    super.key,
  });

  final RankingsTab active;
  final ValueChanged<RankingsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            for (final tab in RankingsTab.values)
              Expanded(
                child: _Segment(
                  tab: tab,
                  isActive: tab == active,
                  onTap: () => onChanged(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final RankingsTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.teal : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            tab.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.microLabel.copyWith(
              fontSize: 11,
              letterSpacing: 0.5,
              color: isActive ? AppColors.bg : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
