import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/firebase_auth_service.dart';
import 'package:drive_rank/core/services/firebase_telemetry_service.dart';
import 'package:drive_rank/core/services/onesignal_push_service.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/revenuecat_paywall_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/firestore_trip_sink.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:drive_rank/shared/services/sync_manager.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One-shot async bootstrap: binding, DI, system chrome, then the
/// best-effort Firebase + OneSignal init.
///
/// The container is wired up with preview/no-op service implementations
/// first (so the app always boots), then we *attempt* to initialise the
/// real production SDKs. If Firebase init succeeds we swap in
/// FirebaseAuthService / FirebaseTelemetryService / FirestoreTripSink.
/// If a OneSignal app id is present we swap in OneSignalPushService.
///
/// Anything that fails leaves the matching preview in place — the app
/// still works, just with the local-only versions. The user knows what
/// to install (firebase_options.dart, GoogleService-Info.plist,
/// google-services.json, ONESIGNAL_APP_ID env) because each `catch`
/// debugPrints a clear hint.
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

  // Wire FlutterError so that as soon as Firebase comes online (or any
  // future telemetry service is registered) crashes are forwarded
  // automatically. The handler reads getIt lazily — no captured ref.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final telemetry = _safeTelemetry();
    if (telemetry != null) {
      unawaited(telemetry.recordFlutterError(details));
    }
  };

  // Async uncaught zone errors → telemetry too.
  PlatformDispatcher.instance.onError = (error, stack) {
    final telemetry = _safeTelemetry();
    if (telemetry != null) {
      unawaited(telemetry.recordError(error, stack, fatal: true));
    }
    return true;
  };

  await _maybeInitFirebase();
  await _maybeInitOneSignal();
  await _maybeInitRevenueCat();

  // Kick the sync queue. Safe to call even when the registered sink is
  // the no-op — pending trips just flip is_synced=true locally and the
  // queue drains in a couple of ms.
  unawaited(getIt<SyncManager>().start());

  runApp(await builder());
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

    // Swap preview services for the real ones now that the SDKs are live.
    final auth = FirebaseAuthService(fb.FirebaseAuth.instance);
    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;
    final firestore = FirebaseFirestore.instance
      ..settings = const Settings(persistenceEnabled: true);

    // Crashlytics: forward Flutter errors and async errors at framework level
    // too — belt-and-braces alongside the dispatcher hooks set above.
    if (!kDebugMode) {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    final telemetry = FirebaseTelemetryService(analytics, crashlytics);
    final sink = FirestoreTripSink(firestore, getIt<TripRepository>());

    // Unregister the previews and register the real implementations.
    await _replace<AuthService>(() => auth);
    await _replace<TelemetryService>(() => telemetry);
    await _replace<RemoteTripSink>(() => sink);

    // Identify the user (anonymous local uid until they sign in).
    final settings = await getIt<UserSettingsRepository>().read();
    await telemetry.setUser(uid: settings.uid);
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
  // OneSignal_flutter is only supported on Android + iOS — guard so the
  // dev tools / desktop targets still boot.
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

  // Link RevenueCat's app user id to our local uid so a user's purchase
  // sticks even if they sign in / out of their Google account later.
  String? appUserId;
  try {
    appUserId = (await getIt<UserSettingsRepository>().read()).uid;
  } catch (_) {
    /* settings not ready yet — RC will assign an anonymous id */
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
