import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/tables/challenge_progress_table.dart';
import 'package:drive_rank/core/database/tables/challenges_table.dart';
import 'package:drive_rank/core/database/tables/deleted_trips_table.dart';
import 'package:drive_rank/core/database/tables/friend_requests_table.dart';
import 'package:drive_rank/core/database/tables/friends_table.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart';
import 'package:drive_rank/core/database/tables/trip_eligibility_table.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/trophies_table.dart';
import 'package:drive_rank/core/database/tables/user_settings_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Drift database — the source of truth for trips, waypoints and settings.
///
/// Reads are always served from this DB (reactive streams) — Firestore is
/// a write-only sync target. Keeps the app fully offline-capable.
@DriftDatabase(
  tables: [
    Trips,
    Waypoints,
    UserSettings,
    LiveTrips,
    LiveWaypoints,
    Friends,
    FriendRequests,
    Challenges,
    ChallengeProgress,
    Trophies,
    TripEligibility,
    DeletedTrips,
  ],
)
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests — pass a custom executor (e.g. in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 adds Trips.road_segment_ids — comma-separated famous-road
        // segment ids the trip's bounding box overlapped at save time.
        // Raw SQL keeps the migration independent of generated code so the
        // file compiles even when build_runner hasn't been re-run yet.
        await customStatement(
          'ALTER TABLE trips ADD COLUMN road_segment_ids TEXT NOT NULL '
          "DEFAULT ''",
        );
      }
      if (from < 3) {
        // v3 adds the LiveTrips + LiveWaypoints tables that back the
        // crash-recovery + service-isolate checkpoint flow. The
        // generated CREATE statements live on the migrator — no need
        // to hand-roll SQL.
        await m.createTable(liveTrips);
        await m.createTable(liveWaypoints);
      }
      if (from < 4) {
        // v4 adds UserSettings.oem_advice_shown — set once after the
        // OEM battery-killer bottom sheet runs so we don't nag the
        // user every trip start.
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN oem_advice_shown '
          'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 5) {
        // v5 adds UserSettings.bg_location_disclosure_acked — flips true
        // after the user sees the Prominent Disclosure dialog (during
        // onboarding or before the first trip start). Google Play
        // policy requires the in-app disclosure ahead of any background
        // location use.
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN '
          'bg_location_disclosure_acked INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 6) {
        // v6 adds UserSettings.speed_goal_kmh / distance_goal_km — the
        // "beat this next" targets shown on Trip Summary and referenced
        // in retention-notification copy. Nullable, no default: null
        // means "no goal set yet" (before the user's first trip).
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN speed_goal_kmh REAL',
        );
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN distance_goal_km REAL',
        );
      }
      if (from < 7) {
        // v7 — elevation, stopped-time, location-footer, and minimum
        // trip length. See PRD items 1/2/4/8/9.
        await customStatement(
          'ALTER TABLE waypoints ADD COLUMN altitude_meters REAL',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN stop_count INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN elevation_gain_meters REAL',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN max_elevation_meters REAL',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN location_name TEXT',
        );
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN min_trip_length_meters '
          'REAL NOT NULL DEFAULT 500',
        );
      }
      if (from < 8) {
        // v8 — heading-based turn direction / lane-change detection,
        // accel/decel split, top cornering speed, and a persisted
        // lifetime 0-100 time. See the Profile page revamp plan.
        await customStatement('ALTER TABLE waypoints ADD COLUMN heading REAL');
        await customStatement(
          'ALTER TABLE trips ADD COLUMN left_turn_count INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN right_turn_count INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN lane_change_count INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN max_acceleration_mps2 REAL NOT '
          'NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN max_deceleration_mps2 REAL NOT '
          'NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN top_cornering_speed_kmh REAL NOT '
          'NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE trips ADD COLUMN zero_to_hundred_seconds REAL',
        );
      }
      if (from < 9) {
        // v9 — remote_id: stable UUID used as the Firestore doc id for
        // cloud trip sync, decoupled from the local autoincrement
        // primary key so two devices restoring/pushing under the same
        // account can't collide on the same path.
        await customStatement('ALTER TABLE trips ADD COLUMN remote_id TEXT');
      }
      if (from < 10) {
        // v10 — free_trip_limit: the free-trip allowance persisted per
        // user, rather than read from a global constant, so lowering
        // the default for new users (3 → 1) can't retroactively cut an
        // existing install's already-granted allowance. Every row that
        // already exists at this migration is, by definition, an
        // existing install — backfill it to the OLD default (3) so it
        // keeps exactly the allowance it already had. New rows created
        // after this point get the new default (1) explicitly at
        // insert time (see UserSettingsRepository.ensureExists).
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN free_trip_limit INTEGER',
        );
        await customStatement(
          'UPDATE user_settings SET free_trip_limit = 3 '
          'WHERE free_trip_limit IS NULL',
        );
      }
      if (from < 11) {
        // v11 — adds the Social Competition feature's local tables:
        // friends, friend requests, challenges (+ per-participant
        // progress), and trophies. Phase 1 scaffolding only — no
        // remote/Firestore sync yet.
        await m.createTable(friends);
        await m.createTable(friendRequests);
        await m.createTable(challenges); // must precede challengeProgress
        await m.createTable(challengeProgress);
        await m.createTable(trophies);
      }
      if (from < 12) {
        // v12 — the competition engine's persistence.
        //
        // `trip_eligibility` records whether a saved trip counts toward
        // competition. Deliberately a separate table rather than columns
        // on `trips`: social state stays out of the production trip
        // schema, and the row is keyed on trip_id alone so it survives
        // both uid-rewriting migrations (see the table's doc comment).
        // No backfill — an absent row reads as eligible, so existing
        // history keeps counting without re-walking every old trip's
        // waypoints.
        await m.createTable(tripEligibility);

        // Collapses a repeated trophy award to one row at the database
        // level, since trophy remote ids are deterministic (see
        // `trophyRemoteId`). Raw SQL keeps this independent of
        // generated code; `IF NOT EXISTS` makes it a no-op on a
        // database that already created the index via `createAll`. Safe
        // to add now precisely because v11 never shipped, so no
        // duplicate rows can exist in the wild to reject it.
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_trophies_remote_id '
          'ON trophies (remote_id)',
        );

        // Carries mock-location evidence through crash recovery — the
        // eligibility check runs on in-memory points, which are rebuilt
        // from live_waypoints after an interrupted trip resumes.
        await customStatement(
          'ALTER TABLE live_waypoints ADD COLUMN is_mocked '
          'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 13) {
        // v13 — rankings_enabled: the kill switch for the public
        // rankings surfaces. Defaults on, and persisted rather than
        // held in memory so the last known answer survives a cold
        // offline launch and every consumer (router, nav bar, page)
        // reads one reactive source. Existing rows default to enabled
        // — nobody loses a feature by upgrading.
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN rankings_enabled '
          'INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (from < 14) {
        // v14 — `deleted_trips`: the tombstones that make deleting a
        // trip stick. Until now a delete only removed the local row, so
        // the cloud copy came back on the next restore. No backfill is
        // possible or wanted — trips already deleted under the old
        // behaviour left no record of ever having existed.
        await m.createTable(deletedTrips);
      }
      if (from < 15) {
        // v15 — username_claimed: whether this account holds its
        // username in the shared Firestore namespace.
        //
        // Defaults false, which is the truthful starting point for
        // every existing install: usernames were never checked for
        // uniqueness, so nobody holds theirs yet. The next launch
        // attempts a claim and flips this when it succeeds. Nobody is
        // renamed and nobody is blocked in the meantime — an unclaimed
        // account simply isn't findable by name.
        await customStatement(
          'ALTER TABLE user_settings ADD COLUMN username_claimed '
          'INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
    beforeOpen: (details) async {
      // SQLite has foreign-key enforcement off by default per connection.
      // Without this, the `onDelete: cascade` on waypoints does nothing
      // and deleting a trip leaves orphaned rows behind.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'drive_rank.sqlite'));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}
