import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart'
    as domain;
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
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

  /// Writes **both** directions.
  ///
  /// The table has documented "one row per direction" since Phase 1 and
  /// the writer only ever wrote one, which left `areFriends` (which
  /// checks both ways) agreeing that two people were friends while
  /// `watchFriends` showed it on one side only. Both rows share the
  /// [remoteId] of the single Firestore document they project from — so
  /// a remote id identifies a *friendship*, not a row.
  @override
  Future<Friend> addFriend({
    required String ownerUid,
    required String friendUid,
    String? remoteId,
  }) async {
    final now = DateTime.now();
    final id = remoteId ?? const Uuid().v4();
    final rows = await _local.insertFriendship(
      remoteId: id,
      ownerUid: ownerUid,
      friendUid: friendUid,
      at: now,
    );
    return _friendFromRow(rows.first);
  }

  /// Removes both directions. Unfriending is mutual — remotely it is one
  /// document, and locally it has to behave the same way or one side
  /// keeps a friend the other has dropped.
  @override
  Future<void> removeFriend({
    required String ownerUid,
    required String friendUid,
  }) {
    return _local.deleteFriendship(uidA: ownerUid, uidB: friendUid);
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
  /// The duplicate guard is direction-agnostic.
  ///
  /// It used to check only `from → to`, so two people could each hold a
  /// pending request to the other and neither would ever see a
  /// friendship — the accept path would produce two half-answers. If
  /// the other person has already asked, the caller is told to accept
  /// theirs rather than creating a crossed pair.
  @override
  Future<FriendRequest> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    if (await _local.hasPendingRequest(toUid, fromUid)) {
      throw StateError('They have already sent you a request — accept it.');
    }
    if (await _local.hasPendingRequest(fromUid, toUid)) {
      throw StateError('A pending friend request already exists.');
    }
    if (await areFriends(fromUid, toUid)) {
      throw StateError('Already friends.');
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

  /// Accepting a request **creates the friendship**.
  ///
  /// It used to flip a status and stop there, so accepting a friend
  /// request made no friend — nothing in the codebase called
  /// `addFriend` in response to anything. The two writes happen in one
  /// transaction, so a request can never be marked accepted without the
  /// friendship it entitles.
  @override
  Future<void> respondToFriendRequest({
    required String requestId,
    required FriendRequestStatus response,
  }) async {
    final request = await _local.getRequestByRemoteId(requestId);
    if (request == null) {
      throw StateError('No such friend request.');
    }
    if (FriendRequestStatus.fromName(request.status) !=
        FriendRequestStatus.pending) {
      // accepted and declined are terminal, matching the rules.
      throw StateError('That request has already been answered.');
    }

    await _local.respondToRequest(
      remoteId: requestId,
      status: response.name,
      at: DateTime.now(),
      // Only an acceptance creates a friendship; a decline is just a
      // decline.
      befriend: response == FriendRequestStatus.accepted
          ? (ownerUid: request.fromUid, friendUid: request.toUid)
          : null,
    );
  }

  /// Only the sender may cancel, and only while it is still pending.
  ///
  /// Neither was checked before: anybody holding the id could cancel,
  /// and an already-accepted request could be "cancelled" out from under
  /// a friendship that already existed.
  @override
  Future<void> cancelFriendRequest(String requestId, {String? byUid}) async {
    final request = await _local.getRequestByRemoteId(requestId);
    if (request == null) {
      throw StateError('No such friend request.');
    }
    if (byUid != null && request.fromUid != byUid) {
      throw StateError('Only the sender can cancel a request.');
    }
    if (FriendRequestStatus.fromName(request.status) !=
        FriendRequestStatus.pending) {
      throw StateError('Only a pending request can be cancelled.');
    }
    await _local.updateRequestStatus(
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
  Future<bool> updateChallengeStatus({
    required String challengeId,
    required ChallengeStatus status,
  }) async {
    final changed = await _local.updateChallengeStatus(
      remoteId: challengeId,
      status: status.name,
      updatedAt: DateTime.now(),
    );
    return changed > 0;
  }

  @override
  Future<void> deleteChallenge(String challengeId) {
    return _local.deleteChallenge(challengeId);
  }

  @override
  Future<List<Challenge>> getActiveChallengesAt({
    required String uid,
    required DateTime at,
  }) async {
    final rows = await _local.getActiveChallengesAt(uid: uid, at: at);
    return rows.map(_challengeFromRow).toList();
  }

  @override
  Future<List<Challenge>> getLapsedActiveChallenges({
    required String uid,
    required DateTime at,
  }) async {
    final rows = await _local.getLapsedActiveChallenges(uid: uid, at: at);
    return rows.map(_challengeFromRow).toList();
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
  Future<domain.ChallengeProgress?> getProgress({
    required String challengeId,
    required String uid,
  }) async {
    final challengeRow = await _local.getChallengeByRemoteId(challengeId);
    if (challengeRow == null) return null;
    final row = await _local.getProgress(
      challengeRowId: challengeRow.id,
      uid: uid,
    );
    return row == null ? null : _progressFromRow(row, challengeId);
  }

  @override
  Future<void> upsertProgressValue(domain.ChallengeProgress progress) async {
    final challengeRow = await _local.getChallengeByRemoteId(
      progress.challengeId,
    );
    if (challengeRow == null) {
      throw ArgumentError('No challenge found for id ${progress.challengeId}');
    }
    await _local.upsertProgressValue(
      challengeRowId: challengeRow.id,
      uid: progress.uid,
      currentValue: progress.currentValue,
      targetValue: progress.targetValue,
      lastCalculatedAt: progress.lastCalculatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> markProgressComplete({
    required String challengeId,
    required String uid,
    required DateTime completedAt,
  }) async {
    final challengeRow = await _local.getChallengeByRemoteId(challengeId);
    if (challengeRow == null) return;
    await _local.markProgressComplete(
      challengeRowId: challengeRow.id,
      uid: uid,
      completedAt: completedAt,
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
  Future<List<Trophy>> getTrophies(String uid) async {
    final rows = await _local.getTrophies(uid);
    return rows.map(_trophyFromRow).toList();
  }

  @override
  Future<Trophy?> awardTrophy(Trophy trophy) async {
    final row = await _local.insertTrophyIfAbsent(
      TrophiesCompanion.insert(
        remoteId: trophy.id,
        uid: trophy.uid,
        type: trophy.type.name,
        unlockedAt: trophy.unlockedAt,
        metadataJson: Value(trophy.metadataJson),
      ),
    );
    // Null means the deterministic id was already present — the user
    // holds this trophy, so this isn't a new unlock.
    return row == null ? null : _trophyFromRow(row);
  }

  // Competition inputs

  @override
  Future<List<CompetitionTrip>> getCompetitionTrips({
    required String uid,
    required CompetitionWindow window,
  }) async {
    final rows = await _local.getTripsWithEligibility(
      uid: uid,
      start: window.start,
      end: window.end,
    );
    return [
      for (final (trip, eligibility) in rows)
        CompetitionTrip(
          tripId: trip.id,
          startedAt: trip.startedAt,
          distanceKm: trip.distanceKm,
          durationSeconds: trip.durationSeconds,
          // No verdict row means the trip predates the competition
          // engine — read as eligible rather than dropping the user's
          // whole history from every leaderboard.
          eligible: eligibility?.eligible ?? true,
          utcOffsetMinutes:
              eligibility?.startedAtUtcOffsetMinutes ??
              trip.startedAt.timeZoneOffset.inMinutes,
        ),
    ];
  }

  @override
  Future<void> recordTripEligibility({
    required int tripId,
    required CompetitionEligibility eligibility,
    required DateTime startedAt,
    String? tripRemoteId,
  }) {
    return _local.upsertTripEligibility(
      TripEligibilityCompanion.insert(
        tripId: Value(tripId),
        tripRemoteId: Value(tripRemoteId),
        eligible: eligibility.eligible,
        failureReasons: Value(
          eligibility.reasons.map((r) => r.name).join(','),
        ),
        mockedSampleCount: Value(eligibility.mockedSampleCount),
        startedAtUtcOffsetMinutes: startedAt.timeZoneOffset.inMinutes,
        evaluatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<CompetitionEligibility?> getTripEligibility(int tripId) async {
    final row = await _local.getTripEligibility(tripId);
    if (row == null) return null;
    return CompetitionEligibility(
      reasons: row.failureReasons
          .split(',')
          .map(EligibilityFailureReason.fromName)
          .whereType<EligibilityFailureReason>()
          .toList(growable: false),
      mockedSampleCount: row.mockedSampleCount,
    );
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
