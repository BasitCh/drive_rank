import 'dart:async';

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

  /// Live view of several accounts' mirrors — the friends board's data.
  ///
  /// A listener rather than a fetch for the same reason the friendships
  /// needed one: a friend's figure changes on *their* device, and a
  /// board that only refreshed when the page was rebuilt is the exact
  /// staleness that showed up on device in 4b. Accounts that have never
  /// published are simply absent from the list — no mirror is not a
  /// figure of zero.
  ///
  /// Subscribe only while the friends board is actually showing:
  /// everything under `public_profiles` is a billed read, and a viewer
  /// who never opens that scope should pay for none of it.
  Stream<List<CompetitionMirror>> watchProfiles(List<String> uids);

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
  ///
  /// **Not idempotent, despite the derived id.** A second call writes
  /// the same document, and writing an existing document is an
  /// *update* — which the friendship rule forbids outright, because an
  /// updatable `uids` array would be a way to rewrite who is friends
  /// with whom. So the second caller is refused, not ignored. Callers
  /// must establish that the friendship is absent *remotely* first;
  /// a missing local row is not evidence of that.
  Future<void> createFriendship({required String a, required String b});

  Future<void> deleteFriendship({required String a, required String b});

  Future<List<RemoteFriendship>> friendshipsFor(String uid);

  /// Live view of the friendships this account is part of.
  ///
  /// The friends feature is the first thing in this app whose state is
  /// changed by *somebody else's* device, so it is the first that needs
  /// a listener rather than a poll: without one, a request only appears
  /// when the page is re-created, which is exactly the staleness that
  /// showed up on device.
  Stream<List<RemoteFriendship>> watchFriendships(String uid);

  /// Live view of the requests waiting on this account's answer.
  Stream<List<FriendRequest>> watchIncomingRequests(String uid);

  // Challenges. The first records here whose outcome depends on two
  // people's writes — see the `challenges` block in `firestore.rules`
  // for why no winner is ever stored.

  /// Opens a challenge. The opponent must already be a friend, which
  /// the rules check at the pair-derived friendship path.
  Future<void> createChallenge(Challenge challenge);

  /// Accepts or declines one. Acceptance is refused by the rules once
  /// the window has closed — both people have to agree to compete
  /// before the competition ends.
  Future<void> respondToChallenge({
    required String challengeId,
    required ChallengeStatus response,
  });

  Future<List<Challenge>> challengesFor(String uid);

  Stream<List<Challenge>> watchChallenges(String uid);

  /// Publishes **this account's own** figure for a challenge.
  ///
  /// One document per participant, and the rules let nobody else write
  /// it: that ownership is what makes a derived result trustworthy
  /// without a server deciding it.
  Future<void> publishProgress({
    required String challengeId,
    required String uid,
    required double value,
  });

  /// Both participants' figures, keyed by uid. A uid absent from the
  /// map has published nothing — **which is not a figure of zero.**
  Stream<Map<String, double>> watchProgress(String challengeId);

  /// Live view of the requests this account sent.
  ///
  /// Added once sent requests became something the sender can *see*.
  /// While only incoming ones were watched, the sender never learned
  /// their own request had been answered: the friendship arrived (that
  /// has its own listener) but the request row stayed `pending`
  /// locally, so an accepted request sat in the sender's "requests you
  /// sent" list until they pulled to refresh.
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid);
}

/// The pair key both sides compute identically.
String friendshipKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

String friendRequestKey({required String fromUid, required String toUid}) =>
    '${fromUid}_$toUid';

/// Reads one `public_profiles` document into a [CompetitionMirror].
///
/// A top-level function rather than a method so it can be tested
/// without a Firestore instance: this is where "absent is not zero" and
/// "a missing timestamp is not now" are actually decided, and both are
/// claims about other people that the board then ranks on.
CompetitionMirror mirrorFromFirestore(String uid, Map<String, dynamic> data) {
  final totals = <(CompetitionMetric, LeaderboardPeriod), double?>{};
  for (final metric in CompetitionMetric.values) {
    for (final period in LeaderboardPeriod.values) {
      final value = data[CompetitionMirror.fieldFor(metric, period)];
      // Absent stays absent. This used to fall back to 0, which said
      // "they drove nothing" about somebody whose document simply
      // predates the field — and then ranked them last for it.
      totals[(metric, period)] = (value as num?)?.toDouble();
    }
  }
  final publishedAt = data['updatedAt'];
  return CompetitionMirror(
    uid: uid,
    username: data['username'] as String? ?? '',
    carMake: data['carMake'] as String? ?? '',
    carModel: data['carModel'] as String? ?? '',
    countryCode: data['countryCode'] as String? ?? '',
    inviteCode: data['inviteCode'] as String? ?? '',
    totals: totals,
    // Null rather than "now" when the field is missing: this is the one
    // place where a missing timestamp must not read as fresh, or an
    // ancient document would look like it arrived this second.
    updatedAt: publishedAt is Timestamp
        ? publishedAt.toDate()
        : publishedAt is DateTime
        ? publishedAt
        : null,
  );
}

