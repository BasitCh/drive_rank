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

  Future<void> syncNow() async {
    try {
      final uid = (await _settings.read()).uid;
      if (uid.isEmpty || uid == 'local' || uid == 'pending') return;

      await _syncFriendships(uid);
      await _syncRequests(uid);
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
      if (request.status == FriendRequestStatus.accepted) {
        final other = request.fromUid == uid ? request.toUid : request.fromUid;
        final alreadyFriends = await _local.friendshipExists(uid, other);
        if (!alreadyFriends) {
          await _directory.createFriendship(a: uid, b: other);
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
}
