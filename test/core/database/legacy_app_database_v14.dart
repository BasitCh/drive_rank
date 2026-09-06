import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/challenge_progress_table.dart';
import 'package:drive_rank/core/database/tables/challenges_table.dart';
import 'package:drive_rank/core/database/tables/deleted_trips_table.dart';
import 'package:drive_rank/core/database/tables/friend_requests_table.dart';
import 'package:drive_rank/core/database/tables/friends_table.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart'
    show LiveTrips, LiveWaypoints;
import 'package:drive_rank/core/database/tables/trip_eligibility_table.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/trophies_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

import 'legacy_tables_pre_v15.dart';

part 'legacy_app_database_v14.g.dart';

/// The thirteen tables that existed at schema v14 — everything through
/// the trip-deletion tombstones, before v15 added
/// `user_settings.username_claimed`.
///
/// `user_settings` is the frozen pre-v15 copy for the reason the v13
/// fixture documents: a live definition here would carry a column v15
/// is about to add, and the migration would fail on the duplicate
/// instead of proving anything.
@DriftDatabase(
  tables: [
    Trips,
    Waypoints,
    LegacyUserSettingsPreV15,
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
class LegacyAppDatabaseV14 extends _$LegacyAppDatabaseV14 {
  LegacyAppDatabaseV14(super.executor);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
