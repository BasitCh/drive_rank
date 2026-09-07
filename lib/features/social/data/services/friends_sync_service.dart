import 'dart:async';

import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Brings this account's friendships and requests down into Drift.
///
/// The app's standing rule is that reads are served from Drift and
/// Firestore is a write-only sync target. Friends is the first genuine
/// exception — a friendship is created by *somebody else's* device — so
/// the rule is preserved where it matters: this pulls remote state into
/// the local tables, and every screen still watches Drift. The friends
/// list therefore renders offline, and reactively, like the rest of the
/// app.
///
/// **Reconciles; never appends.** Each pass makes the local tables match
/// what Firestore returned: friendships that vanished remotely are
/// deleted locally, so unfriending on another device lands here, and
/// running it three times leaves exactly what running it once did.
@lazySingleton
class FriendsSyncService {
  FriendsSyncService(this._local, this._settings);

  final SocialLocalDataSource _local;
  final UserSettingsRepository _settings;

  /// Resolved lazily for the reason `SyncManager` documents: a
  /// constructor-injected Firestore dependency captures the pre-Firebase
  /// no-op permanently, and every write silently goes nowhere.
  SocialDirectory get _directory => getIt<SocialDirectory>();

  StreamSubscription<void>? _friendshipsSub;
  StreamSubscription<void>? _requestsSub;
  StreamSubscription<void>? _sentSub;

  /// Serialises reconciliation passes.
  ///
  /// Three listeners drive this, and two of them (incoming and
  /// outgoing requests) wake for the *same* remote change — so without
  /// a queue the same pass ran twice at once, each half deciding from a
  /// database the other was mid-write on. Same reasoning, and the same
  /// shape, as `LocalSocialTripProcessor`'s queue.
  Future<void> _queue = Future<void>.value();

  Future<void> _serialised(Future<void> Function() work) {
    final result = _queue.then((_) => work());
    // The queue must never hold an error, or one failed pass would
    // poison every later one.
    _queue = result.catchError((Object e, StackTrace st) {
      if (kDebugMode) debugPrint('[FriendsSync] pass failed: $e');
    });
    return result;
  }

