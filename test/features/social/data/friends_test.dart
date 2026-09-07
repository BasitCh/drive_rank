import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/data/services/competition_mirror_sink.dart';
import 'package:drive_rank/features/social/data/services/competition_value_publisher.dart';
import 'package:drive_rank/features/social/data/services/friends_sync_service.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/invite_code.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

/// Records what would have been published.
class _RecordingSink implements CompetitionMirrorSink {
  final List<CompetitionMirror> written = [];

  @override
  Future<void> write(CompetitionMirror mirror) async => written.add(mirror);
}

/// An in-memory stand-in for the shared collections.
class _FakeDirectory implements SocialDirectory {
  /// Makes every write throw the way a rules refusal does.
  bool failWrites = false;

  final Map<String, RemoteFriendship> friendships = {};
  final Map<String, FriendRequest> requests = {};
  final Map<String, String> usernames = {};
  final Map<String, CompetitionMirror> profiles = {};
  int createFriendshipCalls = 0;

  @override
  Future<CompetitionMirror?> profileFor(String uid) async => profiles[uid];

  @override
  Stream<List<CompetitionMirror>> watchProfiles(List<String> uids) =>
      Stream.value([
        for (final uid in uids)
          if (profiles[uid] != null) profiles[uid]!,
      ]);

  @override
  Future<String?> uidForUsername(String username) async =>
      usernames[username.toLowerCase()];

  @override
  Future<String?> uidForInviteCode(String code) async {
    for (final entry in profiles.entries) {
      if (entry.value.inviteCode == code) return entry.key;
    }
    return null;
  }

  @override
  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    if (failWrites) throw StateError('permission-denied');
    final id = friendRequestKey(fromUid: fromUid, toUid: toUid);
    requests[id] = FriendRequest(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      status: FriendRequestStatus.pending,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> respondToRequest({
    required String fromUid,
    required String toUid,
    required FriendRequestStatus response,
  }) async {
    if (failWrites) throw StateError('permission-denied');
    final id = friendRequestKey(fromUid: fromUid, toUid: toUid);
    final existing = requests[id]!;
    requests[id] = FriendRequest(
      id: id,
      fromUid: existing.fromUid,
      toUid: existing.toUid,
      status: response,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 2),
    );
  }

  @override
  Future<void> cancelRequest({
    required String fromUid,
    required String toUid,
  }) => respondToRequest(
    fromUid: fromUid,
    toUid: toUid,
    response: FriendRequestStatus.cancelled,
  );

  @override
  Future<List<FriendRequest>> requestsFor(String uid) async => requests.values
      .where((r) => r.fromUid == uid || r.toUid == uid)
      .toList();

  @override
  Future<void> createFriendship({
    required String a,
    required String b,
  }) async {
    if (failWrites) throw StateError('permission-denied');
    final key = friendshipKey(a, b);
    // Mirrors `allow update: if false` on friendships. Writing an
    // existing friendship document is an update, and the rules refuse
    // it — so a fake that quietly accepted the second write hid a
    // permission-denied that reached a real device's Crashlytics on
    // every acceptance.
    if (friendships.containsKey(key)) {
      throw StateError('permission-denied: friendships are immutable');
    }
    createFriendshipCalls += 1;
    friendships[key] = RemoteFriendship(
      pairKey: key,
      uids: [a, b]..sort(),
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> deleteFriendship({
    required String a,
    required String b,
  }) async {
    friendships.remove(friendshipKey(a, b));
    // Mirrors the real batch: an unfriend ends the accepted requests
    // behind it, or the healing pass would recreate the friendship.
    for (final (from, to) in [(a, b), (b, a)]) {
      final id = friendRequestKey(fromUid: from, toUid: to);
      final existing = requests[id];
      if (existing?.status == FriendRequestStatus.accepted) {
        requests[id] = FriendRequest(
          id: id,
          fromUid: existing!.fromUid,
          toUid: existing.toUid,
          status: FriendRequestStatus.ended,
          createdAt: existing.createdAt,
          updatedAt: DateTime(2026, 3),
        );
      }
    }
  }

  @override
  Future<List<RemoteFriendship>> friendshipsFor(String uid) async =>
      friendships.values.where((f) => f.uids.contains(uid)).toList();

  /// Broadcast so a test can push a change the way Firestore would.
  final friendshipEvents =
      StreamController<List<RemoteFriendship>>.broadcast();
  final requestEvents = StreamController<List<FriendRequest>>.broadcast();
  final sentEvents = StreamController<List<FriendRequest>>.broadcast();

  @override
  Stream<List<RemoteFriendship>> watchFriendships(String uid) =>
      friendshipEvents.stream;

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) =>
      requestEvents.stream;

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid) =>
      sentEvents.stream;

