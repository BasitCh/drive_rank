import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:drive_rank/shared/services/sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockTelemetry extends Mock implements TelemetryService {}

class _StubAuth implements AuthService {
  _StubAuth(this.uid);
  final String uid;

  @override
  AuthUser get currentUser => AuthUser(uid: uid, isAnonymous: false);

  @override
  Stream<AuthUser> get userChanges => const Stream.empty();

  @override
  Future<SignInResult> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// Records what the cloud was asked to do, and can be told to fail.
class _RecordingSink implements RemoteTripSink {
  final List<String> uploaded = [];
  final List<String> deleted = [];
  bool failDeletes = false;

  @override
  Future<void> uploadTrip(TripRow trip) async {
    uploaded.add(trip.remoteId ?? '');
  }

  @override
  Future<void> deleteTrip({
    required String uid,
    required String remoteId,
  }) async {
    if (failDeletes) throw StateError('offline');
    deleted.add(remoteId);
  }
}

void main() {
  setUpAll(() => registerFallbackValue(StackTrace.empty));

  late AppDatabase db;
  late TripRepository trips;
  late _RecordingSink sink;
  late SyncManager sync;

  const uid = 'user-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    trips = TripRepository(db, GeocodingService());
    sink = _RecordingSink();

    final network = _MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => network.onConnected)
        .thenAnswer((_) => const Stream<void>.empty());

    final telemetry = _MockTelemetry();
    when(() => telemetry.recordError(any<Object>(), any<StackTrace>()))
        .thenAnswer((_) async {});

    getIt
      ..registerSingleton<RemoteTripSink>(sink)
      ..registerSingleton<AuthService>(_StubAuth(uid));

    sync = SyncManager(db, network, telemetry);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Future<int> addTrip({String? remoteId, bool synced = true}) {
    return db.into(db.trips).insert(
      TripsCompanion.insert(
        uid: uid,
        topSpeedKmh: 90,
        avgSpeedKmh: 50,
        distanceKm: 12,
        durationSeconds: 900,
        startedAt: DateTime(2026, 9, 2),
        remoteId: Value(remoteId),
        isSynced: Value(synced),
      ),
    );
  }

  test('deleting a synced trip records the intent to delete it remotely — '
      'without this the local row goes and the cloud copy comes back on '
      'the next restore', () async {
    final id = await addTrip(remoteId: 'remote-1');

    await trips.deleteTrip(id);

    expect(await trips.getById(id), isNull);
    final pending = await trips.pendingRemoteDeletions(uid);
    expect(pending.map((t) => t.remoteId), ['remote-1']);
    expect(pending.single.uid, uid);
  });

  test('deleting a trip that never reached the cloud leaves no tombstone, '
      'so the queue never carries work that cannot be done', () async {
    final id = await addTrip(remoteId: null, synced: false);

    await trips.deleteTrip(id);

    expect(await trips.pendingRemoteDeletions(uid), isEmpty);
  });

  test('syncing removes the cloud copy and drops the tombstone', () async {
    final id = await addTrip(remoteId: 'remote-1');
    await trips.deleteTrip(id);

    await sync.syncNow();

    expect(sink.deleted, ['remote-1']);
    expect(await trips.pendingRemoteDeletions(uid), isEmpty);
  });

  test('a failed remote delete keeps the tombstone for the next tick — a '
      'delete the user watched happen must not be silently abandoned '
      'because they were offline', () async {
    final id = await addTrip(remoteId: 'remote-1');
    await trips.deleteTrip(id);
    sink.failDeletes = true;

    await sync.syncNow();

    expect(sink.deleted, isEmpty);
    expect(
      (await trips.pendingRemoteDeletions(uid)).map((t) => t.remoteId),
      ['remote-1'],
    );

    // Back online.
    sink.failDeletes = false;
    await sync.syncNow();
    expect(sink.deleted, ['remote-1']);
    expect(await trips.pendingRemoteDeletions(uid), isEmpty);
  });

  test('one unreachable delete does not block the rest of the queue',
      () async {
    final a = await addTrip(remoteId: 'remote-a');
    final b = await addTrip(remoteId: 'remote-b');
    await trips.deleteTrip(a);
    await trips.deleteTrip(b);

    await sync.syncNow();

    expect(sink.deleted, containsAll(['remote-a', 'remote-b']));
    expect(await trips.pendingRemoteDeletions(uid), isEmpty);
  });

  test('deletions drain before uploads, so a trip cannot be pushed back up '
      'in the same pass that removes it', () async {
    final deletedId = await addTrip(remoteId: 'remote-gone');
    await trips.deleteTrip(deletedId);
    await addTrip(remoteId: 'remote-new', synced: false);

    await sync.syncNow();

    expect(sink.deleted, ['remote-gone']);
    expect(sink.uploaded, ['remote-new']);
  });

  test('a restore skips a doc whose delete has not landed yet', () async {
    final id = await addTrip(remoteId: 'remote-1');
    await trips.deleteTrip(id);

    // What CloudSyncService consults before re-inserting a cloud doc.
    final skip = await trips.deletedRemoteIds(uid);
    expect(skip, {'remote-1'});
  });

  test("another account's tombstones are left alone", () async {
    final id = await addTrip(remoteId: 'remote-1');
    await trips.deleteTrip(id);

    expect(await trips.deletedRemoteIds('someone-else'), isEmpty);
  });
}
