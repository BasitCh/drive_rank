import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/shared/models/friend_models.dart';
import 'package:drive_rank/shared/repositories/firestore_leaderboard_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Outcome of sending or actioning a friend request.
enum FriendOperationResult { ok, alreadyExists, notFound, failed }

/// All friend-system data access. The leaderboard's Friends tab gets its
/// UIDs from this repository via [FriendUidsSource], so the leaderboard
/// stays decoupled from the friends feature internals.
abstract class FriendsRepository implements FriendUidsSource {
  /// Username-prefix search against the public `/users` collection.
  /// Empty / <3-char queries short-circuit to an empty list.
  Future<List<FriendSearchResult>> searchByUsernamePrefix({
    required String prefix,
    required String myUid,
  });

  /// Send a friend request. Returns `alreadyExists` if the same
  /// (from, to) request is already pending.
  Future<FriendOperationResult> sendRequest({
    required String fromUid,
    required String fromUsername,
    required String toUid,
  });

  /// Live stream of pending requests where the current user is the
  /// recipient — drives the profile screen's incoming requests list
  /// and the bottom-nav badge count.
  Stream<List<IncomingFriendRequest>> watchIncomingRequests({
    required String uid,
  });

  /// Live stream of the user's confirmed friends — drives the
  /// leaderboard's Friends tab.
  Stream<List<Friend>> watchFriends({required String uid});

  /// Accept a pending request: writes friend docs on both sides
  /// (atomic batch) and flips the request status to `accepted`.
  Future<FriendOperationResult> acceptRequest({
    required String requestId,
    required String myUid,
    required String myUsername,
  });

  /// Decline a pending request — just flips the status to `declined`.
  /// We keep the doc around so the sender's UI can show the rejection
  /// rather than letting the request quietly disappear.
  Future<FriendOperationResult> declineRequest({
    required String requestId,
    required String myUid,
  });
}

/// Local-only preview that lets the friends UI exercise its full flow
/// without Firestore configured. Backed by in-memory maps — resets on
/// each app launch. Bootstrap swaps in the Firestore impl when Firebase
/// is initialised.
@LazySingleton(as: FriendsRepository)
class PreviewFriendsRepository implements FriendsRepository {
  PreviewFriendsRepository();

  final _seedUsers = <String, _SeedUser>{
    'seed_zain': const _SeedUser('zain_r', 'BMW M3'),
    'seed_ali': const _SeedUser('ali_k', 'Toyota Corolla'),
    'seed_sara': const _SeedUser('sara_m', 'Honda Civic'),
    'seed_omar': const _SeedUser('omar_m', 'Ford Mustang'),
    'seed_hamza': const _SeedUser('hamza_r', 'Suzuki Swift'),
  };

  final _sentRequests = <String>{}; // toUid set per current user
  final _incoming = StreamController<List<IncomingFriendRequest>>.broadcast();
  final _friends = StreamController<List<Friend>>.broadcast();
  final _friendList = <Friend>[];

  @override
  Future<List<FriendSearchResult>> searchByUsernamePrefix({
    required String prefix,
    required String myUid,
  }) async {
    if (prefix.length < 3) return const <FriendSearchResult>[];
    final lower = prefix.toLowerCase();
    return _seedUsers.entries
        .where((e) => e.value.username.toLowerCase().startsWith(lower))
        .map(
          (e) => FriendSearchResult(
            uid: e.key,
            username: e.value.username,
            carName: e.value.carName,
            requestSent: _sentRequests.contains(e.key),
            alreadyFriend: _friendList.any((f) => f.uid == e.key),
          ),
        )
        .toList();
  }

  @override
  Future<FriendOperationResult> sendRequest({
    required String fromUid,
    required String fromUsername,
    required String toUid,
  }) async {
    if (_sentRequests.contains(toUid)) {
      return FriendOperationResult.alreadyExists;
    }
    _sentRequests.add(toUid);
    return FriendOperationResult.ok;
  }

  @override
  Stream<List<IncomingFriendRequest>> watchIncomingRequests({
    required String uid,
  }) {
    // Preview always reports an empty list — there's no other user
    // sending us requests in local dev.
    Future.microtask(() => _incoming.add(const <IncomingFriendRequest>[]));
    return _incoming.stream;
  }

  @override
  Stream<List<Friend>> watchFriends({required String uid}) {
    Future.microtask(() => _friends.add(List.of(_friendList)));
    return _friends.stream;
  }

  @override
  Future<FriendOperationResult> acceptRequest({
    required String requestId,
    required String myUid,
    required String myUsername,
  }) async {
    return FriendOperationResult.ok;
  }

  @override
  Future<FriendOperationResult> declineRequest({
    required String requestId,
    required String myUid,
  }) async {
    return FriendOperationResult.ok;
  }

  @override
  Future<List<String>> uidsFor(String uid) async =>
      _friendList.map((f) => f.uid).toList();
}

class _SeedUser {
  const _SeedUser(this.username, this.carName);
  final String username;
  final String carName;
}

/// Production [FriendsRepository] backed by Firestore.
///
/// Collection layout:
///
///   /users/{uid}                                 → { username, carName, ... }
///   /usernames/{lowercased}                      → { uid, createdAt }   (Issue 13)
///   /friend_requests/{autoId}                    → { fromUid, fromUsername, toUid, status, createdAt }
///   /friends/{uid}/friendList/{friendUid}        → { username, addedAt }
class FirestoreFriendsRepository implements FriendsRepository {
  FirestoreFriendsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('friend_requests');
  CollectionReference<Map<String, dynamic>> _friendList(String uid) =>
      _db.collection('friends').doc(uid).collection('friendList');

