import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';

/// Where a value sits on the benchmark ladder.
///
/// This invents no mechanic. The six benchmarks are already ordered by
/// difficulty in `benchmarkIdsByDifficulty`, so "how many have you
/// cleared" is a fact about a ladder that has existed since Phase 3a —
/// it was simply never named on screen. Nothing is stored: like every
/// other aggregate in this feature, it is recomputed from the value in
/// front of you.
///
/// Deliberately not a "level" or "XP" system. Those would need their own
/// progression rules, their own persistence, and their own decisions
/// about what happens when a week resets; this needs none of that,
/// because it is a reading of the board rather than a second game
/// running alongside it.
@immutable
class BenchmarkTier {
  const BenchmarkTier({
    required this.cleared,
    required this.total,
    this.nextName,
    this.nextValue,
  });

  /// Reads [value] against the published ladder for [metric]/[period].
  ///
  /// **Matching a benchmark exactly counts as clearing it**, matching
  /// `GetGlobalLeaderboard._rank`, where a tie goes to the real person:
  /// a benchmark is a target, so reaching it means you got there.
  factory BenchmarkTier.forValue({
    required double value,
    required CompetitionMetric metric,
    required LeaderboardPeriod period,
  }) {
    final ladder = benchmarksFor(metric: metric, period: period);
    if (ladder.isEmpty) {
      return const BenchmarkTier(cleared: 0, total: 0);
    }

    // Catalogue order is hardest first; walk it easiest first so the
    // "next" one is the cheapest target still ahead.
    final easiestFirst = ladder.reversed.toList();
    var cleared = 0;
    for (final benchmark in easiestFirst) {
      if (value >= benchmark.value) {
        cleared += 1;
      } else {
        return BenchmarkTier(
          cleared: cleared,
          total: ladder.length,
          nextName: benchmark.displayName,
          nextValue: benchmark.value,
        );
      }
    }
    return BenchmarkTier(cleared: cleared, total: ladder.length);
  }

  /// How many benchmarks this value has reached or passed.
  final int cleared;

  /// How many there are on this metric and period — always the full
  /// ladder, so `3 / 6` means the same thing on every board.
  final int total;

  /// The next one up, or null once the whole ladder is cleared.
  final String? nextName;
  final double? nextValue;

  bool get isTopped => cleared >= total;

}
