/// When benchmark entries appear on a board.
///
/// Keyed on the number of **active real competitors** on that specific
/// board — one metric, one period, one scope — not on how many users the
/// app has. A board can be crowded on weekly distance and empty on
/// all-time consistency, and each should decide for itself.
///
/// Benchmarks exist only to keep a sparse board from reading as broken,
/// so they retire as soon as there are enough real people to rank
/// against. Centralised here so no widget ever hardcodes the condition.
library;

import 'package:flutter/foundation.dart';

/// Once a board has this many real competitors, benchmarks stop showing.
///
/// Ten is enough for a ranking to feel populated — a "nearby" view has
/// people both above and below the viewer — while being low enough that
/// benchmarks disappear early rather than lingering as decoration.
const int kBenchmarkHiddenAtRealCompetitors = 10;

/// The same threshold for a **friends** board, which fills up far more
/// slowly.
///
/// Ten is right for a global board, where the population is everyone;
/// on a friends board it would mean benchmarks effectively never retire,
/// because ten friends who all publish is a lot of friends. Four — the
/// viewer plus three people they chose — is a ranking in its own right,
/// and past that a published constant standing between two friends is
/// clutter rather than a pace.
const int kBenchmarkHiddenAtFriendCompetitors = 4;

@immutable
class BenchmarkVisibilityPolicy {
  const BenchmarkVisibilityPolicy({
    this.hiddenAtRealCompetitors = kBenchmarkHiddenAtRealCompetitors,
  });

  /// The policy for a friends-scoped board.
  const BenchmarkVisibilityPolicy.friends()
    : hiddenAtRealCompetitors = kBenchmarkHiddenAtFriendCompetitors;

  final int hiddenAtRealCompetitors;

  /// Whether to show benchmarks on a board with [realCompetitors] real
  /// people on it (the viewer included).
  ///
  /// On the global board that count is still always 1 — nothing ranks
  /// strangers, and widening the mirror's read rule to do so is exactly
  /// the change not to make. On the friends board it is the viewer plus
  /// however many friends published a figure, so benchmarks retire on
  /// their own there with no UI change at all.
  bool showBenchmarks({required int realCompetitors}) =>
      realCompetitors < hiddenAtRealCompetitors;
}