/// The remote shape of a challenge.
///
/// Top-level so it can be tested without a Firestore instance, like
/// [mirrorFromFirestore]. `participants` is the sorted pair and exists
/// purely so one `arrayContains` query finds both sides' challenges —
/// the rules read it to decide who may see and write anything here, so
/// it must always agree with `creatorUid`/`opponentUid`.
Map<String, Object?> challengeToFirestore(Challenge challenge) {
  final opponent = challenge.opponentUid;
  if (opponent == null) {
    // A personal target is nobody else's business and has no second
    // party to authorise anything.
    throw ArgumentError.value(
      challenge,
      'challenge',
      'A personal target is never published.',
    );
  }
  final participants = [challenge.creatorUid, opponent]..sort();
  return {
    'participants': participants,
    'creatorUid': challenge.creatorUid,
    'opponentUid': opponent,
    'metric': challenge.metric.name,
    'targetValue': challenge.targetValue,
    'period': challenge.period.name,
    'startAt': Timestamp.fromDate(challenge.startAt),
    'endAt': Timestamp.fromDate(challenge.endAt),
    'status': challenge.status.name,
    'createdAt': Timestamp.fromDate(challenge.createdAt),
    'updatedAt': Timestamp.fromDate(challenge.updatedAt),
  };
}

/// Reads one `challenges/{id}` document back.
///
/// A status this client doesn't know falls back to `pending` via
/// [ChallengeStatus.fromName], which is the safe direction: an
/// unrecognised state must not read as a live competition.
///
/// The remote vocabulary is deliberately identical to
/// [ChallengeStatus]'s — `pending`, `active`, `declined`, `cancelled`.
/// The rules never see `completed` or `expired`, which are derived from
/// the two frozen figures rather than written by anybody.
Challenge challengeFromFirestore(String id, Map<String, dynamic> data) {
  DateTime dateOr(Object? value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback;
  }

  final createdAt = dateOr(data['createdAt'], DateTime.now());
  return Challenge(
    id: id,
    creatorUid: data['creatorUid'] as String? ?? '',
    opponentUid: data['opponentUid'] as String?,
    metric: CompetitionMetric.fromName(data['metric'] as String? ?? ''),
    targetValue: (data['targetValue'] as num?)?.toDouble() ?? 0,
    period: LeaderboardPeriod.fromName(data['period'] as String? ?? ''),
    startAt: dateOr(data['startAt'], createdAt),
    endAt: dateOr(data['endAt'], createdAt),
    status: ChallengeStatus.fromName(data['status'] as String? ?? ''),
    createdAt: createdAt,
    updatedAt: dateOr(data['updatedAt'], createdAt),
  );
}

/// Default when Firebase isn't initialised — an empty directory rather
/// than an error, so every friends surface renders its empty state
/// instead of failing.
@LazySingleton(as: SocialDirectory)
class NoopSocialDirectory implements SocialDirectory {
  const NoopSocialDirectory();

  @override
  Future<CompetitionMirror?> profileFor(String uid) async => null;

  @override
  Stream<List<CompetitionMirror>> watchProfiles(List<String> uids) =>
      // An immediate empty list, not `Stream.empty()`: a board waiting
      // for its first event would spin forever on a device where
      // Firebase never initialised.
      Stream.value(const []);

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

