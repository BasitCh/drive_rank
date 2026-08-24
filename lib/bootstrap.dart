import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/firebase_auth_service.dart';
import 'package:drive_rank/core/services/firebase_telemetry_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/onesignal_push_service.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/core/services/posthog_telemetry_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/retention_notification_service.dart';
import 'package:drive_rank/core/services/revenuecat_paywall_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/firestore_trip_sink.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:drive_rank/shared/services/sync_manager.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// One-shot async bootstrap: binding, DI, system chrome, then a
/// best-effort, *offline-first* init of the production SDKs we still
/// use after the MVP scope reduction.
///
/// MVP scope: Drive Rank is offline-first. Local Drift is the source
/// of truth for every trip; there is no cloud sync, no leaderboard,
/// no friends, and no public profile yet. The only Firebase surfaces
/// still wired up are Auth (anonymous) for stable per-install identity
/// and Crashlytics/Analytics for telemetry. RevenueCat handles
/// purchases. OneSignal handles push. Each remote init is best-effort
/// — a missing config leaves the preview/no-op impl in place and the
/// app still works.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050508),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await configureDependencies();

  // Forward uncaught errors to telemetry. Handlers read getIt lazily
  // so they work whether or not Firebase is up yet.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final telemetry = _safeTelemetry();
    if (telemetry != null) {
      unawaited(telemetry.recordFlutterError(details));
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    final telemetry = _safeTelemetry();
    if (telemetry != null) {
      unawaited(telemetry.recordError(error, stack, fatal: true));
    }
    return true;
  };

  // Firebase init is awaited so anonymous sign-in completes before
  // any UI that wants `auth.currentUser.uid` for telemetry / RC user
  // matching. The actual call is fast on a warm cache (sub-second).
  await _maybeInitFirebase();

  // Honour the persisted unit override before we ever paint a frame —
  // otherwise the LocaleService starts as the platform default and the
  // user's previously-saved metric/imperial choice wouldn't take effect
  // until the next restart.
  await _applyPersistedUnitOverride();

  // Sticky analytics user properties so every event report can be sliced
  // by country / vehicle / pro / units / map theme / onboarding status
  // without having to attach them to each track() call.
  await _syncAnalyticsUserProperties();

  // One-shot app_open event so Firebase Analytics can compute DAU /
  // session retention. Firebase also auto-fires its own session_start,
  // but the typed app_open lets us correlate with our own properties.
  unawaited(_safeTelemetry()?.track(TelemetryEvents.appOpen));

  runApp(await builder());

  // OneSignal and RevenueCat are independent of any first-launch
  // screen — defer them so they don't add to time-to-first-frame.
  unawaited(_initDeferredServices());
}

/// Reads the persisted `unitSystem` from Drift and, if it differs from the
/// platform-locale default, re-registers [LocaleService] with the right
/// override. Runs before runApp so the very first paint shows the user's
/// previously-saved unit (km/h vs mph) instead of the OS guess.
Future<void> _applyPersistedUnitOverride() async {
  try {
    final repo = getIt<UserSettingsRepository>();
    final row = await repo.ensureExists();
    final stored = row.unitSystem == 'imperial'
        ? UnitSystem.imperial
        : UnitSystem.metric;
    final current = getIt<LocaleService>();
    if (current.unitSystem == stored) return;
    final swapped = current.withOverride(stored);
    if (getIt.isRegistered<LocaleService>()) {
      await getIt.unregister<LocaleService>();
    }
    getIt.registerLazySingleton<LocaleService>(() => swapped);
  } catch (e) {
    if (kDebugMode) debugPrint('[bootstrap] unit override skipped: $e');
  }
}

Future<void> _initDeferredServices() async {
  await Future.wait<void>([
    _maybeInitOneSignal(),
    _maybeInitRevenueCat(),
    _maybeSyncFreeTripCounter(),
    _initRetentionNotifications(),
  ]);
}

