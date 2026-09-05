import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Creates a personal target and brings its progress up to date at once.
///
/// **This is the only place a target's window is decided.** Callers pick
/// a [LeaderboardPeriod] and nothing more — the dates come from
/// `CompetitionWindow.forPeriod`, the same factory the calculators and
/// the leaderboard use. A UI that computed its own `now + 7 days` would
/// eventually disagree with them about when a week starts and would
/// drift by an hour across a DST boundary.
///
/// The window is the *current* period's, which means a weekly target
/// created late on a Sunday inherits a window with very little left in
/// it. That's deliberate — "this week" means this week — so the
/// creation UI shows the deadline it's about to inherit rather than
/// letting it come as a surprise.
///
/// Progress is refreshed immediately after the write, so a target set
/// after the driving shows what's already been done instead of zero
/// until the next drive — and one that's already been met is stamped
/// complete on the spot.
@injectable
class CreateTarget {
  const CreateTarget(this._social, this._refreshProgress);

  final SocialRepository _social;
  final RefreshTargetProgress _refreshProgress;

  Future<Challenge> call({
    required String uid,
    required CompetitionMetric metric,
    required LeaderboardPeriod period,
    required double targetValue,
    DateTime? now,
  }) async {
    if (targetValue <= 0) {
      throw ArgumentError.value(
        targetValue,
        'targetValue',
        'A target must be above zero.',
      );
    }

    final at = now ?? DateTime.now();
    final window = CompetitionWindow.forPeriod(period, at);

    final created = await _social.createChallenge(
      Challenge(
        id: const Uuid().v4(),
        creatorUid: uid,
        metric: metric,
        targetValue: targetValue,
        period: period,
        startAt: window.start,
        // An open-ended window (all-time) still needs a concrete end to
        // store. A target you can never fail isn't a target, so all-time
        // targets are scoped to the end of the current year — chosen
        // here, once, rather than invented by a caller.
        endAt: window.end ?? DateTime(at.year + 1),
        // Active immediately: a target is self-imposed, so there's
        // nobody to accept it.
        status: ChallengeStatus.active,
        createdAt: at,
        updatedAt: at,
      ),
    );

    await _refreshProgress(uid: uid, at: at);
    return created;
  }
}
