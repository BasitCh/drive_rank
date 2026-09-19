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
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

import 'legacy_tables.dart';

part 'legacy_app_database_v12.g.dart';

/// The eleven tables that existed at schema v12 — everything through the
/// competition engine, before v13 added the rankings kill switch.
///
/// `live_waypoints` keeps its live definition here (v12 is the version
/// that added `is_mocked`, so at v12 the column exists), while
/// `user_settings` uses the frozen pre-v13 copy because v13 is the
/// migration under test. `trophies` is live too — its unique index
/// landed in v12.
@DriftDatabase(
  tables: [
    Trips,
    Waypoints,
    LegacyUserSettingsPreV13,
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
class LegacyAppDatabaseV12 extends _$LegacyAppDatabaseV12 {
  LegacyAppDatabaseV12(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