/// Wires the retention-notification system's app-open hook: tracks a
/// cold start launched by tapping a notification, and — for a user who
/// already has trip history — backfills/refreshes the inactivity-nudge
/// and weekly-recap schedules. Deferred like the other services above
/// so local-notification plugin init never delays first paint. Safe to
/// call every launch (see `RetentionNotificationService.onAppStarted`).
Future<void> _initRetentionNotifications() async {
  try {
    final uid = (await getIt<UserSettingsRepository>().read()).uid;
    await getIt<RetentionNotificationService>().onAppStarted(uid: uid);
    if (kDebugMode) debugPrint('[bootstrap] retention notifications ready');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] retention notifications init failed: $e');
    }
  }
}

/// Reconciles the local free-trip counter with the cloud value keyed
/// on this device's hashed ID. Runs deferred (post-runApp) so the
/// network round-trip doesn't delay first paint. The repo no-ops on
/// any failure, so this is safe to fire-and-forget.
Future<void> _maybeSyncFreeTripCounter() async {
  try {
    await getIt<UserSettingsRepository>().syncFreeTripsWithCloud();
    if (kDebugMode) debugPrint('[bootstrap] free-trip counter synced');
  } catch (e) {
    if (kDebugMode) debugPrint('[bootstrap] trip counter sync failed: $e');
  }
}

TelemetryService? _safeTelemetry() {
  try {
    return getIt<TelemetryService>();
  } catch (_) {
    return null;
  }
}

/// Reads the persisted user settings and pushes them to Firebase Analytics
/// as sticky user properties. Safe to call multiple times — Firebase
/// dedups identical values cheaply. Settings UI re-calls this whenever
/// a property changes (pro upgrade, country switch, unit toggle, etc.).
Future<void> _syncAnalyticsUserProperties() async {
  try {
    final telemetry = _safeTelemetry();
    if (telemetry == null) return;
    final row = await getIt<UserSettingsRepository>().ensureExists();
    await Future.wait<void>([
      telemetry.setUserProperty(
        name: TelemetryUserProperties.countryCode,
        value: row.country,
      ),
      telemetry.setUserProperty(
        name: TelemetryUserProperties.vehicleType,
        value: row.vehicleType,
      ),
      telemetry.setUserProperty(
        name: TelemetryUserProperties.unitSystem,
        value: row.unitSystem,
      ),
      telemetry.setUserProperty(
        name: TelemetryUserProperties.isPro,
        value: row.isPro ? 'true' : 'false',
      ),
      telemetry.setUserProperty(
        name: TelemetryUserProperties.mapTheme,
        value: row.selectedMapTheme,
      ),
      telemetry.setUserProperty(
        name: TelemetryUserProperties.onboardingComplete,
        value: row.onboardingComplete ? 'true' : 'false',
      ),
    ]);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] analytics user-properties sync skipped: $e');
    }
  }
}

/// Swap the registered implementation of [T] for the one [factory] builds.
/// Idempotent — works whether the type was previously registered or not.
Future<void> _replace<T extends Object>(T Function() factory) async {
  if (getIt.isRegistered<T>()) {
    await getIt.unregister<T>();
  }
  getIt.registerLazySingleton<T>(factory);
}