  @override
  Future<List<FriendSearchResult>> searchByUsernamePrefix({
    required String prefix,
    required String myUid,
  }) async {
    if (prefix.length < 3) return const <FriendSearchResult>[];
    try {
      final lower = prefix.toLowerCase();
      // Firestore prefix search trick: range query with the next codepoint.
      final upper = '$lower';
      final snap = await _users
          .where('usernameLower', isGreaterThanOrEqualTo: lower)
          .where('usernameLower', isLessThanOrEqualTo: upper)
          .limit(20)
          .get();
      // Skip the searcher's own row.
      final users = snap.docs.where((d) => d.id != myUid).toList();
      if (users.isEmpty) return const <FriendSearchResult>[];

      // Resolve which uids we've already sent requests to + already
      // friends with. Both are bounded reads (limit ~20).
      final sentFut = _requests
          .where('fromUid', isEqualTo: myUid)
          .where('toUid', whereIn: users.map((d) => d.id).take(10).toList())
          .where('status', isEqualTo: 'pending')
          .get();
      final friendsFut = _friendList(myUid).get();
      final results = await Future.wait([sentFut, friendsFut]);

      final sentSet = <String>{
        for (final d in results[0].docs) d.data()['toUid'] as String,
      };
      final friendSet = <String>{for (final d in results[1].docs) d.id};

      return users.map((d) {
        final data = d.data();
        return FriendSearchResult(
          uid: d.id,
          username: (data['username'] as String?) ?? '',
          carName: (data['carName'] as String?) ?? '',
          requestSent: sentSet.contains(d.id),
          alreadyFriend: friendSet.contains(d.id),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[FriendsRepository] search failed: $e');
      return const <FriendSearchResult>[];
    }
  }

  @override
  Future<FriendOperationResult> sendRequest({
    required String fromUid,
    required String fromUsername,
    required String toUid,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[FriendsRepository] → friend_requests/(new) '
        'from=$fromUid to=$toUid',
      );
    }
    try {
      // Reject duplicate pending requests in a transaction so we don't
      // race two concurrent sends.
      final result =
          await _db.runTransaction<FriendOperationResult>((txn) async {
        final existing = await _requests
            .where('fromUid', isEqualTo: fromUid)
            .where('toUid', isEqualTo: toUid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          return FriendOperationResult.alreadyExists;
        }
        txn.set(_requests.doc(), <String, Object?>{
          'fromUid': fromUid,
          'fromUsername': fromUsername,
          'toUid': toUid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return FriendOperationResult.ok;
      });
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✓ sendRequest → $result');
      }
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✗ sendRequest failed: $e\n$st');
      }
      return FriendOperationResult.failed;
    }
  }

  @override
  Stream<List<IncomingFriendRequest>> watchIncomingRequests({
    required String uid,
  }) {
    return _requests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return IncomingFriendRequest(
              id: d.id,
              fromUid: (data['fromUid'] as String?) ?? '',
              fromUsername: (data['fromUsername'] as String?) ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList(),
        );
  }

  @override
  Stream<List<Friend>> watchFriends({required String uid}) {
    return _friendList(uid).snapshots().map(
      (snap) => snap.docs.map((d) {
        final data = d.data();
        return Friend(
          uid: d.id,
          username: (data['username'] as String?) ?? '',
          addedAt: (data['addedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );
      }).toList(),
    );
  }

  @override
  Future<FriendOperationResult> acceptRequest({
    required String requestId,
    required String myUid,
    required String myUsername,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[FriendsRepository] → accept friend_requests/$requestId '
        'as $myUid (writes friends/$myUid + friends/<other>)',
      );
    }
    try {
      final requestDoc = _requests.doc(requestId);
      final snap = await requestDoc.get();
      if (!snap.exists) return FriendOperationResult.notFound;
      final data = snap.data() ?? const <String, dynamic>{};
      final fromUid = data['fromUid'] as String?;
      final fromUsername = (data['fromUsername'] as String?) ?? '';
      if (fromUid == null || fromUid.isEmpty) {
        return FriendOperationResult.failed;
      }

      // Atomic: flip status + write both friend docs together.
      await (_db.batch()
            ..update(requestDoc, {'status': 'accepted'})
            ..set(
              _friendList(myUid).doc(fromUid),
              <String, Object?>{
                'username': fromUsername,
                'addedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            )
            ..set(
              _friendList(fromUid).doc(myUid),
              <String, Object?>{
                'username': myUsername,
                'addedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            ))
          .commit();
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✓ accept $requestId');
      }
      return FriendOperationResult.ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✗ accept failed: $e\n$st');
      }
      return FriendOperationResult.failed;
    }
  }

  @override
  Future<FriendOperationResult> declineRequest({
    required String requestId,
    required String myUid,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[FriendsRepository] → decline friend_requests/$requestId',
      );
    }
    try {
      await _requests.doc(requestId).update({'status': 'declined'});
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✓ decline $requestId');
      }
      return FriendOperationResult.ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendsRepository] ✗ decline failed: $e\n$st');
      }
      return FriendOperationResult.failed;
    }
  }

  @override
  Future<List<String>> uidsFor(String uid) async {
    try {
      final snap = await _friendList(uid).get();
      return snap.docs.map((d) => d.id).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[FriendsRepository] uidsFor: $e');
      return const <String>[];
    }
  }
}
