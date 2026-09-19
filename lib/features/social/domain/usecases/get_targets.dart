import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:injectable/injectable.dart';

/// The user's personal targets, each with its progress recomputed now.
///
/// Head-to-head challenges are filtered out: they need an opponent's
/// value to mean anything, and nothing can supply one yet.
///
/// The value is derived rather than read from `challenge_progress`, so
/// a target set *after* the driving already reflects it. The persisted
/// `completedAt` is still trusted for completion, because that's a fact
/// about the past — deleting a trip later can push the live value back
/// under the target, and that must not un-finish a finished target.
@injectable
class GetTargets {
  const GetTargets(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  Future<List<Target>> call({required String uid}) async {
    final challenges = await _social.watchChallenges(uid).first;
    final targets = <Target>[];

    for (final challenge in challenges) {
      if (!challenge.isPersonal) continue;
      if (challenge.status == ChallengeStatus.cancelled ||
          challenge.status == ChallengeStatus.declined) {
        continue;
      }

      // Scored over the window the challenge stored, never one
      // re-derived from its period — those disagree for any target that
      // didn't start on a period boundary.
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
      final progress = await _social.getProgress(
        challengeId: challenge.id,
        uid: uid,
      );

      targets.add(
        Target(
          challenge: challenge,
          currentValue: value,
          completedAt: progress?.completedAt,
        ),
      );
    }

    // Active first, then most recently created — the thing you're
    // chasing matters more than the thing you finished.
    targets.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
      return b.challenge.createdAt.compareTo(a.challenge.createdAt);
    });
    return targets;
  }
}
