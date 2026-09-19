import 'package:drift/drift.dart';

/// A head-to-head challenge, or a personal target when [opponentUid] is
/// null — one table covers both since a target is just a challenge with
/// no opponent (see `Challenge.isPersonal`).
///
/// `metric` and `period` are stored as `CompetitionMetric.name` /
/// `LeaderboardPeriod.name`.
/// `remoteId` is the challenge's stable UUID and is **uniquely
/// indexed**: from 4d a challenge can arrive from the opponent's
/// device, and the sync upserts it by that id. Without the constraint
/// every reconciliation pass appends another copy — the exact bug that
/// `friend_requests` shipped with and had to be migrated out of in v16,
/// caught here before it could happen twice.
@TableIndex(name: 'idx_challenges_remote_id', columns: {#remoteId}, unique: true)
@DataClassName('ChallengeRow')
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get creatorUid => text()();

  /// Null for a personal target — not competitive against another user.
  TextColumn get opponentUid => text().nullable()();

  TextColumn get metric => text()();
  RealColumn get targetValue => real()();
  TextColumn get period => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
