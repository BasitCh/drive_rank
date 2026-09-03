import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/challenge_progress_table.dart';
import 'package:drive_rank/core/database/tables/challenges_table.dart';
import 'package:drive_rank/core/database/tables/friend_requests_table.dart';
import 'package:drive_rank/core/database/tables/friends_table.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart'
    show LiveTrips;
import 'package:drive_rank/core/database/tables/trips_table.dart';
import 'package:drive_rank/core/database/tables/user_settings_table.dart';
import 'package:drive_rank/core/database/tables/waypoints_table.dart';

import 'legacy_tables.dart';

part 'legacy_app_database_v11.g.dart';

/// The ten tables that existed at schema v11 — the social tables from
/// phase 1, before the competition engine's v12 additions.
///
/// This path only ever existed on development devices (v11 was never
/// released), but it's the one most easily broken: putting the v12
/// table creation inside the `from < 11` block, for instance, would
/// still pass a 10 → 12 test while leaving every dev database without
/// it.
///
/// `live_waypoints` and `trophies` use frozen pre-v12 copies because
/// v12 altered both — see `legacy_tables.dart`.
@DriftDatabase(
  tables: [
    Trips,
    Waypoints,
    UserSettings,
    LiveTrips,
    LegacyLiveWaypointsPreV12,
    Friends,
    FriendRequests,
    Challenges,
    ChallengeProgress,
    LegacyTrophiesV11,
  ],
)
class LegacyAppDatabaseV11 extends _$LegacyAppDatabaseV11 {
  LegacyAppDatabaseV11(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
