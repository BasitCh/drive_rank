import 'package:drift/drift.dart';

/// The pre-v17 `challenges`, in its own file on purpose.
///
/// Same reason as the pre-v15 `user_settings` and the pre-v16
/// `friend_requests`: two table classes mapping to one SQL name inside a
/// single imported library make drift **silently drop one**, and the
/// fixture then generates without that table.

/// `challenges` as it stood through v16 — before v17 added the unique
/// index on `remote_id`.
///
/// Column-for-column identical to the live table; the only difference is
/// the absent `@TableIndex`. A fixture importing the live class would
/// have gained the index the moment it was added, so the duplicate rows
/// v17 exists to prevent could not be seeded and the migration would go
/// untested for the only case it was written for. Fourth time this trap
/// has been walked into; first time it was seen coming.
@DataClassName('LegacyChallengePreV17Row')
class LegacyChallengesPreV17 extends Table {
  @override
  String get tableName => 'challenges';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get creatorUid => text()();
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

/// The pre-v17 `challenge_progress`, frozen **because of its foreign
/// key**, not because v17 changes it.
///
/// The live `ChallengeProgress` references the live `Challenges`, so
/// including it here would pull that class into this library alongside
/// the frozen copy above — two tables mapping the SQL name `challenges`
/// in one library, which drift resolves by silently dropping one. The
/// fixture then generates against whichever it kept, and the failure
/// surfaces as a missing type in generated code rather than anything
/// legible.
///
/// Safe to share this file with the frozen `challenges`: they map
/// different SQL names, and it is the *name* collision that bites.
@DataClassName('LegacyChallengeProgressPreV17Row')
class LegacyChallengeProgressPreV17 extends Table {
  @override
  String get tableName => 'challenge_progress';

  IntColumn get challengeId => integer().references(
    LegacyChallengesPreV17,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get uid => text()();
  RealColumn get currentValue => real().withDefault(const Constant(0))();
  RealColumn get targetValue => real()();
  DateTimeColumn get lastCalculatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {challengeId, uid};
}
