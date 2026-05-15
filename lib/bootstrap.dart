import 'dart:async';

import 'package:drive_rank/core/di/injection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One-shot async bootstrap: binding, DI, system chrome.
///
/// Firebase / Crashlytics / RevenueCat / OneSignal initialisation will be
/// added here when their config files (firebase_options.dart,
/// GoogleService-Info.plist, google-services.json, REVENUECAT_API_KEY in
/// .env) are wired up. Doing so now without those files would fail to build,
/// so Session 1 ships an init pipeline that DOES work and we layer SaaS on
/// top in later sessions.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — the entire HTML mock is portrait-only.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Status bar / nav bar styling — dark UI everywhere.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050508),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Surface uncaught Flutter errors clearly during dev. In release these
  // route to Crashlytics once Firebase is wired up.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // TODO(session-5): forward to FirebaseCrashlytics.recordFlutterError
    }
  };

  await configureDependencies();

  runApp(await builder());
}
