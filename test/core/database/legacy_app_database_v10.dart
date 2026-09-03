import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart'
    show LiveTrips;
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

import 'legacy_tables.dart';

part 'legacy_app_database_v10.g.dart';

/// The five tables that existed at schema v10, for seeding a populated
/// "pre-migration" database in the migration tests.
///
/// Tables no later migration has altered are imported live, so their
/// DDL is guaranteed identical to a real v10 install. `live_waypoints`
/// (v12 added a column) and `user_settings` (v13 added one) are the
/// exceptions and use frozen copies; see `legacy_tables.dart` for why
/// that matters.
@DriftDatabase(
  tables: [
    Trips,
    Waypoints,
    LegacyUserSettingsPreV13,
    LiveTrips,
    LegacyLiveWaypointsPreV12,
  ],
)
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
