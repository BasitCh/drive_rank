import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:flutter/foundation.dart';

/// A placed row: an entry plus the rank it earned by its value.
@immutable
class LeaderboardPosition {
  const LeaderboardPosition({required this.rank, required this.entry});

  /// 1-based.
  final int rank;
  final LeaderboardEntry entry;
}

/// A ranked board for one metric over one period.
///
/// All the "how am I doing" arithmetic the UI needs lives here as
/// derived getters, so no widget re-derives it and no two surfaces can
/// disagree about the gap to the next position.
@immutable
class Leaderboard {
  const Leaderboard({
    required this.positions,
    required this.realCompetitorCount,
    required this.benchmarksShown,
  });

  /// Best first.
  final List<LeaderboardPosition> positions;

  /// How many real people are on this board — the input the benchmark
  /// visibility policy is keyed on. Counts people, not rows, so
  /// benchmarks can never make a board look populated.
  final int realCompetitorCount;

  final bool benchmarksShown;

  /// The viewer's row. Always present on a global board — the user is on
  /// their own leaderboard even with no trips yet.
  LeaderboardPosition? get me =>
      positions.where((p) => p.entry.isCurrentUser).firstOrNull;

  /// The row directly above the viewer, or null when they're first.
  LeaderboardPosition? get nextAbove {
    final mine = me;
    if (mine == null || mine.rank <= 1) return null;
    return positions.where((p) => p.rank == mine.rank - 1).firstOrNull;
  }

  /// The row directly below the viewer — who they're defending against
  /// when they're already on top.
  LeaderboardPosition? get nextBelow {
    final mine = me;
    if (mine == null) return null;
    return positions.where((p) => p.rank == mine.rank + 1).firstOrNull;
  }

  /// How much more the viewer needs to overtake [nextAbove], or null
  /// when there's nobody above them.
  double? get gapToNextAbove {
    final mine = me;
    final above = nextAbove;
    if (mine == null || above == null) return null;
    return above.entry.value - mine.entry.value;
  }

  /// True when the viewer is the only real competitor here — drives the
  /// "you're one of the first drivers" framing instead of an empty
  /// board, which would read as broken.
  bool get isSparse => realCompetitorCount <= 1;
}
