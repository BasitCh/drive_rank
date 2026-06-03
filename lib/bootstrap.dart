import 'dart:async';
import 'dart:io' show Platform;

import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/firebase_auth_service.dart';
import 'package:drive_rank/core/services/firebase_telemetry_service.dart';
import 'package:drive_rank/core/services/onesignal_push_service.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/revenuecat_paywall_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

  runApp(await builder());

  // OneSignal and RevenueCat are independent of any first-launch
  // screen — defer them so they don't add to time-to-first-frame.
  unawaited(_initDeferredServices());
}

Future<void> _initDeferredServices() async {
  await Future.wait<void>([
    _maybeInitOneSignal(),
    _maybeInitRevenueCat(),
    _maybeSyncFreeTripCounter(),
  ]);
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
    await Firebase.initializeApp();
    if (kDebugMode) debugPrint('[bootstrap] Firebase initialised');

    final auth = FirebaseAuthService(fb.FirebaseAuth.instance);
    // Stable per-install identity. Cheap on a warm cache (the FB SDK
    // re-uses the persisted session uid); only round-trips on a fresh
    // install. We use the uid for telemetry attribution + RC app user
    // matching — no Firestore writes gate on it any more.
    await auth.ensureSignedIn();

    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;

    if (!kDebugMode) {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    final telemetry = FirebaseTelemetryService(analytics, crashlytics);
    await _replace<AuthService>(() => auth);
    await _replace<TelemetryService>(() => telemetry);

    final authUid = auth.currentUser.uid;
    if (authUid.isNotEmpty && authUid != 'pending') {
      await telemetry.setUser(uid: authUid);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] Firebase init skipped — preview services in use. '
        '($e) — run `flutterfire configure` to enable Firebase.',
      );
    }
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
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] OneSignal init failed: $e');
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
}
