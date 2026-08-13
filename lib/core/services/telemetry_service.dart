import 'package:flutter/foundation.dart';

/// Combined analytics + crash boundary.
///
/// One interface so feature code never has to decide whether to call
/// Firebase Analytics, Crashlytics, or PostHog — it just calls
/// `track(...)` / `recordError(...)`. Bootstrap registers the
/// console-only [ConsoleTelemetryService] (default), or a
/// `FirebaseTelemetryService` once Firebase is initialised — wrapped in
/// a [CompositeTelemetryService] alongside `PosthogTelemetryService`
/// when a PostHog API key is configured.
abstract class TelemetryService {
  /// Identify a user — keeps analytics events tied to the same anonymous
  /// or authenticated id over time.
  Future<void> setUser({required String uid});

  /// Set a sticky user property — appears as a filter in every report.
  /// Used for country / vehicle / units / pro / map theme / onboarding,
  /// so any event-level breakdown can be sliced by these dimensions
  /// without having to re-attach them on every track() call.
  Future<void> setUserProperty({required String name, required String? value});

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
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    _trace('telemetry/setUserProperty $name=$value');
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
      _trace('telemetry/flutter_error ${details.exceptionAsString()}');
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

/// Fans every call out to multiple backends so bootstrap can run
/// Firebase (Crashlytics + Analytics) and PostHog (funnel/retention
/// analysis) side by side without any call site needing to know both
/// exist. Each backend is isolated in a try/catch — one SDK choking
/// (e.g. PostHog offline) must never take the other one down with it.
class CompositeTelemetryService implements TelemetryService {
  CompositeTelemetryService(this._services);

  final List<TelemetryService> _services;

