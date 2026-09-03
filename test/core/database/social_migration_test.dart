import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Prefixed because each fixture generates its own same-named companion
// and row classes (`TripsCompanion`, `TripRow`, …) that are distinct
// types from the live database's, even though the DDL matches.
import 'legacy_app_database_v10.dart' as v10;
import 'legacy_app_database_v11.dart' as v11;
import 'legacy_app_database_v12.dart' as v12;

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

  /// Opens the real database on the seeded file so the actual
  /// `onUpgrade` runs, and closes it at the end of the test.
  AppDatabase openMigrated() {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);
    return db;
  }

  Future<void> expectSocialTablesExistAndAreEmpty(AppDatabase db) async {
    expect(await db.select(db.friends).get(), isEmpty);
    expect(await db.select(db.friendRequests).get(), isEmpty);
    expect(await db.select(db.challenges).get(), isEmpty);
    expect(await db.select(db.challengeProgress).get(), isEmpty);
    expect(await db.select(db.trophies).get(), isEmpty);
    expect(await db.select(db.tripEligibility).get(), isEmpty);
  }

  group('v10 -> v12 — the real production upgrade path', () {
    // v11 was never released, so every install in the wild jumps
    // straight from 10 to 12.
    test('preserves every existing row and adds the social schema', () async {
      final legacyDb = v10.LegacyAppDatabaseV10(NativeDatabase(dbFile));

      final tripId = await legacyDb
          .into(legacyDb.trips)
          .insert(
            v10.TripsCompanion.insert(
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
            v10.WaypointsCompanion.insert(
              tripId: tripId,
              lat: 31.5,
              lng: 74.3,
              speedKmh: 50,
              accuracyMeters: 5,
              timestamp: DateTime(2026, 1, 1),
            ),
          );
      await legacyDb
          .into(legacyDb.legacyUserSettingsPreV13)
          .insert(
            v10.LegacyUserSettingsPreV13Companion.insert(
              uid: 'user-1',
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      final liveTripId = await legacyDb
          .into(legacyDb.liveTrips)
          .insert(
            v10.LiveTripsCompanion.insert(
              uid: 'user-1',
              startedAt: DateTime(2026, 1, 2),
              updatedAt: DateTime(2026, 1, 2),
            ),
          );
      await legacyDb
          .into(legacyDb.legacyLiveWaypointsPreV12)
          .insert(
            v10.LegacyLiveWaypointsPreV12Companion.insert(
              tripLocalId: liveTripId,
              lat: 31.6,
              lng: 74.4,
              speedKmh: 30,
              accuracyMeters: 5,
              timestamp: DateTime(2026, 1, 2),
            ),
          );
      // Safe to close: the data is on disk, not in memory.
      await legacyDb.close();

      final db = openMigrated();

      final trips = await db.select(db.trips).get();
      expect(trips, hasLength(1));
      expect(trips.single.id, tripId);
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

      expect(await db.select(db.liveTrips).get(), hasLength(1));

      final liveWaypoints = await db.select(db.liveWaypoints).get();
      expect(liveWaypoints, hasLength(1));
      // The column v12 added, defaulted for the pre-existing row.
      expect(liveWaypoints.single.isMocked, isFalse);

      await expectSocialTablesExistAndAreEmpty(db);
    });

    test('leaves trip_eligibility empty rather than backfilling — an '
        'absent verdict reads as eligible, so existing history keeps '
        "counting without re-walking every old trip's waypoints", () async {
      final legacyDb = v10.LegacyAppDatabaseV10(NativeDatabase(dbFile));
      for (var i = 0; i < 3; i++) {
        await legacyDb
            .into(legacyDb.trips)
            .insert(
              v10.TripsCompanion.insert(
                uid: 'user-1',
                topSpeedKmh: 100,
                avgSpeedKmh: 50,
                distanceKm: 10,
                durationSeconds: 600,
                startedAt: DateTime(2026, 1, i + 1),
              ),
            );
      }
      await legacyDb.close();

      final db = openMigrated();
      expect(await db.select(db.trips).get(), hasLength(3));
      expect(await db.select(db.tripEligibility).get(), isEmpty);
    });
  });

  group('v11 -> v12 — the development upgrade path', () {
    test('adds the competition schema without disturbing phase-1 social '
        'rows', () async {
      final legacyDb = v11.LegacyAppDatabaseV11(NativeDatabase(dbFile));
      final now = DateTime(2026, 2, 1);

      await legacyDb
          .into(legacyDb.friends)
          .insert(
            v11.FriendsCompanion.insert(
              remoteId: 'friend-1',
              ownerUid: 'user-1',
              friendUid: 'user-2',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await legacyDb
          .into(legacyDb.legacyTrophiesV11)
          .insert(
            v11.LegacyTrophiesV11Companion.insert(
              remoteId: 'roadWarrior:user-1:2026-W05',
              uid: 'user-1',
              type: 'roadWarrior',
              unlockedAt: now,
            ),
          );
      await legacyDb.close();

      final db = openMigrated();

      expect(await db.select(db.friends).get(), hasLength(1));
      expect(await db.select(db.trophies).get(), hasLength(1));
      expect(await db.select(db.tripEligibility).get(), isEmpty);
      expect(await db.select(db.liveWaypoints).get(), isEmpty);
    });

    test('creates the unique index that makes trophy awards idempotent — '
        'a duplicate remote id must be rejected even on a database that '
        'predates the index', () async {
      final legacyDb = v11.LegacyAppDatabaseV11(NativeDatabase(dbFile));
      await legacyDb.close();

      final db = openMigrated();
      final now = DateTime(2026, 2, 1);

      TrophiesCompanion trophy() => TrophiesCompanion.insert(
        remoteId: 'consistent:user-1:2026-W05',
        uid: 'user-1',
        type: 'consistent',
        unlockedAt: now,
      );

      await db.into(db.trophies).insert(trophy());
      await expectLater(
        db.into(db.trophies).insert(trophy()),
        throwsA(anything),
      );
    });
  });

  group('v12 -> v13 — the rankings kill switch', () {
    test('adds rankings_enabled defaulting to on, so upgrading never '
        'takes the feature away from an existing user', () async {
      final legacyDb = v12.LegacyAppDatabaseV12(NativeDatabase(dbFile));
      await legacyDb
          .into(legacyDb.legacyUserSettingsPreV13)
          .insert(
            v12.LegacyUserSettingsPreV13Companion.insert(
              uid: 'user-1',
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      await legacyDb.close();

      final db = openMigrated();
      final settings = await db.select(db.userSettings).get();
      expect(settings, hasLength(1));
      expect(settings.single.uid, 'user-1');
      expect(settings.single.rankingsEnabled, isTrue);
    });

    test('preserves the competition schema and its rows', () async {
      final legacyDb = v12.LegacyAppDatabaseV12(NativeDatabase(dbFile));
      final tripId = await legacyDb
          .into(legacyDb.trips)
          .insert(
            v12.TripsCompanion.insert(
              uid: 'user-1',
              topSpeedKmh: 90,
              avgSpeedKmh: 50,
              distanceKm: 20,
              durationSeconds: 900,
              startedAt: DateTime(2026, 4, 1),
            ),
          );
      await legacyDb
          .into(legacyDb.tripEligibility)
          .insert(
            v12.TripEligibilityCompanion.insert(
              tripId: Value(tripId),
              eligible: true,
              startedAtUtcOffsetMinutes: 300,
              evaluatedAt: DateTime(2026, 4, 1),
            ),
          );
      await legacyDb.close();

      final db = openMigrated();
      expect(await db.select(db.trips).get(), hasLength(1));
      final eligibility = await db.select(db.tripEligibility).get();
      expect(eligibility, hasLength(1));
      expect(eligibility.single.tripId, tripId);
      expect(eligibility.single.eligible, isTrue);
    });
  });

  group('fresh install at v13', () {
    // Catches a table added to the migration but not to the
    // `@DriftDatabase` tables list — `createAll` would skip it and only
    // upgraded databases would have it.
    test('onCreate builds the whole schema, including trip_eligibility',
        () async {
      final db = openMigrated();
      expect(await db.select(db.trips).get(), isEmpty);
      await expectSocialTablesExistAndAreEmpty(db);
    });

    Future<int> insertTrip(AppDatabase db) {
      return db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: 'user-1',
              topSpeedKmh: 100,
              avgSpeedKmh: 50,
              distanceKm: 10,
              durationSeconds: 600,
              startedAt: DateTime(2026, 3, 1),
            ),
          );
    }

    test('trip_eligibility cascades away with its trip', () async {
      final db = openMigrated();
      final tripId = await insertTrip(db);
      await db
          .into(db.tripEligibility)
          .insert(
            TripEligibilityCompanion.insert(
              tripId: Value(tripId),
              eligible: true,
              startedAtUtcOffsetMinutes: 300,
              evaluatedAt: DateTime(2026, 3, 1),
            ),
          );
      expect(await db.select(db.tripEligibility).get(), hasLength(1));

      await (db.delete(db.trips)..where((t) => t.id.equals(tripId))).go();
      expect(await db.select(db.tripEligibility).get(), isEmpty);
    });

    test('a verdict for a trip that does not exist is rejected — proves '
        'the foreign key actually points at trips, which SQLite would '
        'otherwise only complain about at insert time', () async {
      final db = openMigrated();
      await expectLater(
        db
            .into(db.tripEligibility)
            .insert(
              TripEligibilityCompanion.insert(
                tripId: const Value(999999),
                eligible: true,
                startedAtUtcOffsetMinutes: 0,
                evaluatedAt: DateTime(2026, 3, 1),
              ),
            ),
        throwsA(anything),
      );
    });

    // These guards exist because the fixtures import live table classes
    // wherever a table has never been altered, which silently stops
    // being faithful the moment one is. Both times a migration has
    // touched an existing table (v12's live_waypoints, v13's
    // user_settings) the fixtures broke — loudly the first time, and
    // these assertions are what make the next one loud too. When a
    // count changes here, freeze that table's old shape in
    // legacy_tables.dart and repoint the older fixtures at it.
    test('the fixtures still match the live trips schema', () async {
      final db = openMigrated();
      final columns = await db.customSelect('PRAGMA table_info(trips)').get();
      expect(columns, hasLength(33));
    });

    test('the fixtures still match the live user_settings schema', () async {
      final db = openMigrated();
      final columns = await db
          .customSelect('PRAGMA table_info(user_settings)')
          .get();
      // 26 at v12, plus rankings_enabled.
      expect(columns, hasLength(27));
    });
  });
}
