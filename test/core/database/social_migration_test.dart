import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart'
    hide
        LiveTripsCompanion,
        LiveWaypointsCompanion,
        TripsCompanion,
        UserSettingsCompanion,
        WaypointsCompanion;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'legacy_app_database_v10.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('social_migration_test');
    dbFile = File(p.join(tempDir.path, 'legacy.sqlite'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'v10 -> v11 upgrade preserves existing data and adds social tables',
    () async {
      // Seed a populated v10 database on disk, then close it — data
      // persists on disk (unlike an in-memory DB), so it's safe to close
      // before reopening on the real v11 AppDatabase below.
      final legacyDb = LegacyAppDatabaseV10(NativeDatabase(dbFile));

      final tripId = await legacyDb
          .into(legacyDb.trips)
          .insert(
            TripsCompanion.insert(
              uid: 'user-1',
              topSpeedKmh: 120,
              avgSpeedKmh: 60,
              distanceKm: 42.5,
              durationSeconds: 3600,
              startedAt: DateTime(2026, 1, 1),
              remoteId: const Value('trip-remote-1'),
              isSynced: const Value(true),
            ),
          );
      await legacyDb
          .into(legacyDb.waypoints)
          .insert(
            WaypointsCompanion.insert(
              tripId: tripId,
              lat: 31.5,
              lng: 74.3,
              speedKmh: 50,
              accuracyMeters: 5,
              timestamp: DateTime(2026, 1, 1),
            ),
          );
      await legacyDb
          .into(legacyDb.userSettings)
          .insert(
            UserSettingsCompanion.insert(
              uid: 'user-1',
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      final liveTripId = await legacyDb
          .into(legacyDb.liveTrips)
          .insert(
            LiveTripsCompanion.insert(
              uid: 'user-1',
              startedAt: DateTime(2026, 1, 2),
              updatedAt: DateTime(2026, 1, 2),
            ),
          );
      await legacyDb
          .into(legacyDb.liveWaypoints)
          .insert(
            LiveWaypointsCompanion.insert(
              tripLocalId: liveTripId,
              lat: 31.6,
              lng: 74.4,
              speedKmh: 30,
              accuracyMeters: 5,
              timestamp: DateTime(2026, 1, 2),
            ),
          );
      await legacyDb.close();

      // Reopen the SAME file with the real AppDatabase (schemaVersion 11)
      // — drift reads the persisted user_version (10) and runs the real
      // onUpgrade(m, 10, 11).
      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(db.close);

      // Existing data untouched.
      final trips = await db.select(db.trips).get();
      expect(trips, hasLength(1));
      expect(trips.single.uid, 'user-1');
      expect(trips.single.remoteId, 'trip-remote-1');
      expect(trips.single.isSynced, isTrue);
      expect(trips.single.distanceKm, 42.5);

      final waypoints = await db.select(db.waypoints).get();
      expect(waypoints, hasLength(1));
      expect(waypoints.single.tripId, tripId);

      final settings = await db.select(db.userSettings).get();
      expect(settings, hasLength(1));
      expect(settings.single.uid, 'user-1');

      final liveTrips = await db.select(db.liveTrips).get();
      expect(liveTrips, hasLength(1));

      final liveWaypoints = await db.select(db.liveWaypoints).get();
      expect(liveWaypoints, hasLength(1));

      // No duplication from onCreate accidentally also running.
      expect(await db.select(db.trips).get(), hasLength(1));

      // New tables exist and are empty.
      expect(await db.select(db.friends).get(), isEmpty);
      expect(await db.select(db.friendRequests).get(), isEmpty);
      expect(await db.select(db.challenges).get(), isEmpty);
      expect(await db.select(db.challengeProgress).get(), isEmpty);
      expect(await db.select(db.trophies).get(), isEmpty);

      // Explicit constraint assertions on the new schema.

      // friends: unique (ownerUid, friendUid).
      final now = DateTime(2026, 2, 1);
      await db
          .into(db.friends)
          .insert(
            FriendsCompanion.insert(
              remoteId: 'friend-remote-1',
              ownerUid: 'user-1',
              friendUid: 'user-2',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await expectLater(
        db
            .into(db.friends)
            .insert(
              FriendsCompanion.insert(
                remoteId: 'friend-remote-2',
                ownerUid: 'user-1',
                friendUid: 'user-2',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );

      // challenges -> challenge_progress: composite PK + cascade delete.
      final challengeRowId = await db
          .into(db.challenges)
          .insert(
            ChallengesCompanion.insert(
              remoteId: 'challenge-remote-1',
              creatorUid: 'user-1',
              metric: 'distance',
              targetValue: 100,
              period: 'weekly',
              startAt: now,
              endAt: now.add(const Duration(days: 7)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.challengeProgress)
          .insertOnConflictUpdate(
            ChallengeProgressCompanion.insert(
              challengeId: challengeRowId,
              uid: 'user-1',
              targetValue: 100,
            ),
          );
      await db
          .into(db.challengeProgress)
          .insertOnConflictUpdate(
            ChallengeProgressCompanion.insert(
              challengeId: challengeRowId,
              uid: 'user-1',
              currentValue: const Value(42),
              targetValue: 100,
            ),
          );
      final progressRows = await db.select(db.challengeProgress).get();
      expect(progressRows, hasLength(1));
      expect(progressRows.single.currentValue, 42);

      await (db.delete(
        db.challenges,
      )..where((c) => c.id.equals(challengeRowId))).go();
      expect(await db.select(db.challengeProgress).get(), isEmpty);
    },
  );
}