  @override
  Future<void> setUser({required String uid}) =>
      _fanOut((s) => s.setUser(uid: uid));

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) => _fanOut((s) => s.setUserProperty(name: name, value: value));

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) => _fanOut((s) => s.track(event, properties: properties));

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      _fanOut((s) => s.recordFlutterError(details));

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) => _fanOut((s) => s.recordError(error, stack, fatal: fatal));

  @override
  Future<void> log(String message) => _fanOut((s) => s.log(message));

  Future<void> _fanOut(Future<void> Function(TelemetryService) call) async {
    await Future.wait(
      _services.map((s) async {
        try {
          await call(s);
        } catch (e) {
          if (kDebugMode) debugPrint('[telemetry] backend call failed: $e');
        }
      }),
    );
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

  // Retention funnel milestones — fired once each, the first time a
  // user's lifetime trip count crosses that threshold. This is the
  // actual signal for the install → 2nd-trip drop-off analysis;
  // `tripEnded` fires on every trip and can't answer "did they come
  // back," only "did trips happen."
  static const String firstTripCompleted = 'first_trip_completed';
  static const String secondTripCompleted = 'second_trip_completed';

  // ---- Engagement / retention-notification system ----
  //
  // Deliberately NOT duplicating events that already exist:
  //   "trip_completed"                -> use `tripEnded` (fires with the
  //                                       same trip stats already).
  //   "first_trip_completed"          -> already exists above.
  //   "notification_to_trip_conversion" -> not a discrete event. Build it
  //                                       as a PostHog funnel/insight from
  //                                       `notificationOpened` -> `tripStarted`
  //                                       (windowed) instead — that's what
  //                                       funnels are for, and it avoids a
  //                                       bespoke "conversion" event that
  //                                       would just duplicate what the two
  //                                       existing events already say.

  /// Fired the moment a just-saved trip beats a prior personal best
  /// (see `TrackingBloc`'s lightweight top-speed check, run right after
  /// `TripRepository.saveTrip` — deliberately NOT the full multi-kind
  /// record system `BuildInsights` computes lazily on the Insights
  /// page; that stays as-is for the detailed/on-demand view).
  static const String personalRecordAchieved = 'personal_record_achieved';

  /// Fired whenever `GoalCalculator` produces a new active goal — i.e.
  /// on a user's first trip (goal didn't exist yet) or right after
  /// `goalAchieved` fires for the previous one.
  static const String goalCreated = 'goal_created';

  /// Fired when a just-saved trip meets or beats the active
  /// speed/distance goal.
  static const String goalAchieved = 'goal_achieved';

  /// Fired when the user opens/taps the weekly-recap notification —
  /// the recap's content *is* the notification body, there's no
  /// separate results screen, so "viewed" and "opened" are the same
  /// moment for this one campaign specifically.
  static const String weeklyRecapViewed = 'weekly_recap_viewed';

  /// Fired when `RetentionNotificationService` schedules (time-based
  /// campaigns) or shows (the immediate personal-record one) a
  /// notification. For the three scheduled campaigns this is "sent"
  /// in the sense of "successfully handed to the OS scheduler," not a
  /// delivery confirmation — Dart isn't running to observe an actual
  /// future delivery while the app is fully closed. Only the immediate
  /// personal-record notification is delivery-accurate, since it's
  /// shown synchronously in response to a real trip-completion.
  static const String notificationSent = 'notification_sent';

  /// Fired when the user taps a retention notification — covers both
  /// a live tap (app already running, foreground or background) and a
  /// cold-start-via-tap (checked once at bootstrap via
  /// `getNotificationAppLaunchDetails()`). Carries a `campaign`
  /// property so PostHog can slice/funnel per campaign type.
  static const String notificationOpened = 'notification_opened';

  static const String paywallViewed = 'paywall_viewed';
  static const String paywallPlanSelected = 'paywall_plan_selected';
  static const String paywallPurchaseStarted = 'paywall_purchase_started';
  static const String paywallPurchaseSucceeded = 'paywall_purchase_succeeded';
  static const String paywallPurchaseFailed = 'paywall_purchase_failed';
  static const String paywallRestored = 'paywall_restored';

  static const String mapThemeChanged = 'map_theme_changed';
  static const String unitsChanged = 'units_changed';
  static const String fuelConfigured = 'fuel_configured';
  static const String monthlyReportOpened = 'monthly_report_opened';

  static const String appOpen = 'app_open';
  static const String screenView = 'screen_view';
  static const String tripPaused = 'trip_paused';
  static const String tripResumed = 'trip_resumed';
  static const String tripRecovered = 'trip_recovered';
  static const String settingChanged = 'setting_changed';
  static const String updateRequiredShown = 'update_required_shown';
  static const String recoveryBannerShown = 'recovery_banner_shown';

  // Social share cards — one funnel per card kind.
  //
  // viewed → page opened from Trip Summary.
  // shared → user tapped the Share CTA (intent).
  // exported → capture + share_plus sheet actually fired (success).
  //
  // Split per card so we can compare Performance vs Journey usage and
  // spot capture failures (grey map tiles, OOM on long trips, etc.)
  // by comparing intent → success counts per surface.
  static const String performanceCardViewed = 'performance_card_viewed';
  static const String performanceCardShared = 'performance_card_shared';
  static const String performanceCardExported = 'performance_card_exported';

  static const String journeyCardViewed = 'journey_card_viewed';
  static const String journeyCardShared = 'journey_card_shared';
  static const String journeyCardExported = 'journey_card_exported';
}

/// Sticky user property keys. Firebase Analytics shows these as filters
/// across every report so we can break funnels and retention down by
/// country / vehicle / pro etc. without re-attaching to each event.
class TelemetryUserProperties {
  const TelemetryUserProperties._();

  static const String countryCode = 'country_code';
  static const String vehicleType = 'vehicle_type';
  static const String unitSystem = 'unit_system';
  static const String isPro = 'is_pro';
  static const String mapTheme = 'map_theme';
  static const String onboardingComplete = 'onboarding_complete';
}
