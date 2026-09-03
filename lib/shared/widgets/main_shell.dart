import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/widgets/connectivity_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom-nav shell that wraps the main tabs:
/// Drive | History | Rankings | Profile.
///
/// Rankings is conditional — when the rankings kill switch is off the
/// tab is dropped from the bar, and the router separately bounces any
/// direct navigation to it. Both read the same flag from
/// `UserSettingsRepository`, which owns that decision; this widget only
/// renders its consequence.
///
/// Personal Bests has no tab. Its route stays registered in
/// `app_router.dart` and is reachable by deep link; it lost the slot to
/// Rankings.
///
/// In-app update checks moved up to the splash page — `MainShell` is
/// purely a layout widget again. A user that reaches the shell has
/// already cleared the forced-update gate.
class MainShell extends StatelessWidget {
  const MainShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _driveTab = _Tab(
    label: AppStrings.navDrive,
    icon: Icons.speed_rounded,
    path: RouteNames.home,
  );
  static const _historyTab = _Tab(
    label: AppStrings.navHistory,
    icon: Icons.history_rounded,
    path: RouteNames.history,
  );
  static const _rankingsTab = _Tab(
    label: AppStrings.navRankings,
    icon: Icons.leaderboard_rounded,
    path: RouteNames.rankings,
  );
  static const _profileTab = _Tab(
    label: AppStrings.navProfile,
    icon: Icons.person_rounded,
    path: RouteNames.profile,
  );

  static List<_Tab> _tabsFor({required bool rankingsEnabled}) => [
    _driveTab,
    _historyTab,
    if (rankingsEnabled) _rankingsTab,
    _profileTab,
  ];

  int _activeIndex(List<_Tab> tabs) {
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt whenever the settings row changes, so a flag flip takes
    // the tab away (or gives it back) without a restart. Defaults to
    // showing it while the first value is in flight — the tab appearing
    // a frame late is better than it flickering in on every launch.
    return StreamBuilder<bool>(
      stream: getIt<UserSettingsRepository>().watchRankingsEnabled(),
      initialData: true,
      builder: (context, snapshot) =>
          _buildShell(context, rankingsEnabled: snapshot.data ?? true),
    );
  }

  Widget _buildShell(BuildContext context, {required bool rankingsEnabled}) {
    final tabs = _tabsFor(rankingsEnabled: rankingsEnabled);
    final active = _activeIndex(tabs);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.card2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.border2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavTab(
                    tab: tabs[i],
                    isActive: i == active,
                    onTap: () => context.go(tabs[i].path),
                  ),
                ),
            ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive ? AppColors.tealDim : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
            ],
          ),
        ),
      ),
    );
  }
}
