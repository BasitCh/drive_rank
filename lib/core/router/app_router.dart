import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/features/history/presentation/pages/history_page.dart';
import 'package:drive_rank/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/splash_page.dart';
import 'package:drive_rank/features/paywall/presentation/pages/paywall_page.dart';
import 'package:drive_rank/features/profile/presentation/pages/profile_page.dart';
import 'package:drive_rank/features/settings/presentation/pages/settings_page.dart';
import 'package:drive_rank/features/tracking/presentation/pages/home_page.dart';
import 'package:drive_rank/features/tracking/presentation/pages/tracking_page.dart';
import 'package:drive_rank/features/trip_summary/presentation/pages/trip_summary_page.dart';
import 'package:drive_rank/shared/widgets/main_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

/// App-wide GoRouter configuration.
///
/// Session 1 wires every route to a placeholder page; later sessions replace
/// the pages. The shell route owns the persistent bottom nav (Drive, History,
/// Rankings, Profile). Tracking / trip-summary / paywall / settings sit
/// outside the shell so they render full-screen.
@singleton
class AppRouter {
  AppRouter() : router = _build();

  final GoRouter router;

  static GoRouter _build() {
    return GoRouter(
      initialLocation: RouteNames.splash,
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: RouteNames.tracking,
          builder: (_, __) => const TrackingPage(),
        ),
        GoRoute(
          path: '${RouteNames.tripSummary}/:tripId',
          builder: (_, state) => TripSummaryPage(
            tripId: int.parse(state.pathParameters['tripId']!),
          ),
        ),
        GoRoute(
          path: RouteNames.paywall,
          pageBuilder: (_, __) => const NoTransitionPage(child: PaywallPage()),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (_, __) => const SettingsPage(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainShell(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: RouteNames.home,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HomePage()),
            ),
            GoRoute(
              path: RouteNames.history,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HistoryPage()),
            ),
            GoRoute(
              path: RouteNames.leaderboard,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: LeaderboardPage()),
            ),
            GoRoute(
              path: RouteNames.profile,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    );
  }
}
