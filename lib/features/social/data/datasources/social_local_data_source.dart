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

  /// Statuses a challenge can never leave — completed and expired
  /// results are historical fact, and a declined/cancelled challenge
  /// shouldn't spring back to life.
  static const _terminalChallengeStatuses = [
    'completed',
    'expired',
    'declined',
    'cancelled',
  ];

  /// Writes a new status, refusing to overwrite a terminal one.
  ///
  /// The guard lives in the `where` rather than in a caller's
  /// read-then-write so it's race-free and every future caller inherits
  /// it. Returns the number of rows changed — 0 means the challenge was
  /// already terminal (or absent).
  Future<int> updateChallengeStatus({
    required String remoteId,
    required String status,
    required DateTime updatedAt,
  }) {
    return (_db.update(_db.challenges)..where(
          (c) =>
              c.remoteId.equals(remoteId) &
              c.status.isNotIn(_terminalChallengeStatuses),
        ))
        .write(
          ChallengesCompanion(
            status: Value(status),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  /// The user's challenges that are active and whose window contains
  /// [at] — `startAt <= at < endAt`, matching the half-open convention
  /// used everywhere else. Filtered in SQL rather than in Dart so the
  /// query doesn't have to load every challenge the user is party to.
  Future<List<ChallengeRow>> getActiveChallengesAt({
    required String uid,
    required DateTime at,
  }) {
    return (_db.select(_db.challenges)..where(
          (c) =>
              c.status.equals('active') &
              c.startAt.isSmallerOrEqualValue(at) &
              c.endAt.isBiggerThanValue(at) &
              (c.creatorUid.equals(uid) | c.opponentUid.equals(uid)),
        ))
        .get();
  }

  /// The user's active challenges whose window has already closed —
  /// what "expire on touch" acts on. There's no timer anywhere, so a
  /// challenge only learns it expired the next time the user drives.
  Future<List<ChallengeRow>> getLapsedActiveChallenges({
    required String uid,
    required DateTime at,
  }) {
    return (_db.select(_db.challenges)..where(
          (c) =>
              c.status.equals('active') &
              c.endAt.isSmallerOrEqualValue(at) &
              (c.creatorUid.equals(uid) | c.opponentUid.equals(uid)),
        ))
        .get();
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

  Future<ChallengeProgressRow?> getProgress({
    required int challengeRowId,
    required String uid,
  }) {
    return (_db.select(_db.challengeProgress)
          ..where((p) => p.challengeId.equals(challengeRowId) & p.uid.equals(uid))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Writes the recomputed tally for one participant.
  ///
  /// Deliberately narrow: only `currentValue` and `lastCalculatedAt` are
  /// touched. A full-companion upsert would let a recompute pass
  /// `completedAt: null` and silently erase a completion, or overwrite
  /// the `targetValue` snapshot taken when the challenge was created.
  /// Completion is a separate, explicit write — see
  /// [markProgressComplete].
  Future<void> upsertProgressValue({
    required int challengeRowId,
    required String uid,
    required double currentValue,
    required double targetValue,
    required DateTime lastCalculatedAt,
  }) {
    return _db
        .into(_db.challengeProgress)
        .insertOnConflictUpdate(
          ChallengeProgressCompanion.insert(
            challengeId: challengeRowId,
            uid: uid,
            currentValue: Value(currentValue),
            // Only consulted on first insert; the conflict path below
            // leaves an existing row's target untouched.
            targetValue: targetValue,
            lastCalculatedAt: Value(lastCalculatedAt),
          ),
        );
  }

  /// Stamps completion, once. Write-once by construction: the `where`
  /// requires `completed_at IS NULL`, so a later recompute can't move
  /// or clear the timestamp even if the tally later drops below target
  /// (a trip deletion can do exactly that).
  Future<int> markProgressComplete({
    required int challengeRowId,
    required String uid,
    required DateTime completedAt,
  }) {
    return (_db.update(_db.challengeProgress)..where(
          (p) =>
              p.challengeId.equals(challengeRowId) &
              p.uid.equals(uid) &
              p.completedAt.isNull(),
        ))
        .write(ChallengeProgressCompanion(completedAt: Value(completedAt)));
  }

  // Trophies

  Stream<List<TrophyRow>> watchTrophies(String uid) {
    return (_db.select(_db.trophies)..where((t) => t.uid.equals(uid)))
        .watch();
  }

  Future<List<TrophyRow>> getTrophies(String uid) {
    return (_db.select(_db.trophies)..where((t) => t.uid.equals(uid))).get();
  }

  /// Inserts a trophy unless its (deterministic) `remoteId` is already
  /// present, returning null in that case.
  ///
  /// `insertOrIgnore` against the unique index on `remote_id` is what
  /// makes awarding safe under concurrency — two trips saved
  /// back-to-back would both pass a read-then-insert check, but only
  /// one row can land here.
  Future<TrophyRow?> insertTrophyIfAbsent(TrophiesCompanion companion) {
    return _db
        .into(_db.trophies)
        .insertReturningOrNull(companion, mode: InsertMode.insertOrIgnore);
  }

  // Trip eligibility

  Future<void> upsertTripEligibility(TripEligibilityCompanion companion) {
    return _db.into(_db.tripEligibility).insertOnConflictUpdate(companion);
  }

  Future<TripEligibilityRow?> getTripEligibility(int tripId) {
    return (_db.select(_db.tripEligibility)
          ..where((e) => e.tripId.equals(tripId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Every trip of [uid] started inside the window, paired with its
  /// eligibility verdict when one exists.
  ///
  /// A **left** join, and the null case must be read as eligible by the
  /// caller: only trips saved since the competition engine shipped have
  /// a verdict row, so an inner join (or a `WHERE eligible = 1`) would
  /// silently drop the user's entire pre-existing history from every
  /// leaderboard.
  Future<List<(TripRow, TripEligibilityRow?)>> getTripsWithEligibility({
    required String uid,
    required DateTime start,
    DateTime? end,
  }) async {
    var predicate =
        _db.trips.uid.equals(uid) &
        _db.trips.startedAt.isBiggerOrEqualValue(start);
    if (end != null) {
      predicate = predicate & _db.trips.startedAt.isSmallerThanValue(end);
    }

    final rows =
        await (_db.select(_db.trips).join([
          leftOuterJoin(
            _db.tripEligibility,
            _db.tripEligibility.tripId.equalsExp(_db.trips.id),
          ),
        ])..where(predicate)).get();

    return [
      for (final row in rows)
        (row.readTable(_db.trips), row.readTableOrNull(_db.tripEligibility)),
    ];
  }
}
