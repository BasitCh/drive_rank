/// Centralised route path constants. Reference these from `context.go(...)`,
/// `context.push(...)` calls — never inline a string literal.
class RouteNames {
  const RouteNames._();

  // Top-level.
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Main shell tabs.
  static const String home = '/home';
  static const String history = '/history';
  static const String personalBests = '/personal-bests';
  static const String profile = '/profile';

  // Modals / detail pages.
  static const String tracking = '/tracking';
  static const String tripSummary = '/trip-summary';
  static const String tripReplay = '/trip-replay';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
  static const String monthlyReport = '/monthly-report';

  // Helper — build a trip summary path for a given id.
  static String tripSummaryFor(int tripId) => '$tripSummary/$tripId';

  /// Helper — build a full-screen route replay path for a given trip id.
  static String tripReplayFor(int tripId) => '$tripReplay/$tripId';
}
