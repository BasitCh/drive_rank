import 'package:drift/drift.dart';

/// The pre-v16 `friend_requests`, in its own file on purpose.
///
/// Same reason as the pre-v13 and pre-v15 copies of `user_settings`: two
/// table classes mapping to the same SQL name in one imported library
/// make drift **silently drop one** — no error, no warning, and the
/// fixture generates without that table. One frozen copy per file keeps
/// each fixture importing exactly the shape it needs.

/// `friend_requests` as it stood through v15 — before v16 collapsed
/// duplicate rows and added the unique index on `remote_id`.
///
/// Column-for-column identical to the live table; the *only* difference
/// is the absent `@TableIndex`. That is the whole point: a fixture that
/// imported the live class would have silently gained the index the
/// moment it was added, so seeding the duplicate rows v16 exists to
/// collapse became impossible and the migration went untested for the
/// only case it was written for. This is the third time a fixture
/// reusing a live definition has hidden the thing under test.
@DataClassName('LegacyFriendRequestPreV16Row')
class LegacyFriendRequestsPreV16 extends Table {
  @override
  String get tableName => 'friend_requests';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get fromUid => text()();
  TextColumn get toUid => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
