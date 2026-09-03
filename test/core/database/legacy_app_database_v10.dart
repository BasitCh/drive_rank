import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/user_settings_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

part 'legacy_app_database_v10.g.dart';

/// A second, minimal `@DriftDatabase` over exactly the 5 tables that
/// existed at schema v10 — reuses the SAME table classes `AppDatabase`
/// uses today (they aren't touched by the v11 social migration), so the
/// DDL this produces is guaranteed identical to what a real v10 install
/// has. Exists only to seed a populated "pre-migration" database for
/// `social_migration_test.dart`.
@DriftDatabase(tables: [Trips, Waypoints, UserSettings, LiveTrips, LiveWaypoints])
class LegacyAppDatabaseV10 extends _$LegacyAppDatabaseV10 {
  LegacyAppDatabaseV10(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
