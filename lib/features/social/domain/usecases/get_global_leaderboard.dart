import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_visibility_policy.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:injectable/injectable.dart';

/// Builds the global board for one metric over one period.
///
/// Today the only real competitor is the viewer — nothing publishes
/// anyone else's values — so the board is the viewer plus whatever
/// benchmarks the visibility policy allows. When real competitors do
/// arrive, they join `entries` and the benchmarks retire on their own.
///
/// Rank is assigned here, after sorting, and never persisted.
@injectable
class GetGlobalLeaderboard {
  const GetGlobalLeaderboard(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  Future<Leaderboard> call({
    required String uid,
    required String displayName,
    required CompetitionMetric metric,
    required LeaderboardPeriod period,
    DateTime? now,
    BenchmarkVisibilityPolicy policy = const BenchmarkVisibilityPolicy(),
  }) async {
    final window = CompetitionWindow.forPeriod(period, now ?? DateTime.now());
    final trips = await _social.getCompetitionTrips(uid: uid, window: window);
    final myValue = _calculator.calculate(
      metric: metric,
      trips: trips,
      window: window,
    );

    final me = LeaderboardEntry(
      id: uid,
      displayName: displayName,
      value: myValue,
      participantType: LeaderboardParticipantType.realUser,
      isCurrentUser: true,
    );

    // The viewer is always on their own board, even at zero — a board
    // that hides you until you qualify can't tell you what to do next.
    final realCompetitors = [me];
    final showBenchmarks = policy.showBenchmarks(
      realCompetitors: realCompetitors.length,
    );

    final entries = [
      ...realCompetitors,
      if (showBenchmarks)
        for (final benchmark in benchmarksFor(metric: metric, period: period))
          LeaderboardEntry(
            id: benchmark.id,
            displayName: benchmark.displayName,
            value: benchmark.value,
            participantType: LeaderboardParticipantType.benchmark,
          ),
    ];

    return Leaderboard(
      positions: _rank(entries),
      realCompetitorCount: realCompetitors.length,
      benchmarksShown: showBenchmarks,
    );
  }

  /// Sorts by value descending and assigns 1-based ranks.
  ///
  /// **Ties go to the real person.** A benchmark is a published target,
  /// not a competitor, so matching it means you've reached it — being
  /// ranked below it on an equal number would read as losing to a thing
  /// that never drove anywhere. Two benchmarks on equal values fall back
  /// to catalogue difficulty order so the ladder stays stable.
  List<LeaderboardPosition> _rank(List<LeaderboardEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        if (byValue != 0) return byValue;
        if (a.isBenchmark != b.isBenchmark) return a.isBenchmark ? 1 : -1;
        if (a.isBenchmark && b.isBenchmark) {
          return benchmarkIdsByDifficulty
              .indexOf(a.id)
              .compareTo(benchmarkIdsByDifficulty.indexOf(b.id));
        }
        return a.displayName.compareTo(b.displayName);
      });

    return [
      for (var i = 0; i < sorted.length; i++)
        LeaderboardPosition(rank: i + 1, entry: sorted[i]),
    ];
  }
}
