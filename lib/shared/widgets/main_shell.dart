import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom-nav shell that wraps the four main tabs:
/// Drive | History | Rankings | Profile.
///
/// Mirrors the mock's `.bottom-nav` block — mono labels, a 3-px teal dot
/// under the active tab, no Material default ripple noise.
class MainShell extends StatelessWidget {
  const MainShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const List<_Tab> _tabs = [
    _Tab(label: AppStrings.navDrive, icon: Icons.speed_rounded,
        path: RouteNames.home),
    _Tab(label: AppStrings.navHistory, icon: Icons.history_rounded,
        path: RouteNames.history),
    _Tab(label: AppStrings.navRankings, icon: Icons.emoji_events_rounded,
        path: RouteNames.leaderboard),
    _Tab(label: AppStrings.navProfile, icon: Icons.person_rounded,
        path: RouteNames.profile),
  ];

  int get _activeIndex {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _NavTab(
                    tab: _tabs[i],
                    isActive: i == active,
                    onTap: () => context.go(_tabs[i].path),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _Tab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.teal : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              tab.label.toUpperCase(),
              style: AppTextStyles.microLabel.copyWith(color: color),
            ),
            const SizedBox(height: 3),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
