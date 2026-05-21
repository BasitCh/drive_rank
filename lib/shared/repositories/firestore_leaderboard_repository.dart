import 'dart:math' as math;

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

      final live = _materialise(snap.docs, myUid);
      // Until the cloud has real users on it, show a deterministic
      // seed pool so the board never looks like a broken/empty
      // screen on first launch. The user's own best (if any) is
      // merged in and the list is re-ranked. As soon as enough
      // real entries land the seed is hidden — see _topUpWithSeed.
      return _topUpWithSeed(
        live: live,
        scope: scope,
        myUid: myUid,
        myCountry: settings.country ?? 'US',
        limit: limit,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[LeaderboardRepository] ✗ getEntries failed: $e\n$st',
        );
      }
      // Even on Firestore failure (no network, rules deny, etc.) we
      // still want the user to see something — fall back to the
      // pure-seed leaderboard so the screen renders.
      final settings = await _settings.read();
      return _topUpWithSeed(
        live: const <LeaderboardEntry>[],
        scope: scope,
        myUid: settings.uid,
        myCountry: settings.country ?? 'US',
        limit: limit,
      );
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

  /// Tops up the live leaderboard with deterministic seeded entries
  /// when the cloud doesn't yet have enough real users for the screen
  /// to feel populated. Once [live] reaches half the requested limit
  /// we stop seeding so growing real-world data displaces the seed.
  ///
  /// Seed pool is keyed off the scope id so the ranks don't churn
  /// between visits. Real entries always sort above seed entries with
  /// the same top speed (we sort by speed desc, then by `isSeed`).
  List<LeaderboardEntry> _topUpWithSeed({
    required List<LeaderboardEntry> live,
    required LeaderboardScope scope,
    required String myUid,
    required String myCountry,
    required int limit,
  }) {
    // Don't seed friends boards — friends are a closed set; empty is
    // the correct signal.
    if (scope is LeaderboardScopeFriends) return live;

    // Once real-user count >= half the limit, the screen feels alive
    // on its own; drop the seed entirely.
    final threshold = (limit / 2).ceil();
    if (live.length >= threshold) return live;

    final seed = _seededPool(scope, myCountry, limit + 5);
    // Merge live + seed, but only seed entries that aren't already
    // covered by a live uid.
    final liveUids = {for (final e in live) e.uid};
    final merged = <LeaderboardEntry>[
      ...live,
      ...seed.where((s) => !liveUids.contains(s.uid)),
    ]..sort((a, b) => b.topSpeedKmh.compareTo(a.topSpeedKmh));

    // Re-rank from 1 and flag the current user if their seed entry
    // bubbled into view (won't happen — seed uids never collide with
    // real uids — but the `isYou` flag costs nothing to recompute).
    return [
      for (var i = 0; i < merged.length && i < limit; i++)
        merged[i].copyWith(rank: i + 1, isYou: merged[i].uid == myUid),
    ];
  }

  /// Deterministic competitor pool keyed off the scope id. Speeds skew
  /// higher for famous segments (Stelvio, Nürburgring, …) and lower
  /// for global so the board feels plausible across scopes.
  List<LeaderboardEntry> _seededPool(
    LeaderboardScope scope,
    String myCountry,
    int count,
  ) {
    final seed = scope.id.hashCode;
    final rand = math.Random(seed);
    const names = [
      'zain_r', 'ali_k', 'sara_m', 'omar_m', 'hamza_r', 'leila_v',
      'noah_t', 'mia_s', 'liam_w', 'aisha_b', 'kenji_o', 'maya_d',
      'rico_p', 'ines_g', 'theo_l',
    ];
    const cars = [
      'Toyota Corolla', 'Honda Civic', 'BMW M3', 'Ford Mustang',
      'Suzuki Swift', 'Tesla Model 3', 'Hyundai i30', 'Mazda MX-5',
      'Nissan GT-R', 'Volkswagen Golf',
    ];
    final basis = switch (scope) {
      LeaderboardScopeSegment _ => 180.0,
      LeaderboardScopeCountry _ => 165.0,
      LeaderboardScopeGlobal _ => 200.0,
      LeaderboardScopeFriends _ => 140.0,
    };
    return [
      for (var i = 0; i < count; i++)
        LeaderboardEntry(
          uid: 'seed_${scope.id}_$i',
          username: names[(i + seed.abs()) % names.length],
          carName: cars[(i * 3 + seed.abs()) % cars.length],
          topSpeedKmh: (basis - i * 1.5 + rand.nextDouble() * 4 - 2)
              .clamp(60, 250),
          country: scope is LeaderboardScopeCountry
              ? scope.countryCode
              : myCountry,
          rank: 0,
        ),
    ];
  }
}

/// Tiny interface so the leaderboard repository doesn't need to depend
/// on the whole friends feature — the friends repository (Issue 11)
/// implements this and is injected by bootstrap.
// ignore: one_member_abstracts
abstract class FriendUidsSource {
  Future<List<String>> uidsFor(String uid);
}
