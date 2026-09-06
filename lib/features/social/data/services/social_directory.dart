import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// A friendship as it exists remotely: one document, both parties.
@immutable
class RemoteFriendship {
  const RemoteFriendship({
    required this.pairKey,
    required this.uids,
    required this.createdAt,
  });

  final String pairKey;
  final List<String> uids;
  final DateTime createdAt;

  /// The other person, from [me]'s point of view.
  String otherThan(String me) => uids.firstWhere((u) => u != me, orElse: () => '');
}

/// Reading and writing the shared social surfaces.
///
/// Everything the app knows about *other people* comes through here:
/// looking somebody up, sending them a request, answering one, and the
/// friendships that result. Trips, settings and competition values keep
/// their own paths — this is deliberately only the part that involves
/// two accounts.
///
/// The document ids are load-bearing, not incidental:
///  * a request lives at `{fromUid}_{toUid}`, because the friendship
///    rule has to *name* the request that authorises it — a security
///    rule's `get()` takes a path, and rules have no query;
///  * a friendship lives at the two uids sorted and joined, so the same
///    pair resolves to the same document from either side and cannot be
///    created twice.
abstract class SocialDirectory {
  /// The mirror for one account, or null if they have never published.
  Future<CompetitionMirror?> profileFor(String uid);

  /// Resolves a claimed username to its account.
  Future<String?> uidForUsername(String username);

  /// Resolves a shared invite code to its account.
  Future<String?> uidForInviteCode(String code);

  Future<void> sendRequest({required String fromUid, required String toUid});

  Future<void> respondToRequest({
    required String fromUid,
    required String toUid,
    required FriendRequestStatus response,
  });

  Future<void> cancelRequest({required String fromUid, required String toUid});

  /// Every request this account sent or received.
  Future<List<FriendRequest>> requestsFor(String uid);

  /// Creates the friendship an accepted request entitles these two to.
  /// Idempotent — the document id is derived from the pair, so a second
  /// call from the other device writes the same document.
  Future<void> createFriendship({required String a, required String b});

  Future<void> deleteFriendship({required String a, required String b});

  Future<List<RemoteFriendship>> friendshipsFor(String uid);
}

/// The pair key both sides compute identically.
String friendshipKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

String friendRequestKey({required String fromUid, required String toUid}) =>
    '${fromUid}_$toUid';

/// Default when Firebase isn't initialised — an empty directory rather
/// than an error, so every friends surface renders its empty state
/// instead of failing.
@LazySingleton(as: SocialDirectory)
class NoopSocialDirectory implements SocialDirectory {
  const NoopSocialDirectory();

  @override
  Future<CompetitionMirror?> profileFor(String uid) async => null;

  @override
  Future<String?> uidForUsername(String username) async => null;

  @override
  Future<String?> uidForInviteCode(String code) async => null;

  @override
  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
  }) async {}

  @override
  Future<void> respondToRequest({
    required String fromUid,
    required String toUid,
    required FriendRequestStatus response,
  }) async {}

  @override
  Future<void> cancelRequest({
    required String fromUid,
    required String toUid,
  }) async {}

  @override
  Future<List<FriendRequest>> requestsFor(String uid) async => const [];

  @override
  Future<void> createFriendship({
    required String a,
    required String b,
  }) async {}

  @override
  Future<void> deleteFriendship({
    required String a,
    required String b,
  }) async {}

  @override
  Future<List<RemoteFriendship>> friendshipsFor(String uid) async => const [];
}

class FirestoreSocialDirectory implements SocialDirectory {
  FirestoreSocialDirectory(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('public_profiles');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('friend_requests');
  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  @override
  Future<CompetitionMirror?> profileFor(String uid) async {
    if (uid.isEmpty) return null;
    final snapshot = await _profiles.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return _mirrorFrom(uid, data);
  }

  @override
  Future<String?> uidForUsername(String username) async {
    final key = username.trim().toLowerCase();
    if (key.isEmpty) return null;
    // The reservation document already holds the uid, so resolving a
    // name is one point read — no query, and therefore no index.
    final snapshot = await _firestore.collection('usernames').doc(key).get();
    return snapshot.data()?['uid'] as String?;
  }

  @override
  Future<String?> uidForInviteCode(String code) async {
    if (code.isEmpty) return null;
    final result = await _profiles
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : result.docs.first.id;
  }

  @override
  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    final now = DateTime.now();
    await _requests.doc(friendRequestKey(fromUid: fromUid, toUid: toUid)).set({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': FriendRequestStatus.pending.name,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> respondToRequest({
    required String fromUid,
    required String toUid,
    required FriendRequestStatus response,
  }) async {
    // A status-only update: the rules refuse any write that touches
    // fromUid, toUid or createdAt, so those are deliberately absent
    // rather than resent unchanged.
    await _requests.doc(friendRequestKey(fromUid: fromUid, toUid: toUid)).update({
      'status': response.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
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
  Future<List<FriendRequest>> requestsFor(String uid) async {
    // Two queries rather than one: Firestore has no OR across different
    // fields, and both are single-field equalities, so neither needs an
    // index.
    final incoming = await _requests.where('toUid', isEqualTo: uid).get();
    final outgoing = await _requests.where('fromUid', isEqualTo: uid).get();
    return [
      for (final d in [...incoming.docs, ...outgoing.docs]) _requestFrom(d),
    ];
  }

  @override
  Future<void> createFriendship({
    required String a,
    required String b,
  }) async {
    final uids = [a, b]..sort();
    await _friendships.doc(friendshipKey(a, b)).set({
      'uids': uids,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> deleteFriendship({
    required String a,
    required String b,
  }) => _friendships.doc(friendshipKey(a, b)).delete();

  @override
  Future<List<RemoteFriendship>> friendshipsFor(String uid) async {
    final result = await _friendships
        .where('uids', arrayContains: uid)
        .get();
    return [
      for (final d in result.docs)
        RemoteFriendship(
          pairKey: d.id,
          uids: List<String>.from(d.data()['uids'] as List? ?? const []),
          createdAt: _dateFrom(d.data()['createdAt']),
        ),
    ];
  }

  FriendRequest _requestFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return FriendRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      status: FriendRequestStatus.fromName(data['status'] as String? ?? ''),
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  CompetitionMirror _mirrorFrom(String uid, Map<String, dynamic> data) {
    final totals = <(CompetitionMetric, LeaderboardPeriod), double>{};
    for (final metric in CompetitionMetric.values) {
      for (final period in LeaderboardPeriod.values) {
        final value = data[CompetitionMirror.fieldFor(metric, period)];
        totals[(metric, period)] = (value as num?)?.toDouble() ?? 0;
      }
    }
    return CompetitionMirror(
      uid: uid,
      username: data['username'] as String? ?? '',
      carMake: data['carMake'] as String? ?? '',
      carModel: data['carModel'] as String? ?? '',
      countryCode: data['countryCode'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      totals: totals,
    );
  }

  DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    // A serverTimestamp reads back null on the writing client until it
    // resolves; treating that as "now" keeps ordering sane rather than
    // parking the row at the epoch.
    return DateTime.now();
  }
}
