import 'package:drift/drift.dart';

/// A friend invite from one user to another.
///
/// No DB-level uniqueness on `(fromUid, toUid)` — a new `pending` request
/// can legitimately follow a prior `declined`/`cancelled` one for the same
/// pair. "Already has a pending request" is enforced by the repository,
/// not the schema.
@DataClassName('FriendRequestRow')
class FriendRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get fromUid => text()();
  TextColumn get toUid => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
