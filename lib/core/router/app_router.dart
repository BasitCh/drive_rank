import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/analytics_router_observer.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/history/presentation/pages/history_page.dart';
import 'package:drive_rank/features/monthly_report/presentation/pages/monthly_report_page.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/splash_page.dart';
import 'package:drive_rank/features/paywall/presentation/pages/paywall_page.dart';
import 'package:drive_rank/features/personal_bests/presentation/pages/personal_bests_page.dart';
import 'package:drive_rank/features/profile/presentation/pages/profile_page.dart';
import 'package:drive_rank/features/settings/presentation/pages/settings_page.dart';
import 'package:drive_rank/features/tracking/presentation/pages/tracking_page.dart';
import 'package:drive_rank/features/trip_insights/presentation/pages/route_replay_page.dart';
import 'package:drive_rank/features/trip_summary/presentation/pages/trip_summary_page.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/widgets/main_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

/// App-wide GoRouter configuration.
///
/// The shell route owns the persistent bottom nav (Drive / History /
/// Rankings / Profile). Tracking / trip-summary / paywall / settings sit
/// outside the shell so they render full-screen.
///
/// A redirect on every navigation pushes the user back into `/onboarding`
/// until `UserSettings.onboardingComplete == true`, and the other way around
/// (pushed out of `/onboarding` once they're done).
@singleton
class AppRouter {
  AppRouter() : router = _build();

  final GoRouter router;

  static GoRouter _build() {
    return GoRouter(
      initialLocation: RouteNames.splash,
      redirect: _redirect,
      observers: [
        // Resolved lazily — AppRouter is an eager @singleton and may
        // construct before TelemetryService is registered. The observer
        // only invokes the lookup at navigation time, by which point
        // configureDependencies() has finished.
        AnalyticsRouterObserver(() {
          try {
            return getIt<TelemetryService>();
          } catch (_) {
            return null;
          }
        }),
      ],
      routes: [
        GoRoute(
          path: RouteNames.splash,
          name: 'splash',
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          name: 'onboarding',
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: '${RouteNames.tripSummary}/:tripId',
          name: 'trip_summary',
          builder: (_, state) => TripSummaryPage(
            tripId: int.parse(state.pathParameters['tripId']!),
          ),
        ),
        GoRoute(
          path: '${RouteNames.tripReplay}/:tripId',
          name: 'trip_replay',
          builder: (_, state) => RouteReplayPage(
            tripId: int.parse(state.pathParameters['tripId']!),
          ),
        ),
        GoRoute(
          path: RouteNames.paywall,
          name: 'paywall',
          pageBuilder: (_, __) => const NoTransitionPage(child: PaywallPage()),
        ),
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          builder: (_, __) => const SettingsPage(),
        ),
        GoRoute(
          path: RouteNames.monthlyReport,
          name: 'monthly_report',
          builder: (_, __) => const MonthlyReportPage(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainShell(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: RouteNames.home,
              name: 'home',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: TrackingPage()),
            ),
            GoRoute(
              path: RouteNames.history,
              name: 'history',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HistoryPage()),
            ),
            GoRoute(
              path: RouteNames.personalBests,
              name: 'personal_bests',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: PersonalBestsPage()),
            ),
            GoRoute(
              path: RouteNames.profile,
              name: 'profile',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    );
  }

  static Future<String?> _redirect(_, GoRouterState state) async {
    // The splash page is the only screen allowed to bypass the redirect —
    // it kicks the user to wherever they belong as soon as it boots.
    if (state.matchedLocation == RouteNames.splash) return null;

    final settings = getIt<UserSettingsRepository>();
    final done = await settings.isOnboardingComplete();

    if (!done && state.matchedLocation != RouteNames.onboarding) {
      return RouteNames.onboarding;
    }
    if (done && state.matchedLocation == RouteNames.onboarding) {
      return RouteNames.home;
    }
    return null;
  }
}
