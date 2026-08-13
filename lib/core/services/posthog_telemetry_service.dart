import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog-backed telemetry — analytics only. Crash/error reporting
/// stays on Firebase Crashlytics (see [CompositeTelemetryService]);
/// this fires a lightweight correlated event so an error still shows
/// up on PostHog's own timeline next to the product events around it.
///
/// PostHog is the funnel/cohort/retention tool of choice here — it's
/// what actually answers "did this user come back for a 2nd trip,"
/// which Firebase Analytics' free tier reports don't do well.
class PosthogTelemetryService implements TelemetryService {
  PosthogTelemetryService();

  @override
  Future<void> setUser({required String uid}) async {
    await Posthog().identify(userId: uid);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    // `$set` is PostHog's documented magic property key for updating a
    // person property without a "real" event attached — works whether
    // or not `identify` has run yet (it just attaches to the
    // anonymous profile, which PostHog merges into the identified one
    // later).
    await Posthog().capture(
      eventName: r'$set',
      properties: {
        r'$set': {name: value ?? ''},
      },
    );
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
    await Posthog().capture(eventName: event, properties: params);
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await Posthog().capture(
      eventName: 'flutter_error',
      properties: {'error': details.exceptionAsString()},
    );
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    await Posthog().capture(
      eventName: 'app_error',
      properties: {'error': error.toString(), 'fatal': fatal},
    );
  }

  @override
  Future<void> log(String message) async {
    // Crashlytics-specific breadcrumb semantics (visible in the *next*
    // crash report) — no PostHog equivalent worth the event volume.
    // Firebase's implementation still receives this via the composite.
  }
}
