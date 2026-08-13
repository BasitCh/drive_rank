import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';
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
  tables: [Trips, Waypoints, UserSettings, LiveTrips, LiveWaypoints],
)
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests — pass a custom executor (e.g. in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

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
