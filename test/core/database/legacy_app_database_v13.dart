import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/challenge_progress_table.dart';
import 'package:drive_rank/core/database/tables/challenges_table.dart';
import 'package:drive_rank/core/database/tables/friend_requests_table.dart';
import 'package:drive_rank/core/database/tables/friends_table.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart'
    show LiveTrips, LiveWaypoints;
import 'package:drive_rank/core/database/tables/trip_eligibility_table.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/trophies_table.dart';
import 'package:drive_rank/core/database/tables/user_settings_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

part 'legacy_app_database_v13.g.dart';

/// The twelve tables that existed at schema v13 — everything through the
/// rankings kill switch, before v14 added `deleted_trips`.
///
/// Every definition here is the live one. v14 only *adds* a table; it
/// alters nothing, so no frozen copies are needed. The moment v14's
/// successor changes a column on any table above, that table has to be
/// frozen into `legacy_tables.dart` and swapped in here — the trap that
/// has already caught `live_waypoints.is_mocked` and
/// `user_settings.rankings_enabled`.
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
  ],
)
class LegacyAppDatabaseV13 extends _$LegacyAppDatabaseV13 {
  LegacyAppDatabaseV13(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
