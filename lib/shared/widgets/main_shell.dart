import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/shared/widgets/connectivity_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom-nav shell that wraps the four main tabs:
/// Drive | History | Personal Bests | Profile.
///
/// MVP scope: the previous "Rankings" tab (global leaderboard +
/// friends) is gone. Its slot is now Personal Bests — local-only
/// rollups that don't depend on any cloud feature.
///
/// In-app update checks moved up to the splash page — `MainShell` is
/// purely a layout widget again. A user that reaches the shell has
/// already cleared the forced-update gate.
class MainShell extends StatelessWidget {
  const MainShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const List<_Tab> _tabs = [
    _Tab(
      label: AppStrings.navDrive,
      icon: Icons.speed_rounded,
      path: RouteNames.home,
    ),
    _Tab(
      label: AppStrings.navHistory,
      icon: Icons.history_rounded,
      path: RouteNames.history,
    ),
    // Personal Bests tab is hidden for now — this nav slot is earmarked
    // for a future leaderboard feature. The route itself stays
    // registered in `app_router.dart` (reachable via deep link), only
    // the tab entry is removed here.
    _Tab(
      label: AppStrings.navProfile,
      icon: Icons.person_rounded,
      path: RouteNames.profile,
    ),
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
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavTab(
                    tab: _tabs[i],
                    isActive: i == active,
                    onTap: () => context.go(_tabs[i].path),
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
