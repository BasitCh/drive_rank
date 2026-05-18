import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom-nav shell that wraps the four main tabs:
/// Drive | History | Rankings | Profile.
///
/// Provides the singleton FriendsBloc at the shell level so the
/// Profile-tab badge, the AddFriendSheet, and the leaderboard's
/// Friends tab all read from the same instance — no duplicate
/// Firestore listeners.
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
        path: RouteNames.profile, showRequestBadge: true),
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
    return BlocProvider<FriendsBloc>(
      create: (_) =>
          getIt<FriendsBloc>()..add(const FriendsStarted()),
      child: Scaffold(
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
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.label,
    required this.icon,
    required this.path,
    this.showRequestBadge = false,
  });
  final String label;
  final IconData icon;
  final String path;

  /// When true, the tab's icon renders a teal pending-friend-requests
  /// badge whenever `FriendsBloc.state.pendingRequestsCount > 0`.
  final bool showRequestBadge;
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
            _IconWithBadge(
              icon: tab.icon,
              color: color,
              showBadge: tab.showRequestBadge,
            ),
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

/// Icon with an optional teal-circle badge in the top-right that shows
/// the pending-friend-requests count. Hidden when count is 0 or the
/// tab doesn't opt in.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.showBadge,
  });

  final IconData icon;
  final Color color;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 22, color: color);
    if (!showBadge) return iconWidget;

    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (a, b) =>
          a.pendingRequestsCount != b.pendingRequestsCount,
      builder: (context, state) {
        final count = state.pendingRequestsCount;
        if (count == 0) return iconWidget;
        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.bg, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bg,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