  /// Only the request streams fire — no friendship snapshot.
  ///
  /// This is the shape of a real acceptance arriving: the request
  /// listener wakes on its own, and `_syncRequests` runs without the
  /// friendships pass that `syncNow` would have done first. Every bug
  /// in the healing branch hides behind that pass.
  void notifyRequestsOnly() {
    requestEvents.add(requests.values.toList());
    sentEvents.add(requests.values.toList());
  }

  // Challenges are not what this suite is about; the challenge suite
  // has its own fake. These exist so the class stays concrete.
  @override
  Future<void> createChallenge(Challenge challenge) async {}

  @override
  Future<void> respondToChallenge({
    required String challengeId,
    required ChallengeStatus response,
  }) async {}

  @override
  Future<List<Challenge>> challengesFor(String uid) async => const [];

  @override
  Stream<List<Challenge>> watchChallenges(String uid) =>
      Stream.value(const []);

  @override
  Future<void> publishProgress({
    required String challengeId,
    required String uid,
    required double value,
  }) async {}

  @override
  Stream<Map<String, double>> watchProgress(String challengeId) =>
      Stream.value(const {});

  /// Mimics a remote change arriving: mutate, then notify.
  void notify() {
    friendshipEvents.add(friendships.values.toList());
    requestEvents.add(requests.values.toList());
    sentEvents.add(requests.values.toList());
  }
}

