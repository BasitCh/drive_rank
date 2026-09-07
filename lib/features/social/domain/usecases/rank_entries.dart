import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';

/// Sorts by value descending and assigns 1-based ranks.
///
/// **Ties go to the real person.** A benchmark is a published target,
/// not a competitor, so matching it means you've reached it — being
/// ranked below it on an equal number would read as losing to a thing
/// that never drove anywhere. Two benchmarks on equal values fall back
/// to catalogue difficulty order so the ladder stays stable, and two
/// real people fall back to name so the order is at least deterministic.
///
/// Extracted from `GetGlobalLeaderboard` when the friends board arrived:
/// two boards ranking by two copies of this rule is two places for the
/// tie-breaking to drift, and the tie rule is the part a reader would
/// notice being wrong.
///
/// Rank is assigned here, after sorting, and never persisted.
List<LeaderboardPosition> rankEntries(List<LeaderboardEntry> entries) {
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
