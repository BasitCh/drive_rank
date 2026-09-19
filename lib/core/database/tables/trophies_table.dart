import 'package:drift/drift.dart';

/// One row per trophy a user has unlocked.
///
/// `type` is stored as `TrophyType.name`. `remoteId` is deliberately
/// **deterministic**, not a random UUID — see `trophyRemoteId` — and
/// uniquely indexed, so a repeated award for the same
/// (type, uid, period) collapses to one row at the database level rather
/// than relying on a read-then-insert that two concurrent trip saves
/// would both pass.
@TableIndex(name: 'idx_trophies_remote_id', columns: {#remoteId}, unique: true)
@DataClassName('TrophyRow')
class Trophies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get uid => text()();
  TextColumn get type => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();
}