void main() {
  late AppDatabase db;
  late SocialLocalDataSource local;
  late SocialRepositoryImpl repo;
  late UserSettingsRepository settings;
  late _FakeDirectory directory;
  late FriendsSyncService sync;
  late _RecordingSink sink;

  const alice = 'alice-uid';
  const bob = 'bob-uid';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = SocialLocalDataSource(db);
    repo = SocialRepositoryImpl(local);
    settings = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'DE')),
      _MockFreeTripCounterService(),
    );
    directory = _FakeDirectory();
    sink = _RecordingSink();
    sync = FriendsSyncService(local, settings);
    getIt.registerSingleton<SocialDirectory>(directory);
    await settings.syncUid(alice);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  group('invite codes', () {
    test('are stable for an account and differ between accounts', () {
      expect(inviteCodeFor(alice), inviteCodeFor(alice));
      expect(inviteCodeFor(alice), isNot(inviteCodeFor(bob)));
      expect(inviteCodeFor(alice), hasLength(8));
    });

    test('avoid the characters people misread aloud, because a code gets '
        'read off one screen and typed into another', () {
      final code = inviteCodeFor(alice);
      expect(code, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]+$')));
      expect(code, isNot(contains('I')));
      expect(code, isNot(contains('O')));
    });

    test('normalising accepts what a human actually types', () {
      expect(normaliseInviteCode(' ab-cd 12 '), 'ABCD12');
      // The excluded letters map to what the writer meant: I and L read
      // as 1, O as 0.
      expect(normaliseInviteCode('I0LO'), '1010');
      expect(normaliseInviteCode('u'), 'V');
    });

    test('an empty uid has no code rather than a misleading one', () {
      expect(inviteCodeFor(''), isEmpty);
    });
  });

  group('adding a friend', () {
    test('creates both directions, so the friendship shows on both sides '
        '— it used to appear for the owner only', () async {
      await repo.addFriend(ownerUid: alice, friendUid: bob);

      expect(await repo.getFriends(alice), hasLength(1));
      expect(await repo.getFriends(bob), hasLength(1));
      expect(await repo.areFriends(alice, bob), isTrue);
    });

    test('both rows share the remote id of the one document they came '
        'from — a remote id names a friendship, not a row', () async {
      await repo.addFriend(
        ownerUid: alice,
        friendUid: bob,
        remoteId: 'pair-key',
      );

      final mine = await repo.getFriends(alice);
      final theirs = await repo.getFriends(bob);
      expect(mine.single.id, 'pair-key');
      expect(theirs.single.id, 'pair-key');
    });

    test('is idempotent — adding twice leaves two rows, not four', () async {
      await repo.addFriend(ownerUid: alice, friendUid: bob);
      await repo.addFriend(ownerUid: alice, friendUid: bob);

      expect(await repo.getFriends(alice), hasLength(1));
      expect(await repo.getFriends(bob), hasLength(1));
    });

    test('removing clears both sides, because unfriending is mutual',
        () async {
      await repo.addFriend(ownerUid: alice, friendUid: bob);
      await repo.removeFriend(ownerUid: alice, friendUid: bob);

      expect(await repo.getFriends(alice), isEmpty);
      expect(await repo.getFriends(bob), isEmpty);
      expect(await repo.areFriends(alice, bob), isFalse);
    });
  });

  group('friend requests', () {
    test('accepting actually creates the friendship — it used to flip a '
        'status and make no friend at all', () async {
      final request = await repo.sendFriendRequest(
        fromUid: alice,
        toUid: bob,
      );

      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.accepted,
      );

      expect(await repo.areFriends(alice, bob), isTrue);
      expect(await repo.getFriends(alice), hasLength(1));
      expect(await repo.getFriends(bob), hasLength(1));
    });

    test('declining makes no friendship', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);

      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.declined,
      );

      expect(await repo.areFriends(alice, bob), isFalse);
    });

    test('answering an already-answered request is refused — accepted and '
        'declined are terminal, matching the rules', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.declined,
      );

      expect(
        () => repo.respondToFriendRequest(
          requestId: request.id,
          response: FriendRequestStatus.accepted,
        ),
        throwsStateError,
      );
    });

    test('a crossed request is refused, so two people cannot each hold a '
        'pending request the other never sees resolved', () async {
      await repo.sendFriendRequest(fromUid: bob, toUid: alice);

      expect(
        () => repo.sendFriendRequest(fromUid: alice, toUid: bob),
        throwsStateError,
      );
    });

    test('asking someone who is already a friend is refused', () async {
      await repo.addFriend(ownerUid: alice, friendUid: bob);

      expect(
        () => repo.sendFriendRequest(fromUid: alice, toUid: bob),
        throwsStateError,
      );
    });

    test('only the sender can cancel', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);

      expect(
        () => repo.cancelFriendRequest(request.id, byUid: bob),
        throwsStateError,
      );
      await repo.cancelFriendRequest(request.id, byUid: alice);
    });

    test('withdrawing and then asking again works — the local row that '
        'a withdrawal leaves behind used to make the second request to '
        'anyone you had ever withdrawn fail forever on the unique '
        'remote id', () async {
      final first = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.cancelFriendRequest(first.id, byUid: alice);

      final second = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      expect(second.status, FriendRequestStatus.pending);
      // The same request resumed, at the same derived id — not a
      // second one, which is what the id being derived guarantees.
      expect(second.id, first.id);

      final outgoing = await repo.getOutgoingRequests(alice);
      expect(outgoing, hasLength(1));
      expect(outgoing.single.status, FriendRequestStatus.pending);
    });

    test('a withdrawn request stops blocking, and stops counting as '
        'outstanding', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.cancelFriendRequest(request.id, byUid: alice);

      final outgoing = await repo.getOutgoingRequests(alice);
      expect(outgoing.single.status, FriendRequestStatus.cancelled);
    });

    test('two people who unfriended can become friends again — an ended '
        'request is re-opened rather than replaced, because a request '
        'id is derived from the pair and there is nowhere else for a '
        'fresh one to live', () async {
      final first = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.respondToFriendRequest(
        requestId: first.id,
        response: FriendRequestStatus.accepted,
      );
      expect(await repo.areFriends(alice, bob), isTrue);

      await repo.removeFriend(ownerUid: alice, friendUid: bob);
      await directory.deleteFriendship(a: alice, b: bob);
      expect(await repo.areFriends(alice, bob), isFalse);

      final again = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      expect(again.id, first.id);
      expect(again.status, FriendRequestStatus.pending);

      // …and it can be accepted, all the way back to a friendship.
      await repo.respondToFriendRequest(
        requestId: again.id,
        response: FriendRequestStatus.accepted,
      );
      expect(await repo.areFriends(alice, bob), isTrue);
    });

    test('re-sending never adds a second row for the same pair — the '
        'remote id is the address of one logical request', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      final request = await repo.getOutgoingRequests(alice);
      await repo.cancelFriendRequest(request.single.id, byUid: alice);
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);

      expect(await repo.getOutgoingRequests(alice), hasLength(1));
    });

    test('an answered request cannot then be cancelled out from under the '
        'friendship it created', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.accepted,
      );

      expect(
        () => repo.cancelFriendRequest(request.id, byUid: alice),
        throwsStateError,
      );
      expect(await repo.areFriends(alice, bob), isTrue);
    });
  });

  group('syncing from the cloud', () {
    test('projects one remote friendship into two local rows', () async {
      await directory.createFriendship(a: alice, b: bob);

      await sync.syncNow();

      expect(await repo.getFriends(alice), hasLength(1));
      expect(
        (await repo.getFriends(alice)).single.id,
        friendshipKey(alice, bob),
      );
    });

    test('running it twice changes nothing — it reconciles rather than '
        'appends', () async {
      await directory.createFriendship(a: alice, b: bob);

      await sync.syncNow();
      final first = await db.select(db.friends).get();
      await sync.syncNow();
      await sync.syncNow();
      final third = await db.select(db.friends).get();

      expect(third.length, first.length);
      expect(
        third.map((r) => (r.ownerUid, r.friendUid, r.remoteId)),
        first.map((r) => (r.ownerUid, r.friendUid, r.remoteId)),
      );
    });

    test('a friendship deleted elsewhere disappears here — otherwise '
        'being unfriended would be invisible on this device', () async {
      await directory.createFriendship(a: alice, b: bob);
      await sync.syncNow();
      expect(await repo.getFriends(alice), hasLength(1));

      await directory.deleteFriendship(a: alice, b: bob);
      await sync.syncNow();

      expect(await repo.getFriends(alice), isEmpty);
    });

    test('an accepted request with no friendship is completed — accepting '
        'is two writes and nothing guarantees the second one landed',
        () async {
      await directory.sendRequest(fromUid: bob, toUid: alice);
      await directory.respondToRequest(
        fromUid: bob,
        toUid: alice,
        response: FriendRequestStatus.accepted,
      );
      expect(directory.friendships, isEmpty);

      await sync.syncNow();

      expect(directory.friendships, hasLength(1));
      expect(await repo.areFriends(alice, bob), isTrue);
    });

    test('does not re-create a friendship that already exists, so the '
        'self-healing pass is not a write amplifier', () async {
      await directory.sendRequest(fromUid: bob, toUid: alice);
      await directory.respondToRequest(
        fromUid: bob,
        toUid: alice,
        response: FriendRequestStatus.accepted,
      );

      await sync.syncNow();
      final callsAfterFirst = directory.createFriendshipCalls;
      await sync.syncNow();

      expect(directory.createFriendshipCalls, callsAfterFirst);
    });


    test('an unfriend is not undone by the self-healing pass — the '
        'two-account walkthrough caught this resurrecting a friendship '
        'somebody had deliberately ended', () async {
      // The full shape: a request accepted, a friendship, then an
      // unfriend, then a device syncing from nothing.
      await directory.sendRequest(fromUid: bob, toUid: alice);
      await directory.respondToRequest(
        fromUid: bob,
        toUid: alice,
        response: FriendRequestStatus.accepted,
      );
      await sync.syncNow();
      expect(await repo.areFriends(alice, bob), isTrue);

      await repo.removeFriend(ownerUid: alice, friendUid: bob);
      await directory.deleteFriendship(a: alice, b: bob);

      // The wipe-and-rebuild the walkthrough used: whatever comes back
      // can only have come from the cloud.
      await db.delete(db.friends).go();
      await sync.syncNow();
      await sync.syncNow();

      expect(
        await repo.areFriends(alice, bob),
        isFalse,
        reason: 'healing must not revive an ended friendship',
      );
      expect(directory.friendships, isEmpty);
    });

    test('ending the request is what distinguishes the two cases — a '
        'genuinely dropped friendship write still heals', () async {
      await directory.sendRequest(fromUid: bob, toUid: alice);
      await directory.respondToRequest(
        fromUid: bob,
        toUid: alice,
        response: FriendRequestStatus.accepted,
      );
      // Accepted, and no friendship: the write that never landed.
      expect(directory.friendships, isEmpty);

      await sync.syncNow();

      expect(await repo.areFriends(alice, bob), isTrue);
    });


    test('the healing pass does not rewrite a friendship that already '
        'exists remotely — the usual reason it runs is the other person '
        'having just accepted, so the document is already there and '
        'writing it again is an update the rules refuse. That refusal '
        'went to Crashlytics on every single acceptance', () async {
      await sync.start();
      addTearDown(sync.stop);

      await directory.sendRequest(fromUid: bob, toUid: alice);
      await directory.respondToRequest(
        fromUid: bob,
        toUid: alice,
        response: FriendRequestStatus.accepted,
      );
      // Bob's device created it; this device has no local row yet.
      await directory.createFriendship(a: bob, b: alice);
      final callsBefore = directory.createFriendshipCalls;
      expect(await repo.areFriends(alice, bob), isFalse);

      // The request listener alone, which is how this actually
      // happens: `syncNow` reconciles friendships first and would mask
      // the whole branch.
      directory.notifyRequestsOnly();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Projected locally, and not written again.
      expect(await repo.areFriends(alice, bob), isTrue);
      expect(directory.createFriendshipCalls, callsBefore);
    });

    test('a friendship created on another device lands here without '
        'anything asking — the bug was that the cloud was only read '
        'when the page was constructed', () async {
      await sync.start();
      addTearDown(sync.stop);

      // Somebody else's device acts.
      await directory.createFriendship(a: alice, b: bob);
      directory.notify();
      // Let the listener's reconcile run.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await repo.areFriends(alice, bob), isTrue);
    });

    test('an unfriend elsewhere also lands live', () async {
      await directory.createFriendship(a: alice, b: bob);
      await sync.syncNow();
      expect(await repo.areFriends(alice, bob), isTrue);

      await sync.start();
      addTearDown(sync.stop);
      await directory.deleteFriendship(a: alice, b: bob);
      directory.notify();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await repo.areFriends(alice, bob), isFalse);
    });

    test('starting twice replaces the listeners rather than stacking a '
        'second pair', () async {
      await sync.start();
      await sync.start();
      addTearDown(sync.stop);

      await directory.createFriendship(a: alice, b: bob);
      directory.notify();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // One friendship, one pair of local rows — a stacked listener
      // would reconcile twice, which is harmless here only because the
      // reconcile is idempotent. Asserted so it stays that way.
      expect(await db.select(db.friends).get(), hasLength(2));
    });

    test('never listens under a placeholder uid', () async {
      await db
          .update(db.userSettings)
          .write(const UserSettingsCompanion(uid: Value('pending')));

      await sync.start();
      addTearDown(sync.stop);
      await directory.createFriendship(a: 'pending', b: bob);
      directory.notify();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await db.select(db.friends).get(), isEmpty);
    });


    test('a sent request has the derived id, so the copy sync pulls back '
        'is the same row rather than a second one', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      expect(
        request.id,
        friendRequestKey(fromUid: alice, toUid: bob),
        reason: 'a locally-minted UUID left the request in the table twice',
      );

      await directory.sendRequest(fromUid: alice, toUid: bob);
      await sync.syncNow();

      final rows = await db.select(db.friendRequests).get();
      expect(rows, hasLength(1));
    });

    test('a phantom request row is cleared by a sync — this is the state '
        'real device data was found in, and it blocked every future '
        'request to that person', () async {
      // A row under a random id, exactly as the old code wrote it.
      await local.upsertFriendRequest(
        remoteId: 'a-random-uuid',
        fromUid: alice,
        toUid: bob,
        status: 'pending',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(await db.select(db.friendRequests).get(), hasLength(1));

      // The cloud has no such request.
      await sync.syncNow();

      expect(await db.select(db.friendRequests).get(), isEmpty);
      // And the pair is askable again, rather than permanently refused.
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
    });

    test('a request answered remotely updates in place rather than '
        'duplicating', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await directory.sendRequest(fromUid: alice, toUid: bob);
      await directory.respondToRequest(
        fromUid: alice,
        toUid: bob,
        response: FriendRequestStatus.accepted,
      );

      await sync.syncNow();

      final rows = await db.select(db.friendRequests).get();
      expect(rows, hasLength(1));
      expect(rows.single.status, FriendRequestStatus.accepted.name);
    });

    test('publishes nothing before there is a username — a nameless '
        'public profile renders as a raw uid to whoever finds it',
        () async {
      final publisher = CompetitionValuePublisher(
        settings,
        repo,
        const DefaultCompetitionMetricCalculator(),
      );
      getIt.registerSingleton<CompetitionMirrorSink>(sink);

      await settings.patch(const UserSettingsCompanion(username: Value('')));
      await publisher.publishNow();
      expect(sink.written, isEmpty);

      await settings.patch(
        const UserSettingsCompanion(username: Value('basit')),
      );
      await publisher.publishNow();
      expect(sink.written, hasLength(1));
      expect(sink.written.single.username, 'basit');
    });

    test('publishes nothing under a placeholder uid', () async {
      await db
          .update(db.userSettings)
          .write(const UserSettingsCompanion(uid: Value('local')));
      await directory.createFriendship(a: 'local', b: bob);

      await sync.syncNow();

      expect(await db.select(db.friends).get(), isEmpty);
    });
  });

  group('looking somebody up', () {
    late FriendsBloc bloc;

    setUp(() {
      bloc = FriendsBloc(settings, repo, directory, sync);
      directory.profiles[bob] = CompetitionMirror(
        uid: bob,
        username: 'bob',
        carMake: 'BMW',
        carModel: 'M3',
        countryCode: 'PK',
        inviteCode: inviteCodeFor(bob),
        totals: const {},
      );
    });

    tearDown(() async {
      await bloc.close();
      // `FriendsStarted` is still inside `_sync.start()` at this point
      // in the shorter tests, and that resolves the directory from
      // getIt — which the outer teardown is about to unregister. Let
      // the start-up finish first.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    Future<FriendsState> lookUpBob() async {
      bloc.add(const FriendsStarted());
      await bloc.stream.firstWhere((s) => s.uid == alice);
      bloc.add(FriendsLookupRequested(inviteCodeFor(bob), byCode: true));
      return bloc.stream.firstWhere(
        (s) => s.lookupStatus != LookupStatus.searching &&
            s.lookupStatus != LookupStatus.idle,
      );
    }

    test('a stranger is offered', () async {
      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.found);
      expect(state.lookupResult?.uid, bob);
    });

    test('somebody the viewer already asked comes back as asked, not as '
        'offered — the sheet used to show a live Add here and the send '
        'path then refused it, which is how a sent request became an '
        'invisible dead end', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.requestSent);
      expect(state.lookupResult?.uid, bob);
    });

    test('a withdrawn request stops being outstanding, so they can be '
        'asked again', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.cancelFriendRequest(request.id, byUid: alice);

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.found);
    });

    test('a declined request is not outstanding, and not askable again '
        'either — it reads as "they can add you" rather than offering a '
        'button the cloud would refuse', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.declined,
      );

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.theyMustAsk);
      expect(state.outgoing, isEmpty);
    });

    test('withdrawing clears it both locally and remotely, and leaves a '
        'person who can be asked again', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await directory.sendRequest(fromUid: alice, toUid: bob);

      final asked = await lookUpBob();
      expect(asked.lookupStatus, LookupStatus.requestSent);

      bloc.add(const FriendsRequestCancelled(bob));
      final withdrawn = await bloc.stream.firstWhere(
        (s) => s.lookupStatus == LookupStatus.found,
      );
      expect(withdrawn.error, isNull);
      expect(withdrawn.sentTo, isNot(contains(bob)));

      final local = await repo.getOutgoingRequests(alice);
      expect(local.single.status, FriendRequestStatus.cancelled);
      final remote = directory.requests[
        friendRequestKey(fromUid: alice, toUid: bob)
      ];
      expect(remote?.status, FriendRequestStatus.cancelled);
    });

    test('when they asked first, the viewer is told to answer theirs '
        'rather than offered a crossing request', () async {
      await repo.sendFriendRequest(fromUid: bob, toUid: alice);

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.requestReceived);
    });

    test('an accepted request leaves the sent list on its own, without a '
        'pull-to-refresh — only incoming requests were watched, so the '
        'sender never learned their own request had been answered and '
        'watched it sit there', () async {
      await lookUpBob();
      bloc.add(const FriendsRequestSent(bob));
      await bloc.stream.firstWhere((s) => s.outgoing.isNotEmpty);

      // Bob accepts on his own device: the request turns accepted and
      // the friendship appears, both remotely.
      await directory.respondToRequest(
        fromUid: alice,
        toUid: bob,
        response: FriendRequestStatus.accepted,
      );
      await directory.createFriendship(a: alice, b: bob);
      directory.notify();

      final settled = await bloc.stream.firstWhere(
        (s) => s.outgoing.isEmpty && s.friends.isNotEmpty,
      );
      expect(settled.friends.single.friendUid, bob);
      expect(settled.outgoing, isEmpty);
    });

    test('somebody who is already a friend is never listed as awaiting a '
        'reply, whatever a lagging request status says', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.addFriend(ownerUid: alice, friendUid: bob);

      bloc.add(const FriendsStarted());
      final state = await bloc.stream.firstWhere((s) => s.friends.isNotEmpty);
      expect(state.outgoing, isEmpty);
    });

    test('somebody who declined and never befriended them cannot be '
        'asked, and the sheet says who can do what instead of offering '
        'a button whose write the cloud refuses', () async {
      final request = await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await repo.respondToFriendRequest(
        requestId: request.id,
        response: FriendRequestStatus.declined,
      );

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.theyMustAsk);
    });

    test('a decline the two of them have since overtaken by being '
        'friends is not binding — the friendship superseded the no, and '
        'the same condition gates it in the rules', () async {
      final declined = await repo.sendFriendRequest(
        fromUid: alice,
        toUid: bob,
      );
      await repo.respondToFriendRequest(
        requestId: declined.id,
        response: FriendRequestStatus.declined,
      );

      // The other direction: bob asked, alice accepted, then unfriended.
      final theirs = await repo.sendFriendRequest(fromUid: bob, toUid: alice);
      await repo.respondToFriendRequest(
        requestId: theirs.id,
        response: FriendRequestStatus.accepted,
      );
      await repo.removeFriend(ownerUid: alice, friendUid: bob);
      await local.updateRequestStatus(
        remoteId: theirs.id,
        status: FriendRequestStatus.ended.name,
        updatedAt: DateTime(2026, 2),
      );

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.found);
    });

    test('an existing friend still reads as a friend', () async {
      await repo.addFriend(ownerUid: alice, friendUid: bob);

      final state = await lookUpBob();
      expect(state.lookupStatus, LookupStatus.alreadyFriend);
    });

    test('a sent request appears on the page, which is the only place '
        'the sender can see or withdraw it', () async {
      final found = await lookUpBob();
      expect(found.outgoing, isEmpty);

      bloc.add(const FriendsRequestSent(bob));
      final sent = await bloc.stream.firstWhere(
        (s) => s.outgoing.isNotEmpty,
      );

      expect(sent.outgoing.single.toUid, bob);
      expect(sent.outgoing.single.status, FriendRequestStatus.pending);
      // Named, not shown as a raw uid: the page fetches the profile of
      // whoever is on the other side of a request, like a friend's.
      expect(sent.friendProfiles[bob]?.username, 'bob');
    });

    test('withdrawing it takes it off the page', () async {
      await lookUpBob();
      bloc.add(const FriendsRequestSent(bob));
      await bloc.stream.firstWhere((s) => s.outgoing.isNotEmpty);

      bloc.add(const FriendsRequestCancelled(bob));
      final gone = await bloc.stream.firstWhere((s) => s.outgoing.isEmpty);
      expect(gone.error, isNull);
    });

    test('a remote write that fails takes the local row with it — a '
        'local pending with nothing behind it is invisible to the person '
        'it was addressed to, blocks every later attempt to ask them, '
        'and cannot be withdrawn because there is no remote document to '
        'withdraw. A real device was found in exactly that state',
        () async {
      await lookUpBob();
      directory.failWrites = true;

      bloc.add(const FriendsRequestSent(bob));
      final failed = await bloc.stream.firstWhere((s) => s.error != null);
      expect(failed.error, AppStrings.friendsSendFailed);

      // Nothing left pending, so asking again is possible.
      final local = await repo.getOutgoingRequests(alice);
      expect(
        local.where((r) => r.status == FriendRequestStatus.pending),
        isEmpty,
      );
      directory.failWrites = false;
      expect(
        () => repo.sendFriendRequest(fromUid: alice, toUid: bob),
        returnsNormally,
      );
    });

    test('a withdrawal the cloud refuses still clears locally, rather '
        'than reporting a failure over a row that was in fact '
        'withdrawn — the refusal reported on a real device left the '
        'withdrawal looking broken when it had worked', () async {
      await repo.sendFriendRequest(fromUid: alice, toUid: bob);
      await directory.sendRequest(fromUid: alice, toUid: bob);
      final asked = await lookUpBob();
      expect(asked.lookupStatus, LookupStatus.requestSent);

      directory.failWrites = true;
      bloc.add(const FriendsRequestCancelled(bob));
      final cleared = await bloc.stream.firstWhere(
        (s) => s.lookupStatus == LookupStatus.found,
      );

      expect(cleared.error, isNull);
      final local = await repo.getOutgoingRequests(alice);
      expect(local.single.status, FriendRequestStatus.cancelled);
    });
  });
}
