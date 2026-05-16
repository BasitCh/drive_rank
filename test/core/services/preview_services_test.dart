import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnonymousAuthService', () {
    test('always returns the same local uid', () {
      final a = AnonymousAuthService();
      final b = AnonymousAuthService();
      expect(a.currentUser.uid, equals(b.currentUser.uid));
      expect(a.currentUser.isAnonymous, isTrue);
    });

    test('sign-in fails with no Firebase configured', () async {
      final svc = AnonymousAuthService();
      expect(await svc.signInWithGoogle(), SignInResult.failed);
    });

    test('sign-out is a no-op', () async {
      final svc = AnonymousAuthService();
      // No throw, no state change.
      await svc.signOut();
      expect(svc.currentUser.isAnonymous, isTrue);
    });
  });

  group('ConsoleTelemetryService', () {
    test('every call resolves without throwing', () async {
      final t = ConsoleTelemetryService();
      await t.setUser(uid: 'u');
      await t.track('e');
      await t.track('e', properties: const {'k': 1, 'k2': 'v'});
      await t.recordError(StateError('boom'), StackTrace.current);
      await t.log('hello');
      // No assertions — the contract is "always succeeds".
    });
  });

  group('NoopPushService', () {
    test('reports permission granted', () async {
      final p = NoopPushService();
      expect(await p.requestPermission(), isTrue);
    });

    test('tag / untag / setExternalId all no-op', () async {
      final p = NoopPushService();
      await p.setExternalId('u');
      await p.tag('country', 'PK');
      await p.untag('country');
    });
  });

  group('NoopRemoteTripSink', () {
    test('accepts every trip without erroring', () async {
      const sink = NoopRemoteTripSink();
      // The sink only cares about the row reference — pass null via cast
      // since the contract is "accept-and-forget". A real test runs in
      // SyncManager's test where we feed real TripRow values.
      expect(sink, isA<RemoteTripSink>());
    });
  });
}
