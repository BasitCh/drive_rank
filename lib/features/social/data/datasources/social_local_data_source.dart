import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:injectable/injectable.dart';

/// Thin Drift CRUD wrapper over the social tables (`friends`,
/// `friend_requests`, `challenges`, `challenge_progress`, `trophies`).
///
/// Returns Drift row types — mapping to domain entities is
/// `SocialRepositoryImpl`'s job, not this class's. Resolving a domain
/// `String` id to the internal autoincrement row id (via `remoteId`) also
/// lives here, since that's a persistence detail the repository/domain
/// layer shouldn't need to know about.
@lazySingleton
class SocialLocalDataSource {
  SocialLocalDataSource(this._db);

  final AppDatabase _db;

  // Friends

  Future<List<FriendRow>> getFriends(String ownerUid) {
    return (_db.select(_db.friends)
          ..where((f) => f.ownerUid.equals(ownerUid)))
        .get();
  }

  Stream<List<FriendRow>> watchFriends(String ownerUid) {
    return (_db.select(_db.friends)
          ..where((f) => f.ownerUid.equals(ownerUid)))
        .watch();
  }

  Future<FriendRow> insertFriend(FriendsCompanion companion) async {
    final id = await _db.into(_db.friends).insert(companion);
    return (_db.select(_db.friends)..where((f) => f.id.equals(id)))
        .getSingle();
  }

  Future<int> deleteFriend({
    required String ownerUid,
    required String friendUid,
  }) {
    return (_db.delete(_db.friends)..where(
          (f) => f.ownerUid.equals(ownerUid) & f.friendUid.equals(friendUid),
        ))
        .go();
  }

  Future<bool> friendshipExists(String ownerUid, String friendUid) async {
    final row =
        await (_db.select(_db.friends)
              ..where(
                (f) =>
                    f.ownerUid.equals(ownerUid) &
                    f.friendUid.equals(friendUid),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  // Friend requests

  Stream<List<FriendRequestRow>> watchIncomingRequests(String toUid) {
    return (_db.select(_db.friendRequests)
          ..where(
            (r) => r.toUid.equals(toUid) & r.status.equals('pending'),
          ))
        .watch();
  }

  Future<List<FriendRequestRow>> getOutgoingRequests(String fromUid) {
    return (_db.select(_db.friendRequests)
          ..where((r) => r.fromUid.equals(fromUid)))
        .get();
  }

  Future<bool> hasPendingRequest(String fromUid, String toUid) async {
    final row =
        await (_db.select(_db.friendRequests)
              ..where(
                (r) =>
                    r.fromUid.equals(fromUid) &
                    r.toUid.equals(toUid) &
                    r.status.equals('pending'),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<FriendRequestRow> insertFriendRequest(
    FriendRequestsCompanion companion,
  ) async {
    final id = await _db.into(_db.friendRequests).insert(companion);
    return (_db.select(_db.friendRequests)..where((r) => r.id.equals(id)))
        .getSingle();
  }

  Future<FriendRequestRow?> getRequestByRemoteId(String remoteId) {
    return (_db.select(_db.friendRequests)
          ..where((r) => r.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateRequestStatus({
    required String remoteId,
    required String status,
    required DateTime updatedAt,
  }) {
    return (_db.update(_db.friendRequests)
          ..where((r) => r.remoteId.equals(remoteId)))
        .write(
          FriendRequestsCompanion(
            status: Value(status),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  // Challenges

  Stream<List<ChallengeRow>> watchChallenges(String uid) {
    return (_db.select(_db.challenges)
          ..where(
            (c) => c.creatorUid.equals(uid) | c.opponentUid.equals(uid),
          ))
        .watch();
  }

  Future<ChallengeRow?> getChallengeByRemoteId(String remoteId) {
    return (_db.select(_db.challenges)
          ..where((c) => c.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ChallengeRow> insertChallenge(ChallengesCompanion companion) async {
    final id = await _db.into(_db.challenges).insert(companion);
    return (_db.select(_db.challenges)..where((c) => c.id.equals(id)))
        .getSingle();
  }

  Future<void> updateChallengeStatus({
    required String remoteId,
    required String status,
    required DateTime updatedAt,
  }) {
    return (_db.update(_db.challenges)
          ..where((c) => c.remoteId.equals(remoteId)))
        .write(
          ChallengesCompanion(
            status: Value(status),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> deleteChallenge(String remoteId) {
    return (_db.delete(_db.challenges)
          ..where((c) => c.remoteId.equals(remoteId)))
        .go();
  }

  // Challenge progress

  Future<List<ChallengeProgressRow>> getProgressForChallenge(
    int challengeRowId,
  ) {
    return (_db.select(_db.challengeProgress)
          ..where((p) => p.challengeId.equals(challengeRowId)))
        .get();
  }

  Future<void> upsertProgress(ChallengeProgressCompanion companion) {
    return _db.into(_db.challengeProgress).insertOnConflictUpdate(companion);
  }

  // Trophies

  Stream<List<TrophyRow>> watchTrophies(String uid) {
    return (_db.select(_db.trophies)..where((t) => t.uid.equals(uid)))
        .watch();
  }

  Future<TrophyRow> insertTrophy(TrophiesCompanion companion) async {
    final id = await _db.into(_db.trophies).insert(companion);
    return (_db.select(_db.trophies)..where((t) => t.id.equals(id)))
        .getSingle();
  }
}
