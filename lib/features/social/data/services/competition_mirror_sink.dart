import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Where a published [CompetitionMirror] goes.
///
/// Split from the publisher for the same reason `RemoteTripSink` is split
/// from `SyncManager`: computing what to publish is local logic that
/// works with or without a backend, while *writing* it needs Firebase
/// and has to be swappable — both for the no-Firebase build and, later,
/// for the server-authoritative path that replaces client publishing
/// once rankings carry real stakes.
// ignore: one_member_abstracts
abstract class CompetitionMirrorSink {
  /// Writes the mirror. Throwing means "failed, try again later" — the
  /// caller does not retry inline.
  Future<void> write(CompetitionMirror mirror);
}

/// Default when Firebase isn't initialised.
@LazySingleton(as: CompetitionMirrorSink)
class NoopCompetitionMirrorSink implements CompetitionMirrorSink {
  const NoopCompetitionMirrorSink();

  @override
  Future<void> write(CompetitionMirror mirror) async {
    if (kDebugMode) {
      debugPrint(
        '[CompetitionMirror] (preview) skip /public_profiles/${mirror.uid} '
        '— Firebase not initialised',
      );
    }
  }
}

/// Production implementation — `public_profiles/{uid}`.
///
/// A **full `set`**, not a merge and never an increment. The document is
/// a snapshot of values recomputed from local state, so writing it twice
/// — a retry, a second device, two triggers firing together — produces
/// the same document. An accumulating write would look correct until the
/// first retry silently doubled someone's week.
class FirestoreCompetitionMirrorSink implements CompetitionMirrorSink {
  FirestoreCompetitionMirrorSink(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> write(CompetitionMirror mirror) async {
    final payload = <String, Object?>{
      'username': mirror.username,
      'usernameLower': mirror.username.toLowerCase(),
      'carMake': mirror.carMake,
      'carModel': mirror.carModel,
      'countryCode': mirror.countryCode,
      'updatedAt': FieldValue.serverTimestamp(),
      for (final metric in CompetitionMetric.values)
        for (final period in LeaderboardPeriod.values)
          CompetitionMirror.fieldFor(metric, period): mirror.totalFor(
            metric,
            period,
          ),
    };

    await _firestore
        .collection('public_profiles')
        .doc(mirror.uid)
        .set(payload);

    if (kDebugMode) {
      debugPrint('[CompetitionMirror] ✓ /public_profiles/${mirror.uid}');
    }
  }
}
