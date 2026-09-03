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

@immutable
class BenchmarkVisibilityPolicy {
  const BenchmarkVisibilityPolicy({
    this.hiddenAtRealCompetitors = kBenchmarkHiddenAtRealCompetitors,
  });

  final int hiddenAtRealCompetitors;

  /// Whether to show benchmarks on a board with [realCompetitors] real
  /// people on it (the viewer included).
  ///
  /// Today that count is always 1 — nothing publishes other users'
  /// values yet — so benchmarks always show. The policy takes the count
  /// as an argument anyway so that when real competitors do arrive,
  /// benchmarks retire on their own with no UI change.
  bool showBenchmarks({required int realCompetitors}) =>
      realCompetitors < hiddenAtRealCompetitors;
}
