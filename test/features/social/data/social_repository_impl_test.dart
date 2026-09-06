import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
  });

  tearDown(() async => db.close());

  Challenge challengeFor({
    String creatorUid = 'user-1',
    String? opponentUid,
    double targetValue = 100,
  }) {
    final now = DateTime(2026, 1, 1);
    return Challenge(
      id: const Uuid().v4(),
      creatorUid: creatorUid,
      opponentUid: opponentUid,
      metric: CompetitionMetric.distance,
      targetValue: targetValue,
      period: LeaderboardPeriod.weekly,
      startAt: now,
      endAt: now.add(const Duration(days: 7)),
      status: ChallengeStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('friends', () {
    test('addFriend inserts and getFriends returns it', () async {
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');
      final friends = await repo.getFriends('user-1');
      expect(friends, hasLength(1));
      expect(friends.single.friendUid, 'user-2');
    });

    // This used to assert that a duplicate pair *throws*. Phase 4b
    // changed that deliberately: sync re-inserts every friendship on
    // every pass, so adding one that already exists has to be a no-op
    // rather than an error. "Already friends" is still refused, one
    // level up, by `sendFriendRequest` — which is where a user can
    // actually act on it.
    test('adding the same pair twice is a no-op, not an error, because '
        'sync re-asserts every friendship on every pass', () async {
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');

      expect(await repo.getFriends('user-1'), hasLength(1));
      expect(await repo.getFriends('user-2'), hasLength(1));
    });

    test('a request to someone already a friend is refused at the level '
        'where the user can do something about it', () async {
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');
      await expectLater(
        repo.sendFriendRequest(fromUid: 'user-1', toUid: 'user-2'),
        throwsStateError,
      );
    });

    test('areFriends checks both directions', () async {
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');
      expect(await repo.areFriends('user-1', 'user-2'), isTrue);
      expect(await repo.areFriends('user-2', 'user-1'), isTrue);
      expect(await repo.areFriends('user-1', 'user-3'), isFalse);
    });

    test('removeFriend deletes the row', () async {
      await repo.addFriend(ownerUid: 'user-1', friendUid: 'user-2');
      await repo.removeFriend(ownerUid: 'user-1', friendUid: 'user-2');
      expect(await repo.getFriends('user-1'), isEmpty);
    });
  });

  group('friend requests', () {
    test('sendFriendRequest creates a pending request', () async {
      final request = await repo.sendFriendRequest(
        fromUid: 'user-1',
        toUid: 'user-2',
      );
      expect(request.status, FriendRequestStatus.pending);
      final outgoing = await repo.getOutgoingRequests('user-1');
      expect(outgoing, hasLength(1));
    });

    test('sendFriendRequest throws when a pending request already exists', () async {
      await repo.sendFriendRequest(fromUid: 'user-1', toUid: 'user-2');
      await expectLater(
        repo.sendFriendRequest(fromUid: 'user-1', toUid: 'user-2'),
        throwsA(anything),
      );
    });

    test('respondToFriendRequest updates status', () async {
      final request = await repo.sendFriendRequest(
        fromUid: 'user-1',
        toUid: 'user-2',
      );
      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.accepted,
      );
      final outgoing = await repo.getOutgoingRequests('user-1');
      expect(outgoing.single.status, FriendRequestStatus.accepted);
    });
  });

  group('challenges', () {
    test('createChallenge round-trips a head-to-head challenge', () async {
      final created = await repo.createChallenge(
        challengeFor(opponentUid: 'user-2'),
      );
      expect(created.isPersonal, isFalse);
      final fetched = await repo.getChallengeById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.opponentUid, 'user-2');
    });

    test('createChallenge round-trips a personal target (opponentUid null)', () async {
      final created = await repo.createChallenge(challengeFor());
      expect(created.isPersonal, isTrue);
      final fetched = await repo.getChallengeById(created.id);
      expect(fetched!.opponentUid, isNull);
    });

    test('createChallenge rejects a self-challenge', () async {
      await expectLater(
        repo.createChallenge(
          challengeFor(creatorUid: 'user-1', opponentUid: 'user-1'),
        ),
        throwsArgumentError,
      );
    });

    test('createChallenge rejects a non-positive target', () async {
      await expectLater(
        repo.createChallenge(challengeFor(targetValue: 0)),
        throwsArgumentError,
      );
    });

    test('updateChallengeStatus persists the new status', () async {
      final created = await repo.createChallenge(challengeFor());
      await repo.updateChallengeStatus(
        challengeId: created.id,
        status: ChallengeStatus.active,
      );
      final fetched = await repo.getChallengeById(created.id);
      expect(fetched!.status, ChallengeStatus.active);
    });

    test('deleteChallenge cascades to challenge_progress', () async {
      final created = await repo.createChallenge(challengeFor());
      await repo.upsertProgressValue(
        ChallengeProgress(
          challengeId: created.id,
          uid: 'user-1',
          currentValue: 10,
          targetValue: 100,
        ),
      );
      expect(await repo.getProgressForChallenge(created.id), hasLength(1));
      await repo.deleteChallenge(created.id);
      expect(await repo.getProgressForChallenge(created.id), isEmpty);
    });
  });

  group('challenge progress', () {
    test('upsertProgressValue on the same (challengeId, uid) updates, '
        'not duplicates', () async {
      final created = await repo.createChallenge(challengeFor());
      await repo.upsertProgressValue(
        ChallengeProgress(
          challengeId: created.id,
          uid: 'user-1',
          currentValue: 10,
          targetValue: 100,
        ),
      );
      await repo.upsertProgressValue(
        ChallengeProgress(
          challengeId: created.id,
          uid: 'user-1',
          currentValue: 42,
          targetValue: 100,
        ),
      );
      final progress = await repo.getProgressForChallenge(created.id);
      expect(progress, hasLength(1));
      expect(progress.single.currentValue, 42);
    });
  });

  group('trophies', () {
    Trophy trophyFor({String id = 'roadWarrior:user-1:2026-W01'}) => Trophy(
      id: id,
      uid: 'user-1',
      type: TrophyType.roadWarrior,
      unlockedAt: DateTime(2026, 1, 1),
    );

    test('awardTrophy inserts and watchTrophies emits it', () async {
      final awarded = await repo.awardTrophy(trophyFor());
      expect(awarded, isNotNull);
      final trophies = await repo.watchTrophies('user-1').first;
      expect(trophies, hasLength(1));
      expect(trophies.single.type, TrophyType.roadWarrior);
    });

    test('awarding the same deterministic id twice is a no-op and returns '
        'null the second time — this is what keeps two trips saved '
        'back-to-back from double-awarding, since both would pass a '
        'read-then-insert check', () async {
      expect(await repo.awardTrophy(trophyFor()), isNotNull);
      expect(await repo.awardTrophy(trophyFor()), isNull);
      expect(await repo.getTrophies('user-1'), hasLength(1));
    });

    test('a different period key is a separate trophy', () async {
      await repo.awardTrophy(trophyFor());
      await repo.awardTrophy(trophyFor(id: 'roadWarrior:user-1:2026-W02'));
      expect(await repo.getTrophies('user-1'), hasLength(2));
    });
  });
}