Future<void> _maybeInitFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return; // already initialised in tests
    // Users reported the Android launch screen "hanging" for many
    // seconds — the culprit is `Firebase.initializeApp()` blocking on
    // a cold-start network round-trip when the network is slow or
    // dead. Cap at 4 s so bootstrap always completes and the Flutter
    // engine hands over to `runApp` on a predictable schedule; if
    // the cap trips, we fall back to `ConsoleTelemetryService` and
    // the app still works, just without cloud analytics for that
    // launch.
    await Firebase.initializeApp().timeout(const Duration(seconds: 4));
    if (kDebugMode) debugPrint('[bootstrap] Firebase initialised');

    final auth = FirebaseAuthService(fb.FirebaseAuth.instance);
    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;

    if (!kDebugMode) {
      // Non-awaited — Crashlytics collection is a local flag toggle,
      // no reason to gate boot on it.
      unawaited(crashlytics.setCrashlyticsCollectionEnabled(true));
    }

    final firebaseTelemetry = FirebaseTelemetryService(analytics, crashlytics);
    final telemetry = await _composeTelemetry(firebaseTelemetry);
    await _replace<AuthService>(() => auth);
    await _replace<TelemetryService>(() => telemetry);

    // Cloud trip sync — Firestore is available, so swap the no-op sink
    // and public-profile service for the real ones, then start the
    // background drain of any unsynced trips. Registered here (not via
    // `@LazySingleton` on the class itself) for the same reason as
    // `FirebaseAuthService` above — these must only exist once Firebase
    // has actually initialised.
    await _replace<RemoteTripSink>(
      () => FirestoreTripSink(FirebaseFirestore.instance, getIt()),
    );
    await _replace<PublicProfileService>(
      () => FirestorePublicProfileService(FirebaseFirestore.instance),
    );
    unawaited(getIt<SyncManager>().start());

    // Anonymous sign-in is the other slow leg — round-trips to Firebase
    // Auth on a fresh install and can hang on flaky networks. Kick it
    // off in the background instead of awaiting so bootstrap completes
    // even with no connectivity. Once the sign-in resolves we push the
    // uid to telemetry for attribution and collapse the local
    // pre-auth `'local'` placeholder into this session's uid — see
    // `UserSettingsRepository.syncUid`. This call site is always safe
    // (unlike the sign-in-time call, no account-switching risk): it
    // runs before any user action, against whatever the current
    // anonymous session already is.
    unawaited(
      auth
          .ensureSignedIn()
          .timeout(const Duration(seconds: 6))
          .then((_) {
            final uid = auth.currentUser.uid;
            if (uid.isNotEmpty && uid != 'pending') {
              unawaited(getIt<UserSettingsRepository>().syncUid(uid));
              return telemetry.setUser(uid: uid);
            }
            return null;
          })
          .catchError((_) {
            // Sign-in didn't land — telemetry events fire without user
            // attribution until the next launch. Non-fatal.
          }),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] Firebase init skipped — preview services in use. '
        '($e) — run `flutterfire configure` to enable Firebase.',
      );
    }
  }
}

/// Adds PostHog into the mix alongside [base] (Firebase) when
/// `POSTHOG_API_KEY` is configured. PostHog's funnel/cohort/retention
/// tooling is what actually answers the install → 2nd-trip drop-off
/// question; Firebase stays registered for Crashlytics and whatever
/// else already depends on it. Falls back to [base] alone on any
/// failure — a bad PostHog key must never take telemetry down.
Future<TelemetryService> _composeTelemetry(TelemetryService base) async {
  const apiKey = String.fromEnvironment('POSTHOG_API_KEY');
  if (apiKey.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] PostHog disabled — pass '
        '--dart-define=POSTHOG_API_KEY=... to enable it.',
      );
    }
    return base;
  }
  try {
    final config = PostHogConfig(apiKey)
      ..host = const String.fromEnvironment(
        'POSTHOG_HOST',
        defaultValue: 'https://us.i.posthog.com',
      )
      ..captureApplicationLifecycleEvents = true
      ..debug = kDebugMode;
    await Posthog().setup(config);
    if (kDebugMode) debugPrint('[bootstrap] PostHog initialised');
    return CompositeTelemetryService([base, PosthogTelemetryService()]);
  } catch (e) {
    if (kDebugMode) debugPrint('[bootstrap] PostHog init failed: $e');
    return base;
  }
}

