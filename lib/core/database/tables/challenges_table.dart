import 'package:drift/drift.dart';

/// A head-to-head challenge, or a personal target when [opponentUid] is
/// null — one table covers both since a target is just a challenge with
/// no opponent (see `Challenge.isPersonal`).
///
/// `metric` and `period` are stored as `CompetitionMetric.name` /
/// `LeaderboardPeriod.name`.
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
