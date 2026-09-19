import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/challenges_table.dart';

/// One row per participant per challenge — the running tally toward
/// [targetValue]. `targetValue` is a denormalized snapshot of the parent
/// challenge's target at creation time (read-path convenience, same
/// reasoning as `Trips.roadSegmentIds`).
///
/// Cascades on delete from [Challenges] — removing a challenge removes its
/// progress rows with it.
@DataClassName('ChallengeProgressRow')
class ChallengeProgress extends Table {
  IntColumn get challengeId =>
      integer().references(Challenges, #id, onDelete: KeyAction.cascade)();
  TextColumn get uid => text()();
  RealColumn get currentValue => real().withDefault(const Constant(0))();
  RealColumn get targetValue => real()();
  DateTimeColumn get lastCalculatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {challengeId, uid};
}
