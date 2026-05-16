import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
@DriftDatabase(tables: [Trips, Waypoints, UserSettings])
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests — pass a custom executor (e.g. in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

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
