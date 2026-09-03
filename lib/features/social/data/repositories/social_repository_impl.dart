import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart'
    as domain;
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Local (Drift-backed) implementation of [SocialRepository].
///
/// Owns every row ↔ entity mapping (`remoteId` ↔ entity `id`, `.name` ↔
/// enum) so [SocialLocalDataSource] can stay a thin, entity-agnostic
/// CRUD wrapper — mirrors `AssetCarRepository`'s JSON ↔ entity mapping.
@LazySingleton(as: SocialRepository)
class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._local);

  final SocialLocalDataSource _local;

  // Friends

  @override
  Future<List<Friend>> getFriends(String uid) async {
    final rows = await _local.getFriends(uid);
    return rows.map(_friendFromRow).toList();
  }

  @override
  Stream<List<Friend>> watchFriends(String uid) {
    return _local
        .watchFriends(uid)
        .map((rows) => rows.map(_friendFromRow).toList());
  }

  @override
  Future<Friend> addFriend({
    required String ownerUid,
    required String friendUid,
  }) async {
    final now = DateTime.now();
    final row = await _local.insertFriend(
      FriendsCompanion.insert(
        remoteId: const Uuid().v4(),
        ownerUid: ownerUid,
        friendUid: friendUid,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return _friendFromRow(row);
  }

  @override
  Future<void> removeFriend({
    required String ownerUid,
    required String friendUid,
  }) {
    return _local.deleteFriend(ownerUid: ownerUid, friendUid: friendUid);
  }

  @override
  Future<bool> areFriends(String uidA, String uidB) async {
    return await _local.friendshipExists(uidA, uidB) ||
        await _local.friendshipExists(uidB, uidA);
  }

  // Friend requests

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return _local
        .watchIncomingRequests(uid)
        .map((rows) => rows.map(_friendRequestFromRow).toList());
  }

  @override
  Future<List<FriendRequest>> getOutgoingRequests(String uid) async {
    final rows = await _local.getOutgoingRequests(uid);
    return rows.map(_friendRequestFromRow).toList();
  }

  @override
  Future<FriendRequest> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    final hasPending = await _local.hasPendingRequest(fromUid, toUid);
    if (hasPending) {
      throw StateError('A pending friend request already exists.');
    }
    final now = DateTime.now();
    final row = await _local.insertFriendRequest(
      FriendRequestsCompanion.insert(
        remoteId: const Uuid().v4(),
        fromUid: fromUid,
        toUid: toUid,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return _friendRequestFromRow(row);
  }

  @override
  Future<void> respondToFriendRequest({
    required String requestId,
    required FriendRequestStatus response,
  }) {
    return _local.updateRequestStatus(
      remoteId: requestId,
      status: response.name,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelFriendRequest(String requestId) {
    return _local.updateRequestStatus(
      remoteId: requestId,
      status: FriendRequestStatus.cancelled.name,
      updatedAt: DateTime.now(),
    );
  }

  // Challenges

  @override
  Stream<List<Challenge>> watchChallenges(String uid) {
    return _local
        .watchChallenges(uid)
        .map((rows) => rows.map(_challengeFromRow).toList());
  }

  @override
  Future<Challenge?> getChallengeById(String id) async {
    final row = await _local.getChallengeByRemoteId(id);
    return row == null ? null : _challengeFromRow(row);
  }

  @override
  Future<Challenge> createChallenge(Challenge challenge) async {
    if (challenge.opponentUid == challenge.creatorUid) {
      throw ArgumentError('A challenge cannot target its own creator.');
    }
    if (challenge.targetValue <= 0) {
      throw ArgumentError('targetValue must be positive.');
    }
    if (!challenge.endAt.isAfter(challenge.startAt)) {
      throw ArgumentError('endAt must be after startAt.');
    }
    final row = await _local.insertChallenge(
      ChallengesCompanion.insert(
        remoteId: challenge.id,
        creatorUid: challenge.creatorUid,
        opponentUid: Value(challenge.opponentUid),
        metric: challenge.metric.name,
        targetValue: challenge.targetValue,
        period: challenge.period.name,
        startAt: challenge.startAt,
        endAt: challenge.endAt,
        status: Value(challenge.status.name),
        createdAt: challenge.createdAt,
        updatedAt: challenge.updatedAt,
      ),
    );
    return _challengeFromRow(row);
  }

  @override
  Future<void> updateChallengeStatus({
    required String challengeId,
    required ChallengeStatus status,
  }) {
    return _local.updateChallengeStatus(
      remoteId: challengeId,
      status: status.name,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteChallenge(String challengeId) {
    return _local.deleteChallenge(challengeId);
  }

  // Challenge progress

  @override
  Future<List<domain.ChallengeProgress>> getProgressForChallenge(
    String challengeId,
  ) async {
    final challengeRow = await _local.getChallengeByRemoteId(challengeId);
    if (challengeRow == null) return [];
    final rows = await _local.getProgressForChallenge(challengeRow.id);
    return rows.map((r) => _progressFromRow(r, challengeId)).toList();
  }

  @override
  Future<void> upsertProgress(domain.ChallengeProgress progress) async {
    final challengeRow = await _local.getChallengeByRemoteId(
      progress.challengeId,
    );
    if (challengeRow == null) {
      throw ArgumentError('No challenge found for id ${progress.challengeId}');
    }
    await _local.upsertProgress(
      ChallengeProgressCompanion.insert(
        challengeId: challengeRow.id,
        uid: progress.uid,
        currentValue: Value(progress.currentValue),
        targetValue: progress.targetValue,
        lastCalculatedAt: Value(progress.lastCalculatedAt),
        completedAt: Value(progress.completedAt),
      ),
    );
  }

  // Trophies

  @override
  Stream<List<Trophy>> watchTrophies(String uid) {
    return _local
        .watchTrophies(uid)
        .map((rows) => rows.map(_trophyFromRow).toList());
  }

  @override
  Future<Trophy> awardTrophy(Trophy trophy) async {
    final row = await _local.insertTrophy(
      TrophiesCompanion.insert(
        remoteId: trophy.id,
        uid: trophy.uid,
        type: trophy.type.name,
        unlockedAt: trophy.unlockedAt,
        metadataJson: Value(trophy.metadataJson),
      ),
    );
    return _trophyFromRow(row);
  }

  // Row -> entity mapping

  Friend _friendFromRow(FriendRow row) => Friend(
    id: row.remoteId,
    ownerUid: row.ownerUid,
    friendUid: row.friendUid,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  FriendRequest _friendRequestFromRow(FriendRequestRow row) => FriendRequest(
    id: row.remoteId,
    fromUid: row.fromUid,
    toUid: row.toUid,
    status: FriendRequestStatus.fromName(row.status),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Challenge _challengeFromRow(ChallengeRow row) => Challenge(
    id: row.remoteId,
    creatorUid: row.creatorUid,
    opponentUid: row.opponentUid,
    metric: CompetitionMetric.fromName(row.metric),
    targetValue: row.targetValue,
    period: LeaderboardPeriod.fromName(row.period),
    startAt: row.startAt,
    endAt: row.endAt,
    status: ChallengeStatus.fromName(row.status),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  domain.ChallengeProgress _progressFromRow(
    ChallengeProgressRow row,
    String challengeId,
  ) => domain.ChallengeProgress(
    challengeId: challengeId,
    uid: row.uid,
    currentValue: row.currentValue,
    targetValue: row.targetValue,
    lastCalculatedAt: row.lastCalculatedAt,
    completedAt: row.completedAt,
  );

  Trophy _trophyFromRow(TrophyRow row) => Trophy(
    id: row.remoteId,
    uid: row.uid,
    type: TrophyType.fromName(row.type),
    unlockedAt: row.unlockedAt,
    metadataJson: row.metadataJson,
  );
}