  @override
  Stream<List<RemoteFriendship>> watchFriendships(String uid) =>
      const Stream.empty();

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) =>
      const Stream.empty();

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid) =>
      const Stream.empty();

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
    return mirrorFromFirestore(uid, data);
  }

  /// How many document ids one `whereIn` clause accepts.
  ///
  /// Chunking rather than one listener per friend: a friends board with
  /// twenty friends would otherwise open twenty listeners, and the
  /// mirror's read rule is per-document either way, so a batched query
  /// asks for exactly the same access.
  static const int _whereInLimit = 30;

  @override
  Stream<List<CompetitionMirror>> watchProfiles(List<String> uids) {
    final wanted = uids.where((u) => u.isNotEmpty).toSet().toList();
    if (wanted.isEmpty) return Stream.value(const []);

    final chunks = <List<String>>[
      for (var i = 0; i < wanted.length; i += _whereInLimit)
        wanted.sublist(
          i,
          i + _whereInLimit > wanted.length ? wanted.length : i + _whereInLimit,
        ),
    ];

    if (chunks.length == 1) {
      return _profileChunk(chunks.first);
    }

    // Combine-latest by hand rather than pulling in rxdart for one call
    // site. Each chunk's newest result is held and the merged list is
    // re-emitted on every arrival, so a board never renders half its
    // friends because one chunk hasn't answered yet.
    final latest = List<List<CompetitionMirror>?>.filled(chunks.length, null);
    final subs = <StreamSubscription<List<CompetitionMirror>>>[];
    late StreamController<List<CompetitionMirror>> controller;

    controller = StreamController<List<CompetitionMirror>>(
      onListen: () {
        for (var i = 0; i < chunks.length; i++) {
          final index = i;
          subs.add(
            _profileChunk(chunks[index]).listen(
              (mirrors) {
                latest[index] = mirrors;
                if (latest.any((l) => l == null)) return;
                controller.add([for (final l in latest) ...l!]);
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<List<CompetitionMirror>> _profileChunk(List<String> uids) => _profiles
      .where(FieldPath.documentId, whereIn: uids)
      .snapshots()
      .map(
        (snapshot) => [
          for (final d in snapshot.docs) mirrorFromFirestore(d.id, d.data()),
        ],
      );

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
    final doc = _requests.doc(friendRequestKey(fromUid: fromUid, toUid: toUid));

    // One unconditional write, deliberately: Firestore resolves `set`
    // to a create or an update on its own, and the rules judge each
    // accordingly.
    //
    // Reading the document first to decide is *worse than useless*
    // here — a rules read of a document that doesn't exist evaluates
    // against a null `resource`, so it is denied rather than answered
    // "no such thing", and the branch meant to help a re-send broke
    // every first-time request instead. `createdAt` is therefore not
    // immutable on a re-send; `fromUid` and `toUid` still are, and
    // those are the fields the friendship rule reads.
    await doc.set({
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

  /// Deletes the friendship **and** ends the accepted requests behind
  /// it, in one batch.
  ///
  /// Both or neither. Deleting only the friendship leaves an accepted
  /// request with no friendship, which is precisely the shape the sync's
  /// self-healing pass repairs — so the next sync on either device would
  /// recreate the friendship that was just ended. The two-account
  /// walkthrough caught exactly that.
  @override
  Future<void> deleteFriendship({
    required String a,
    required String b,
  }) async {
    final batch = _firestore.batch()
      ..delete(_friendships.doc(friendshipKey(a, b)));

    // Either direction may hold the acceptance, and in principle both
    // could, so end whichever exist.
    for (final (from, to) in [(a, b), (b, a)]) {
      final ref = _requests.doc(friendRequestKey(fromUid: from, toUid: to));
      final snapshot = await ref.get();
      if (snapshot.data()?['status'] == FriendRequestStatus.accepted.name) {
        batch.update(ref, {
          'status': FriendRequestStatus.ended.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    await batch.commit();
  }

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

  @override
  Stream<List<RemoteFriendship>> watchFriendships(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _friendships
        .where('uids', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => [
            for (final d in snapshot.docs)
              RemoteFriendship(
                pairKey: d.id,
                uids: List<String>.from(d.data()['uids'] as List? ?? const []),
                createdAt: _dateFrom(d.data()['createdAt']),
              ),
          ],
        );
  }

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _requests
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => [for (final d in snapshot.docs) _requestFrom(d)]);
  }

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    // The second listener this collection needs. It used to be skipped
    // on the grounds that an outgoing request changing state mattered
    // less to the sender than an arriving one does to the recipient —
    // true while a sent request was invisible, false now that it is
    // listed with a withdraw button. Without this the sender watches
    // an accepted request sit in that list.
    return _requests
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => [for (final d in snapshot.docs) _requestFrom(d)]);
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

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');

  @override
  Future<void> createChallenge(Challenge challenge) {
    return _challenges
        .doc(challenge.id)
        .set(challengeToFirestore(challenge));
  }

  @override
  Future<void> respondToChallenge({
    required String challengeId,
    required ChallengeStatus response,
  }) {
    // A status-only update. The rules refuse any write that touches the
    // terms — the result is derived from them, so a mutable target or
    // window would be a way to rewrite an outcome without touching a
    // single figure — so they are deliberately absent rather than
    // resent unchanged.
    return _challenges.doc(challengeId).update({
      'status': response.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<List<Challenge>> challengesFor(String uid) async {
    if (uid.isEmpty) return const [];
    final result = await _challenges
        .where('participants', arrayContains: uid)
        .get();
    return [
      for (final d in result.docs) challengeFromFirestore(d.id, d.data()),
    ];
  }

  @override
  Stream<List<Challenge>> watchChallenges(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    // One listener for both sides, which is the whole reason
    // `participants` is stored as a sorted pair rather than being
    // derived from creator/opponent at read time: Firestore has no OR
    // across two fields.
    return _challenges
        .where('participants', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => [
            for (final d in snapshot.docs)
              challengeFromFirestore(d.id, d.data()),
          ],
        );
  }

  @override
  Future<void> publishProgress({
    required String challengeId,
    required String uid,
    required double value,
  }) {
    // One unconditional `set`, never a read first: a rules read of a
    // document that does not exist is *denied* rather than answered
    // empty, so "check whether my figure is there" cannot be asked.
    return _challenges.doc(challengeId).collection('progress').doc(uid).set({
      'value': value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<Map<String, double>> watchProgress(String challengeId) {
    if (challengeId.isEmpty) return Stream.value(const {});
    return _challenges
        .doc(challengeId)
        .collection('progress')
        .snapshots()
        .map(
          (snapshot) => {
            for (final d in snapshot.docs)
              // A document id is the owner's uid. A uid absent from
              // this map published nothing, which is not zero.
              if (d.data()['value'] is num)
                d.id: (d.data()['value'] as num).toDouble(),
          },
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
