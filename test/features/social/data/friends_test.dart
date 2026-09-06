import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/data/services/friends_sync_service.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/invite_code.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

/// An in-memory stand-in for the shared collections.
class _FakeDirectory implements SocialDirectory {
  final Map<String, RemoteFriendship> friendships = {};
  final Map<String, FriendRequest> requests = {};
  final Map<String, String> usernames = {};
  final Map<String, CompetitionMirror> profiles = {};
  int createFriendshipCalls = 0;

  @override
  Future<CompetitionMirror?> profileFor(String uid) async => profiles[uid];

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
    createFriendshipCalls += 1;
    final key = friendshipKey(a, b);
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
  }

  @override
  Future<List<RemoteFriendship>> friendshipsFor(String uid) async =>
      friendships.values.where((f) => f.uids.contains(uid)).toList();
}

void main() {
  late AppDatabase db;
  late SocialLocalDataSource local;
  late SocialRepositoryImpl repo;
  late UserSettingsRepository settings;
  late _FakeDirectory directory;
  late FriendsSyncService sync;

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

    test('publishes nothing under a placeholder uid', () async {
      await db
          .update(db.userSettings)
          .write(const UserSettingsCompanion(uid: Value('local')));
      await directory.createFriendship(a: 'local', b: bob);

      await sync.syncNow();

      expect(await db.select(db.friends).get(), isEmpty);
    });
  });
}
