import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/rank_change.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:injectable/injectable.dart';

/// The rank movement one trip actually caused.
///
/// Builds the board twice — as it stands, and again with this trip
/// excluded — and diffs the viewer's position. Nothing is stored, which
/// is what makes the answer honest: the movement reported is the
/// movement attributable to *this* trip, and it recomputes to the same
/// value when the trip is reopened from History months later.
///
/// Returns null when there's nothing to say, so the card can be absent
/// rather than announce "+0 places".
@injectable
class GetTripRankChange {
  const GetTripRankChange(this._leaderboard);

  final GetGlobalLeaderboard _leaderboard;

  Future<RankChange?> call({
    required int tripId,
    required String uid,
    required String displayName,
    CompetitionMetric metric = CompetitionMetric.distance,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();

    final withTrip = await _leaderboard(
      uid: uid,
      displayName: displayName,
      metric: metric,
      period: period,
      now: at,
    );
    final withoutTrip = await _leaderboard(
      uid: uid,
      displayName: displayName,
      metric: metric,
      period: period,
      now: at,
      excludeTripId: tripId,
    );

    final after = withTrip.me;
    final before = withoutTrip.me;
    if (after == null || before == null) return null;
    if (after.rank >= before.rank) return null;

    // Everyone sitting between the two positions is someone this trip
    // overtook. Named rather than counted, so the copy can say who.
    final passed = withoutTrip.positions
        .where((p) => p.rank >= after.rank && p.rank < before.rank)
        .where((p) => !p.entry.isCurrentUser)
        .map((p) => p.entry.displayName)
        .toList(growable: false);

    return RankChange(
      metric: metric,
      period: period,
      previousRank: before.rank,
      newRank: after.rank,
      passedNames: passed,
    );
  }
}
