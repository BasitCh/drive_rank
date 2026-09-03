import 'package:flutter/foundation.dart';

/// A fixed pace to measure yourself against on a sparse leaderboard.
///
/// **Not a user, and not pretending to be one.** Benchmarks exist so a
/// board with one real driver still reads like a ranking instead of an
/// empty screen. Every surface that shows one must label it as a
/// benchmark, and the names are deliberately descriptive
/// ("Road Warrior") rather than plausible personal names, so a
/// screenshot can never be mistaken for a real rival.
///
/// [value] is a compile-time constant from `benchmarkCatalog` — never
/// derived from, adjusted to, or influenced by the viewer's own
/// performance. A benchmark that moved with the user would be a fake
/// rival, and the whole point is that it isn't one.
@immutable
class Benchmark {
  const Benchmark({
    required this.id,
    required this.displayName,
    required this.value,
  });

  final String id;
  final String displayName;

  /// In the metric's own unit — kilometres for distance and longest
  /// trip, qualifying days for consistency.
  final double value;
}
