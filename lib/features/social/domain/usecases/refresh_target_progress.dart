import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// What one pass of progress recomputation concluded.
@immutable
class TargetProgressRefresh {
  const TargetProgressRefresh({
    required this.progress,
    required this.completedChallengeIds,
  });

  final List<ChallengeProgress> progress;

  /// Challenges that crossed their target on *this* pass — not ones
  /// already complete, so callers can celebrate only real completions.
  final List<String> completedChallengeIds;
}

/// Recomputes progress for every active challenge and stamps any that
/// have just been met.
///
/// Extracted from the trip processor so the two callers share one
/// definition of "recompute and stamp": the processor runs it after a
/// trip, and target creation runs it immediately so a target set *after*
/// the driving is correct straight away rather than showing zero until
/// the next drive. Two copies of this logic would eventually disagree
/// about when something counts as complete.
@injectable
class RefreshTargetProgress {
  const RefreshTargetProgress(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  Future<TargetProgressRefresh> call({
    required String uid,
    required DateTime at,
  }) async {
    final active = await _social.getActiveChallengesAt(uid: uid, at: at);
    final updated = <ChallengeProgress>[];
    final completed = <String>[];

    for (final challenge in active) {
      // A challenge is scored over the window it stored at creation,
      // never a window re-derived from its period — those disagree for
      // any challenge that didn't start on a period boundary.
      final window = CompetitionWindow(
        start: challenge.startAt,
        end: challenge.endAt,
      );
      final trips = await _social.getCompetitionTrips(
        uid: uid,
        window: window,
      );
      final value = _calculator.calculate(
        metric: challenge.metric,
        trips: trips,
        window: window,
      );

      final existing = await _social.getProgress(
        challengeId: challenge.id,
        uid: uid,
      );
      await _social.upsertProgressValue(
        ChallengeProgress(
          challengeId: challenge.id,
          uid: uid,
          currentValue: value,
          targetValue: challenge.targetValue,
          lastCalculatedAt: at,
        ),
      );

      final reachedTarget = value >= challenge.targetValue;
      final alreadyComplete = existing?.completedAt != null;
      if (reachedTarget && !alreadyComplete) {
        await _social.markProgressComplete(
          challengeId: challenge.id,
          uid: uid,
          completedAt: at,
        );
        completed.add(challenge.id);
        // A personal target has no opponent to out-drive, so hitting
        // the number finishes it. A head-to-head challenge stays active
        // until its window closes — the winner depends on the
        // opponent's value too, which this phase can't see.
        if (challenge.isPersonal) {
          await _social.updateChallengeStatus(
            challengeId: challenge.id,
            status: ChallengeStatus.completed,
          );
        }
      }

      updated.add(
        ChallengeProgress(
          challengeId: challenge.id,
          uid: uid,
          currentValue: value,
          targetValue: challenge.targetValue,
          lastCalculatedAt: at,
          completedAt: existing?.completedAt ?? (reachedTarget ? at : null),
        ),
      );
    }

    return TargetProgressRefresh(
      progress: updated,
      completedChallengeIds: completed,
    );
  }
}
