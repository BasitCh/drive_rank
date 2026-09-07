import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/settle_challenge.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// One head-to-head challenge, both sides, ready to render.
@immutable
class ChallengeView {
  const ChallengeView({
    required this.challenge,
    required this.settlement,
    required this.opponentUid,
    required this.isMine,
    this.opponent,
  });

  final Challenge challenge;
  final ChallengeSettlement settlement;
  final String opponentUid;

  /// Whether the viewer opened it — decides who may cancel, and whether
  /// a pending one is waiting on them or on the other person.
  final bool isMine;

  /// The opponent's published identity, when it could be fetched. Their
  /// name comes from here rather than from a uid, for the same reason
  /// friend rows do.
  final CompetitionMirror? opponent;

  String get opponentName {
    final username = opponent?.username ?? '';
    return username.isEmpty ? opponentUid : username;
  }

  /// Waiting on the viewer's answer.
  bool get needsMyAnswer =>
      !isMine && challenge.status == ChallengeStatus.pending;

  /// Sent by the viewer and not yet answered.
  bool get awaitingTheirAnswer =>
      isMine && challenge.status == ChallengeStatus.pending;
}

/// Every head-to-head challenge the viewer is part of, settled.
///
/// The counterpart of `GetTargets`, which deliberately keeps filtering
/// these out: a target is one person's business and a challenge is two
/// people's, so they read from different places and are shown in
/// different sections.
///
/// **The viewer's own figure is recomputed here; the opponent's is
/// read.** Same split as the friends board, and for the same reason: a
/// figure computed from local trips cannot go stale, and reading back
/// what this device last published would let a stale snapshot of
/// yourself decide your own result.
@injectable
class GetChallenges {
  const GetChallenges(this._social, this._calculator, this._settle);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;
  final SettleChallenge _settle;

  /// [opponentProfiles] is whatever the caller managed to fetch, keyed
  /// by uid — a missing one costs a name, never a row.
  Future<List<ChallengeView>> call({
    required String uid,
    Map<String, CompetitionMirror> opponentProfiles = const {},
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final challenges = await _social.getHeadToHeadChallenges(uid);
    final views = <ChallengeView>[];

    for (final challenge in challenges) {
      // Withdrawn and refused challenges are history, not standings.
      if (challenge.status == ChallengeStatus.cancelled ||
          challenge.status == ChallengeStatus.declined) {
        continue;
      }

      final opponentUid = challenge.creatorUid == uid
          ? (challenge.opponentUid ?? '')
          : challenge.creatorUid;
      if (opponentUid.isEmpty) continue;

      // The window the challenge stored, never one re-derived from the
      // period: a challenge starts when it was opened, so those two
      // always disagree.
      final window = CompetitionWindow(
        start: challenge.startAt,
        end: challenge.endAt,
      );
      final trips = await _social.getCompetitionTrips(uid: uid, window: window);
      final mine = _calculator.calculate(
        metric: challenge.metric,
        trips: trips,
        window: window,
      );

      // Absent, not zero. A row the sync never wrote means the opponent
      // published nothing, and `SettleChallenge` must be told that
      // rather than handed a zero it would happily award a win against.
      final theirs = await _social.getProgress(
        challengeId: challenge.id,
        uid: opponentUid,
      );

      views.add(
        ChallengeView(
          challenge: challenge,
          settlement: _settle(
            challenge: challenge,
            mine: mine,
            theirs: theirs?.currentValue,
            now: at,
          ),
          opponentUid: opponentUid,
          isMine: challenge.creatorUid == uid,
          opponent: opponentProfiles[opponentUid],
        ),
      );
    }

    // What needs an answer first, then what is still being decided,
    // then the finished ones — newest first inside each group.
    views.sort((a, b) {
      int rank(ChallengeView v) {
        if (v.needsMyAnswer) return 0;
        if (!v.settlement.isFinal) return 1;
        return 2;
      }

      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return b.challenge.createdAt.compareTo(a.challenge.createdAt);
    });

    return views;
  }
}
