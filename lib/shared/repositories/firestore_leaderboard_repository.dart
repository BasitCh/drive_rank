import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:drive_rank/shared/repositories/leaderboard_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// Production [LeaderboardRepository] backed by Firestore.
///
/// Document layout:
///
///   /leaderboard/global/entries/{uid}
///   /leaderboard/{countryCode}/entries/{uid}
///
/// Each entry is a single document with:
///   { username, carName, topSpeedKmh, countryCode, updatedAt }
///
/// Reads sort by `topSpeedKmh desc` and slice to the requested limit
/// (default 100). The current user's row is highlighted by the UI via
/// [LeaderboardEntry.isYou] — set here by comparing the doc id to the
/// signed-in uid pulled from `UserSettingsRepository`.
///
/// Friend-scope queries delegate to the friend list maintained by the
/// invite-friends feature; the actual entry read is a `whereIn` against
/// the global collection so we don't double-write per-friend.
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  FirestoreLeaderboardRepository(this._db, this._settings, this._friends);

  final FirebaseFirestore _db;
  final UserSettingsRepository _settings;
  final FriendUidsSource _friends;

  CollectionReference<Map<String, dynamic>> _entries(String boardId) =>
      _db.collection('leaderboard').doc(boardId).collection('entries');

  @override
  Future<List<LeaderboardEntry>> getEntries({
    required LeaderboardScope scope,
    int limit = 100,
  }) async {
    try {
      final settings = await _settings.read();
      final myUid = settings.uid;

      if (scope is LeaderboardScopeFriends) {
        return _friendsEntries(myUid: myUid, limit: limit);
      }

      final boardId = switch (scope) {
        LeaderboardScopeGlobal _ => 'global',
        final LeaderboardScopeCountry s => s.countryCode,
        final LeaderboardScopeSegment s => 'segment_${s.segmentId}',
        LeaderboardScopeFriends _ => 'global', // handled above
      };

      final snap = await _entries(boardId)
          .orderBy('topSpeedKmh', descending: true)
          .limit(limit)
          .get();

      return _materialise(snap.docs, myUid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LeaderboardRepository] getEntries failed: $e');
      }
      return const <LeaderboardEntry>[];
    }
  }

  Future<List<LeaderboardEntry>> _friendsEntries({
    required String myUid,
    required int limit,
  }) async {
    final friendUids = await _friends.uidsFor(myUid);
    // Include self in the friends board.
    final uids = <String>{myUid, ...friendUids}.toList();
    if (uids.isEmpty) return const <LeaderboardEntry>[];
    // Firestore `whereIn` supports up to 30 values per query — friends
    // boards stay under that in practice, but we still chunk to be safe.
    final chunks = <List<String>>[];
    for (var i = 0; i < uids.length; i += 30) {
      chunks.add(uids.sublist(i, (i + 30).clamp(0, uids.length)));
    }
    final collected = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final chunk in chunks) {
      final snap = await _entries('global')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      collected.addAll(snap.docs);
    }
    collected.sort((a, b) {
      final av = (a.data()['topSpeedKmh'] as num?)?.toDouble() ?? 0;
      final bv = (b.data()['topSpeedKmh'] as num?)?.toDouble() ?? 0;
      return bv.compareTo(av);
    });
    return _materialise(
      collected.take(limit).toList(),
      myUid,
    );
  }

  @override
  Future<LeaderboardEntry?> getCurrentUserEntry({
    required LeaderboardScope scope,
  }) async {
    try {
      final settings = await _settings.read();
      final myUid = settings.uid;

      final boardId = switch (scope) {
        LeaderboardScopeGlobal _ => 'global',
        final LeaderboardScopeCountry s => s.countryCode,
        final LeaderboardScopeSegment s => 'segment_${s.segmentId}',
        LeaderboardScopeFriends _ => 'global',
      };

      final mine = await _entries(boardId).doc(myUid).get();
      if (!mine.exists) return null;
      final data = mine.data() ?? const <String, dynamic>{};
      final mySpeed =
          (data['topSpeedKmh'] as num?)?.toDouble() ?? 0;

      // Exact rank = 1 + count of entries strictly above this speed.
      // Firestore's aggregation count() avoids paging through them.
      final betterCount = await _entries(boardId)
          .where('topSpeedKmh', isGreaterThan: mySpeed)
          .count()
          .get();
      final rank = (betterCount.count ?? 0) + 1;

      return LeaderboardEntry(
        uid: myUid,
        username: (data['username'] as String?) ?? 'driver',
        carName: (data['carName'] as String?) ?? '',
        topSpeedKmh: mySpeed,
        country: (data['countryCode'] as String?) ?? '',
        rank: rank,
        isYou: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LeaderboardRepository] getCurrentUserEntry failed: $e');
      }
      return null;
    }
  }

  List<LeaderboardEntry> _materialise(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String myUid,
  ) {
    final result = <LeaderboardEntry>[];
    for (var i = 0; i < docs.length; i++) {
      final d = docs[i];
      final data = d.data();
      result.add(
        LeaderboardEntry(
          uid: d.id,
          username: (data['username'] as String?) ?? 'driver',
          carName: (data['carName'] as String?) ?? '',
          topSpeedKmh:
              (data['topSpeedKmh'] as num?)?.toDouble() ?? 0,
          country: (data['countryCode'] as String?) ?? '',
          rank: i + 1,
          isYou: d.id == myUid,
        ),
      );
    }
    return result;
  }
}

/// Tiny interface so the leaderboard repository doesn't need to depend
/// on the whole friends feature — the friends repository (Issue 11)
/// implements this and is injected by bootstrap.
// ignore: one_member_abstracts
abstract class FriendUidsSource {
  Future<List<String>> uidsFor(String uid);
}
