import 'package:drift/drift.dart';

/// A friend invite from one user to another.
///
/// `remoteId` is **derived from the pair** — `{fromUid}_{toUid}`, see
/// `friendRequestKey` — because a security rule has to be able to name
/// the request that authorises a friendship, and rules have no query. So
/// one logical request between two people in one direction is exactly
/// one row, and re-sending after a withdrawal reuses it rather than
/// adding another.
///
/// That was assumed by every reader since 4b and enforced by nothing:
/// the writer used a plain insert, so each send appended a copy. A real
/// device was found holding the same request three times, which shows
/// one entry three times in a list and leaves "which copy is the
/// status" undefined. Hence the unique index — the same reasoning as
/// `Trophies.remoteId`, and for the same kind of deterministic id.
///
/// (An earlier comment here said uniqueness was deliberately absent so
/// a new `pending` could follow a `declined` for the same pair. That
/// predates derived ids: the follow-up now *is* the same row, moved
/// back to `pending`.)
@TableIndex(
  name: 'idx_friend_requests_remote_id',
  columns: {#remoteId},
  unique: true,
)
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