  /// Starts reconciling live, instead of only when something asks.
  ///
  /// Everything else in this app can poll, because everything else is
  /// changed by the person holding the phone. A friend request is not:
  /// it arrives because somebody else acted, and until this existed the
  /// only way to see one was to close and reopen the page — the cloud
  /// was consulted once, at page construction.
  ///
  /// Idempotent: calling it again replaces the subscriptions rather than
  /// stacking a second pair.
  Future<void> start() async {
    final uid = (await _settings.read()).uid;
    if (_isPlaceholder(uid)) return;

    await stop();
    // Each snapshot is reconciled the same way a manual pass is, so
    // live and manual can't drift apart in behaviour.
    _friendshipsSub = _directory.watchFriendships(uid).listen(
      (_) => _serialised(() => _syncFriendships(uid)),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[FriendsSync] friendships stream: $e');
      },
    );
    _requestsSub = _directory.watchIncomingRequests(uid).listen(
      (_) => _serialised(() => _syncRequests(uid)),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[FriendsSync] requests stream: $e');
      },
    );
    // Both directions. A request the *sender* is watching changes state
    // on the recipient's device, so without this the sender's own
    // accepted request stayed `pending` locally and sat in their
    // "requests you sent" list until they pulled to refresh.
    _sentSub = _directory.watchOutgoingRequests(uid).listen(
      (_) => _serialised(() => _syncRequests(uid)),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[FriendsSync] sent stream: $e');
      },
    );
  }

  Future<void> stop() async {
    await _friendshipsSub?.cancel();
    await _requestsSub?.cancel();
    await _sentSub?.cancel();
    _friendshipsSub = null;
    _requestsSub = null;
    _sentSub = null;
  }

  static bool _isPlaceholder(String uid) =>
      uid.isEmpty || uid == 'local' || uid == 'pending';

  Future<void> syncNow() async {
    try {
      final uid = (await _settings.read()).uid;
      if (_isPlaceholder(uid)) return;

      await _serialised(() async {
        await _syncFriendships(uid);
        await _syncRequests(uid);
      });
    } catch (e, st) {
      // Same contract as a trip upload: a failed pass costs freshness,
      // and the next one recomputes from scratch.
      if (kDebugMode) debugPrint('[FriendsSync] failed: $e\n$st');
    }
  }

  Future<void> _syncFriendships(String uid) async {
    final remote = await _directory.friendshipsFor(uid);

    // One remote document becomes two local rows, one per direction,
    // sharing the remote id. A remote id therefore identifies a
    // friendship, not a row — the unique key that holds locally is
    // {ownerUid, friendUid}.
    final expected = <String>{};
    for (final friendship in remote) {
      final other = friendship.otherThan(uid);
      if (other.isEmpty) continue;
      expected.add(other);
      await _local.insertFriendship(
        remoteId: friendship.pairKey,
        ownerUid: uid,
        friendUid: other,
        at: friendship.createdAt,
      );
    }

    // Anything local that the cloud no longer has was unfriended
    // elsewhere. Removing it here is what makes "they dropped me" show
    // up on this device at all.
    final local = await _local.getFriends(uid);
    for (final row in local) {
      if (!expected.contains(row.friendUid)) {
        await _local.deleteFriendship(uidA: uid, uidB: row.friendUid);
      }
    }
  }

  Future<void> _syncRequests(String uid) async {
    final remote = await _directory.requestsFor(uid);

    // Reconcile, like friendships: the cloud is the truth and the local
    // table is a cache of it. This also clears the phantom rows an
    // earlier bug left behind, where a locally-minted UUID meant the
    // same request existed twice and the copy nobody updated stayed
    // `pending` — which then blocked every future request to that
    // person.
    await _local.deleteRequestsNotIn(
      uid: uid,
      keepRemoteIds: remote.map((r) => r.id).toSet(),
    );

    for (final request in remote) {
      await _local.upsertFriendRequest(
        remoteId: request.id,
        fromUid: request.fromUid,
        toUid: request.toUid,
        status: request.status.name,
        createdAt: request.createdAt,
        updatedAt: request.updatedAt,
      );

      // Accepting is two remote writes — the status, then the
      // friendship — and nothing guarantees the second one landed. A
      // request that is accepted with no friendship is finished here
      // instead of leaving two people who both agreed and neither of
      // whom is a friend. Both sides can do this; the pair-keyed
      // document means they converge rather than collide.
      //
      // Only `accepted` heals. An unfriend moves the request to
      // `ended` in the same batch that deletes the friendship, because
      // otherwise the two situations are the same shape and this pass
      // would resurrect a friendship somebody deliberately ended.
      if (request.status == FriendRequestStatus.accepted) {
        final other = request.fromUid == uid ? request.toUid : request.fromUid;
        if (await _local.friendshipExists(uid, other)) continue;

        // **The local row missing does not mean the friendship is.**
        // The usual reason this pass runs at all is the other person
        // having just accepted: the friendship document already exists
        // remotely and simply hasn't been projected here yet. Writing
        // it again is an *update*, which the rules forbid outright —
        // so the create that was meant to heal a missing friendship
        // instead threw permission-denied straight into Crashlytics,
        // every single time somebody accepted.
        //
        // A query, not a document read: a rules read of a document
        // that does not exist is denied rather than answered, so
        // "check whether it exists" has to be phrased as a query over
        // the collection, which legitimately comes back empty.
        final remote = await _directory.friendshipsFor(uid);
        final existsRemotely = remote.any((f) => f.uids.contains(other));

        if (!existsRemotely) {
          try {
            await _directory.createFriendship(a: uid, b: other);
          } catch (e) {
            // Both devices can reach this at once, and the loser of
            // that race is refused for the same reason. Harmless: the
            // winner's document is the one both sides then project.
            if (kDebugMode) debugPrint('[FriendsSync] heal skipped: $e');
            continue;
          }
        }

        await _local.insertFriendship(
          remoteId: friendshipKey(uid, other),
          ownerUid: uid,
          friendUid: other,
          at: request.updatedAt,
        );
      }
    }
  }
}
