import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:drive_rank/shared/services/sync_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNetwork implements NetworkInfo {
  _FakeNetwork();

  bool connected = true;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get connectivityChanges =>
      throw UnimplementedError();

  @override
  Stream<void> get onConnected => const Stream<void>.empty();
}

class _RecordingSink implements RemoteTripSink {
  final uploaded = <int>[];
  bool throwOnce = false;

  @override
  Future<void> uploadTrip(TripRow trip) async {
    if (throwOnce) {
      throwOnce = false;
      throw StateError('simulated network failure');
    }
    uploaded.add(trip.id);
  }
}

class _SilentTelemetry implements TelemetryService {
  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(Object error, StackTrace stack, {bool fatal = false}) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> setUser({required String uid}) async {}

  @override
  Future<void> track(String event, {Map<String, Object?> properties = const {}}) async {}
}

void main() {
  late AppDatabase db;
  late TripRepository trips;
  late _FakeNetwork net;
  late _RecordingSink sink;
  late SyncManager manager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    trips = TripRepository(db);
    net = _FakeNetwork();
    sink = _RecordingSink();
    manager = SyncManager(db, net, sink, _SilentTelemetry());
  });

  tearDown(() async => db.close());

  Future<int> seedTrip({bool synced = false}) async {
    final id = await trips.saveTrip(
      uid: 'u1',
      stats: const LiveTripStats(
        currentSpeedKmh: 0,
        maxSpeedKmh: 120,
        avgSpeedKmh: 60,
        distanceKm: 10,
        durationSeconds: 600,
        maxGforce: 0.5,
        lastPoint: null,
        points: <TripPoint>[],
      ),
      startedAt: DateTime(2026, 5, 16, 10),
      endedAt: DateTime(2026, 5, 16, 10, 10),
      mapTheme: 'regular',
    );
    if (synced) {
      await (db.update(db.trips)..where((t) => t.id.equals(id)))
          .write(const TripsCompanion(isSynced: Value(true)));
    }
    return id;
  }

  test('uploads only the unsynced trips', () async {
    final a = await seedTrip();
    await seedTrip(synced: true);
    final c = await seedTrip();

    final count = await manager.syncNow();

    expect(count, 2);
    expect(sink.uploaded, containsAll([a, c]));
    final remaining = await (db.select(db.trips)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    expect(remaining, isEmpty);
  });

  test('a failed upload leaves the row unsynced so it retries', () async {
    sink.throwOnce = true;
    final a = await seedTrip();
    await seedTrip();

    await manager.syncNow();

    // The failed one is still pending.
    final pending = await (db.select(db.trips)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    expect(pending.map((t) => t.id), contains(a));

    // Retry now succeeds.
    final retried = await manager.syncNow();
    expect(retried, 1);
  });

  test('mutex prevents double-drain when two triggers race', () async {
    await seedTrip();
    final futures = [manager.syncNow(), manager.syncNow()];
    final results = await Future.wait(futures);
    // One drain uploads; the other no-ops because the mutex was held.
    expect(results.where((n) => n == 1), hasLength(1));
    expect(results.where((n) => n == 0), hasLength(1));
  });

  test('markAllUnsynced re-queues everything for a fresh account', () async {
    await seedTrip();
    await seedTrip();
    await manager.syncNow();
    expect(sink.uploaded, hasLength(2));

    await manager.markAllUnsynced();
    sink.uploaded.clear();
    await manager.syncNow();
    expect(sink.uploaded, hasLength(2));
  });
}
