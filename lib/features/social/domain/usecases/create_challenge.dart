import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Opens a head-to-head challenge against a friend.
///
/// **The window is `[now, period end)`, not the period's own window** —
/// and that is the one place this differs from `CreateTarget`, on
/// purpose.
///
/// `CompetitionWindow.forPeriod(weekly, …)` starts on Monday. A target
/// inheriting that is right: "this week" means this week, and the only
/// person affected is the one who set it. A *challenge* inheriting it
/// would be unfair in a way the opponent cannot see — the creator picks
/// the moment to challenge, so they would also be picking how much of
/// their own past driving to count. Somebody who has already driven
/// 200 km by Thursday could open a weekly challenge and start 200 ahead.
///
/// So the period decides the deadline; the clock decides the start. Both
/// people compete over exactly the same interval.
///
/// All-time is rejected for the same reason it makes no sense as a
/// contest: `CompetitionWindow.forPeriod` gives it no end, and a race
/// with no finish line cannot be settled.
///
/// Status is `pending` — unlike a target, somebody has to agree to this.
/// Acceptance is refused once the window has closed (see
/// `firestore.rules`), so an unanswered challenge lapses rather than
/// becoming a contest after the fact.
@injectable
class CreateChallenge {
  const CreateChallenge(this._social);

  final SocialRepository _social;

  Future<Challenge> call({
    required String creatorUid,
    required String opponentUid,
    required CompetitionMetric metric,
    required LeaderboardPeriod period,
    required double targetValue,
    DateTime? now,
  }) async {
    if (targetValue <= 0) {
      throw ArgumentError.value(
        targetValue,
        'targetValue',
        'A challenge must be above zero.',
      );
    }
    if (creatorUid == opponentUid) {
      throw ArgumentError.value(
        opponentUid,
        'opponentUid',
        'A challenge needs two different people.',
      );
    }

    final at = now ?? DateTime.now();
    final end = CompetitionWindow.forPeriod(period, at).end;
    if (end == null) {
      throw ArgumentError.value(
        period,
        'period',
        'An all-time challenge has no finish line to settle at.',
      );
    }
    if (!end.isAfter(at)) {
      // A period whose end has already passed leaves nothing to
      // compete over. Cannot happen with the current calendar
      // arithmetic, but a zero-length contest would settle instantly as
      // a draw and read as a bug.
      throw ArgumentError.value(
        period,
        'period',
        'That period has already closed.',
      );
    }

    return _social.createChallenge(
      Challenge(
        id: const Uuid().v4(),
        creatorUid: creatorUid,
        opponentUid: opponentUid,
        metric: metric,
        targetValue: targetValue,
        period: period,
        startAt: at,
        endAt: end,
        status: ChallengeStatus.pending,
        createdAt: at,
        updatedAt: at,
      ),
    );
  }
}
