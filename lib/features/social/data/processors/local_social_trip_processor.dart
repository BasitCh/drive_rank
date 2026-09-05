import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_update.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/evaluate_competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:drive_rank/features/social/domain/usecases/social_trip_processor.dart';
import 'package:drive_rank/features/social/domain/usecases/trophy_ids.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:injectable/injectable.dart';

/// Distance (km) inside one weekly window that earns `roadWarrior`.
/// Sized against the weekly distance benchmarks the rankings surface
/// will show, so the trophy means roughly "a benchmark-scale week".
const double kRoadWarriorWeeklyKm = 500;

/// Qualifying days inside one weekly window that earn `consistent` —
/// every day of the week.
const double kConsistentWeeklyDays = 7;

/// The uid the app uses before sign-in resolves. Social rows are not
/// written under it: `UserSettingsRepository.syncUid` rewrites
/// `trips.uid` when this collapses into a real account but leaves social
/// tables alone, so anything written here would be stranded *and* would
/// be re-earned under the real uid — a guaranteed double-award.
const String kLocalPlaceholderUid = 'local';

/// Local, client-computed implementation of [SocialTripProcessor].
///
/// **Recomputes rather than increments.** Every value is derived from
/// the trips currently in the window, so the paths that bypass the
/// trip-completion hook — a cloud restore, the debug seeder, a trip the
/// user deleted — can't leave a running total permanently wrong. The
/// cost is that a run must see all the data, which is why calls are
/// serialized below.
@LazySingleton(as: SocialTripProcessor)
class LocalSocialTripProcessor implements SocialTripProcessor {
  LocalSocialTripProcessor(
    this._social,
    this._calculator,
    this._refreshTargets,
  );

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  /// Shared with target creation so both agree on when a target counts
  /// as complete — see `RefreshTargetProgress`.
  final RefreshTargetProgress _refreshTargets;

  /// Serializes processing. Two trips saved back-to-back both arrive as
  /// unawaited read-modify-write passes, and the one that started first
  /// may not see the second trip yet — so without this the later write
  /// can persist a stale, lower value. A "skip if already running"
  /// mutex would be worse: it would silently drop the second trip.
  Future<void> _queue = Future.value();

  @override
  Future<CompetitionUpdate> processCompletedTrip({
    required int tripId,
    required String uid,
    required List<TripPoint> points,
    required double distanceKm,
    required int durationSeconds,
    required DateTime startedAt,
    String? tripRemoteId,
  }) {
    final result = _queue.then(
      (_) => _process(
        tripId: tripId,
        uid: uid,
        points: points,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        startedAt: startedAt,
        tripRemoteId: tripRemoteId,
      ),
    );
    // The queue itself must never hold an error, or one failed trip
    // would poison every later one. The caller still sees the failure
    // through the future returned below.
    _queue = _swallow(result);
    return result;
  }

  static Future<void> _swallow(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // Reported by whoever awaited `processCompletedTrip`.
    }
  }

  Future<CompetitionUpdate> _process({
    required int tripId,
    required String uid,
    required List<TripPoint> points,
    required double distanceKm,
    required int durationSeconds,
    required DateTime startedAt,
    String? tripRemoteId,
  }) async {
    final eligibility = evaluateCompetitionEligibility(
      points: points,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    );
    await _social.recordTripEligibility(
      tripId: tripId,
      eligibility: eligibility,
      startedAt: startedAt,
      tripRemoteId: tripRemoteId,
    );

    // Eligibility is keyed on the trip, so it's safe to record under any
    // uid. Everything below is keyed on the user, so it waits for a
    // real one.
    if (uid == kLocalPlaceholderUid) {
      return CompetitionUpdate.eligibilityOnly(
        tripId: tripId,
        uid: uid,
        eligibility: eligibility,
      );
    }

    final now = DateTime.now();
    final expired = await _expireLapsedChallenges(uid: uid, at: now);
    final refresh = await _refreshTargets(uid: uid, at: now);
    final progress = refresh.progress;
    final completed = refresh.completedChallengeIds;
    final trophies = await _awardTrophies(
      uid: uid,
      now: now,
      tripStartedAt: startedAt,
      completedChallengeIds: completed,
    );

    return CompetitionUpdate(
      tripId: tripId,
      uid: uid,
      eligibility: eligibility,
      updatedProgress: progress,
      completedChallengeIds: completed,
      expiredChallengeIds: expired,
      unlockedTrophies: trophies,
    );
  }

  /// Expire-on-touch: a challenge whose window closed only finds out the
  /// next time the user drives. There's no timer, so readers must treat
  /// `endAt <= now && active` as expired regardless of what's stored.
  Future<List<String>> _expireLapsedChallenges({
    required String uid,
    required DateTime at,
  }) async {
    final lapsed = await _social.getLapsedActiveChallenges(uid: uid, at: at);
    final expired = <String>[];
    for (final challenge in lapsed) {
      final changed = await _social.updateChallengeStatus(
        challengeId: challenge.id,
        status: ChallengeStatus.expired,
      );
      if (changed) expired.add(challenge.id);
    }
    return expired;
  }

  /// Awards the trophies whose inputs exist locally.
  ///
  /// The rest of `TrophyType` needs data this phase doesn't have:
  /// `firstChallenge`/`firstWin`/`rivalHunter` need an opponent's
  /// values, and `rankClimber` needs a ranking. They're awarded in the
  /// phases that introduce those.
  Future<List<Trophy>> _awardTrophies({
    required String uid,
    required DateTime now,
    required DateTime tripStartedAt,
    required List<String> completedChallengeIds,
  }) async {
    // Scoped to the week the trip was *attributed* to, not the week it
    // finished processing in. Those differ for a drive that starts
    // 23:50 on a Sunday: its distance lands in the closing week, so
    // checking the new one would never see it.
    final week = CompetitionWindow.forPeriod(
      LeaderboardPeriod.weekly,
      tripStartedAt,
    );
    final trips = await _social.getCompetitionTrips(uid: uid, window: week);
    final unlocked = <Trophy>[];

    Future<void> award(TrophyType type, {CompetitionWindow? window}) async {
      final trophy = await _social.awardTrophy(
        Trophy(
          // Deterministic, so a repeat award collides on the unique
          // index instead of inserting a second row.
          id: trophyRemoteId(type: type, uid: uid, window: window),
          uid: uid,
          type: type,
          unlockedAt: now,
        ),
      );
      if (trophy != null) unlocked.add(trophy);
    }

    final weeklyKm = _calculator.calculate(
      metric: CompetitionMetric.distance,
      trips: trips,
      window: week,
    );
    if (weeklyKm >= kRoadWarriorWeeklyKm) {
      await award(TrophyType.roadWarrior, window: week);
    }

    final weeklyDays = _calculator.calculate(
      metric: CompetitionMetric.consistency,
      trips: trips,
      window: week,
    );
    if (weeklyDays >= kConsistentWeeklyDays) {
      await award(TrophyType.consistent, window: week);
    }

    if (completedChallengeIds.isNotEmpty) {
      final anyPersonal = await _anyPersonalTarget(completedChallengeIds);
      // Lifetime trophy — no window, so its id is stable forever and
      // the second target the user finishes can't re-award it.
      if (anyPersonal) await award(TrophyType.firstTarget);
    }

    return unlocked;
  }

  Future<bool> _anyPersonalTarget(List<String> challengeIds) async {
    for (final id in challengeIds) {
      final challenge = await _social.getChallengeById(id);
      if (challenge != null && challenge.isPersonal) return true;
    }
    return false;
  }
}
