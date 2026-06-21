import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production telemetry — events go to Firebase Analytics, errors and
/// breadcrumbs to Crashlytics.
///
/// Registered in place of [ConsoleTelemetryService] at bootstrap when
/// `Firebase.initializeApp()` succeeds. The fan-out is deliberate: every
/// `recordError` writes a Crashlytics non-fatal as well as a "trip_error"
/// analytics event, so we can compute crash-free rate AND search Analytics
/// for funnel correlations without bouncing between dashboards.
class FirebaseTelemetryService implements TelemetryService {
  FirebaseTelemetryService(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setUser({required String uid}) async {
    await Future.wait([
      _analytics.setUserId(id: uid),
      _crashlytics.setUserIdentifier(uid),
    ]);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    final params = <String, Object>{
      for (final entry in properties.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    await _analytics.logEvent(name: event, parameters: params);
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterFatalError(details);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }
}
