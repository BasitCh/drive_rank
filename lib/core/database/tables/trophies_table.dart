import 'package:drift/drift.dart';

/// One row per trophy a user has unlocked.
///
/// `type` is stored as `TrophyType.name`. No uniqueness constraint — some
/// trophy types can legitimately be earned more than once; de-duplicating
/// the "first…" trophies is award-time logic, not a schema concern.
@DataClassName('TrophyRow')
class Trophies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get uid => text()();
  TextColumn get type => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();
}
