import 'package:flutter/foundation.dart';

/// Combined analytics + crash boundary.
///
/// One interface so feature code never has to decide whether to call
/// Firebase Analytics, Crashlytics, or PostHog — it just calls
/// `track(...)` / `recordError(...)`. Bootstrap registers either the
/// console-only [ConsoleTelemetryService] (default) or a real
/// `FirebaseTelemetryService` when Firebase is initialised.
abstract class TelemetryService {
  /// Identify a user — keeps analytics events tied to the same anonymous
  /// or authenticated id over time.
  Future<void> setUser({required String uid});

  /// Fire-and-forget event. Property values must be primitives the
  /// underlying SDK can serialise (string / num / bool).
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  });

  /// Forward a Flutter framework error from `FlutterError.onError`.
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Forward an uncaught zone error or rethrown exception.
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  });

  /// Drop a breadcrumb (visible in the next crash report) — useful for
  /// flagging the user's last UI action before a crash.
  Future<void> log(String message);
}

/// Default service. Routes everything to debugPrint in dev builds and
/// no-ops in release. Lets the rest of the app call telemetry methods
/// without worrying about whether SDKs are configured.
class ConsoleTelemetryService implements TelemetryService {
  ConsoleTelemetryService();

  @override
  Future<void> setUser({required String uid}) async {
    _trace('telemetry/setUser uid=$uid');
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    _trace('telemetry/track $event $properties');
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    // FlutterError already prints to console in debug — don't double-log.
    if (kReleaseMode) {
      _trace(
        'telemetry/flutter_error ${details.exceptionAsString()}',
      );
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    _trace('telemetry/error fatal=$fatal $error');
  }

  @override
  Future<void> log(String message) async {
    _trace('telemetry/log $message');
  }

  void _trace(String line) {
    if (kDebugMode) debugPrint('[telemetry] $line');
  }
}

/// Common event names. Centralising them here keeps analytics consistent
/// across features — and the analytics dashboard can lock down the schema
/// to exactly this set.
class TelemetryEvents {
  const TelemetryEvents._();

  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingFinished = 'onboarding_finished';

  static const String tripStarted = 'trip_started';
  static const String tripEnded = 'trip_ended';
  static const String tripSaved = 'trip_saved';
  static const String tripDeleted = 'trip_deleted';
  static const String tripShared = 'trip_shared';

  static const String paywallViewed = 'paywall_viewed';
  static const String paywallPlanSelected = 'paywall_plan_selected';
  static const String paywallPurchaseStarted = 'paywall_purchase_started';
  static const String paywallPurchaseSucceeded =
      'paywall_purchase_succeeded';
  static const String paywallPurchaseFailed = 'paywall_purchase_failed';
  static const String paywallRestored = 'paywall_restored';

  static const String mapThemeChanged = 'map_theme_changed';
  static const String unitsChanged = 'units_changed';
  static const String fuelConfigured = 'fuel_configured';
  static const String monthlyReportOpened = 'monthly_report_opened';
}
