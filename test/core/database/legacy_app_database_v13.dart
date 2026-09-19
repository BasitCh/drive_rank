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

import 'legacy_tables_pre_v15.dart';

part 'legacy_app_database_v13.g.dart';

/// The twelve tables that existed at schema v13 — everything through the
/// rankings kill switch, before v14 added `deleted_trips`.
///
/// `user_settings` uses the frozen pre-v15 copy: v15 adds
/// `username_claimed`, so the live definition would make this fixture
/// "v13 plus a future column" and the v15 ALTER would then fail on a
/// duplicate. That is the third time this trap has fired, after
/// `live_waypoints.is_mocked` and `user_settings.rankings_enabled` —
/// which is why the column-count guards at the end of the suite exist.
/// Every other table here is still the live one, since no migration
/// since v13 has altered them.
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