Future<void> _maybeInitOneSignal() async {
  const appId = String.fromEnvironment('ONESIGNAL_APP_ID');
  if (appId.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] OneSignal disabled — pass '
        '--dart-define=ONESIGNAL_APP_ID=... to enable push.',
      );
    }
    return;
  }
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    final push = OneSignalPushService(appId);
    await _replace<PushService>(() => push);
    if (kDebugMode) debugPrint('[bootstrap] OneSignal initialised');
    // Only meaningful once `push` is the real OneSignal implementation
    // — calling it any earlier would hit the no-op default and go
    // nowhere.
    await _syncPushUserProperties();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] OneSignal init failed: $e');
    }
  }
}

/// Binds the anonymous/local uid and pushes segmentation tags (country,
/// vehicle type, pro status) to OneSignal — mirrors
/// [_syncAnalyticsUserProperties] but targets [PushService] instead of
/// [TelemetryService]. Without this, OneSignal registers the device but
/// has no way to address it ("users in Pakistan," "Pro users," …) from
/// the dashboard beyond an untargeted blast to everyone.
///
/// Only covers what's known at boot; `OnboardingBloc` and `PaywallBloc`
/// re-tag country/vehicle/pro individually the moment those change
/// within a session, same as bootstrap does for the analytics side.
Future<void> _syncPushUserProperties() async {
  try {
    final push = getIt<PushService>();
    final row = await getIt<UserSettingsRepository>().ensureExists();
    await push.setExternalId(row.uid);
    final country = row.country;
    await Future.wait<void>([
      if (country != null) push.tag('country', country),
      push.tag('vehicle_type', row.vehicleType),
      push.tag('is_pro', row.isPro ? 'true' : 'false'),
    ]);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] push user-properties sync skipped: $e');
    }
  }
}

Future<void> _maybeInitRevenueCat() async {
  const androidKey = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');
  const iosKey = String.fromEnvironment('REVENUECAT_API_KEY_IOS');
  if (androidKey.isEmpty && iosKey.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] RevenueCat disabled — paywall using preview prices. '
        'Pass --dart-define=REVENUECAT_API_KEY_ANDROID=... and '
        '--dart-define=REVENUECAT_API_KEY_IOS=... to enable purchases.',
      );
    }
    return;
  }
  if (!Platform.isAndroid && !Platform.isIOS) return;

  // Use the Firebase Auth uid as the RC app user id so purchases follow
  // the install across re-installs (when the user later restores).
  String? appUserId;
  try {
    appUserId = getIt<AuthService>().currentUser.uid;
    if (appUserId.isEmpty || appUserId == 'pending') appUserId = null;
  } catch (_) {
    // Auth not ready — RC will assign an anonymous id, fine.
  }

  final service = await RevenueCatPaywallService.init(
    androidApiKey: androidKey,
    iosApiKey: iosKey,
    appUserId: appUserId,
  );
  if (service == null) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] RevenueCat init returned null — preview paywall stays.',
      );
    }
    return;
  }
  await _replace<PaywallService>(() => service);
  if (kDebugMode) debugPrint('[bootstrap] RevenueCat initialised');

  // Restore entitlement automatically after a reinstall. Google Play
  // remembers the active subscription against the user's Google account,
  // so this round-trip resolves to `active` even though Drift's local
  // `isPro` flag is fresh. Three-way, not a bool: `active` grants,
  // `inactive` is a *confirmed* absence of entitlement (safe to revoke
  // a stale local `isPro = true`, e.g. an expired/cancelled sub since
  // last launch), `unknown` is a transient failure (network, RevenueCat
  // down) and must leave local `isPro` exactly as it was — never
  // downgrade a locally-pro user just because the remote check failed.
  try {
    final restoreResult = await service.restorePurchases();
    // Fail-open/fail-closed logic lives in one place —
    // UserSettingsRepository.applyEntitlementCheck — not re-implemented
    // here.
    await getIt<UserSettingsRepository>().applyEntitlementCheck(
      restoreResult,
    );
    if (kDebugMode) {
      debugPrint('[bootstrap] RC restorePurchases → $restoreResult');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[bootstrap] RC restore failed: $e');
  }
}
