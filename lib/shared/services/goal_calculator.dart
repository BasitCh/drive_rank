/// Pure "beat this next" goal math for the post-trip goal nudge and
/// retention-notification copy. No I/O, no DI — deliberately kept
/// side-effect-free so it's trivial to unit test and so `TrackingBloc`
/// (which calls it right after saving a trip) never has to await
/// anything extra to compute a goal.
///
/// Increments are round numbers, not a per-user-tuned formula: +5% for
/// speed, +30% for distance, both rounded to the nearest 5, with a
/// guaranteed minimum step so a goal is never "beat your best by
/// 0.1 km/h" when the growth percentage rounds down to nothing.
class GoalCalculator {
  const GoalCalculator._();

  static const double _speedGrowth = 1.05;
  static const double _distanceGrowth = 1.3;
  static const double _roundToKmh = 5;
  static const double _roundToKm = 5;

  /// Next speed goal given the user's current personal-best top speed.
  /// Returns 0 for a non-positive input (no trips yet — caller should
  /// treat 0 as "no goal", not display it).
  static double nextSpeedGoalKmh(double currentBestKmh) =>
      _nextGoal(currentBestKmh, _speedGrowth, _roundToKmh);

  /// Next distance goal given the longest single trip ever recorded.
  static double nextDistanceGoalKm(double currentBestKm) =>
      _nextGoal(currentBestKm, _distanceGrowth, _roundToKm);

  static double _nextGoal(double best, double growth, double roundTo) {
    if (best <= 0) return 0;
    final raw = best * growth;
    var rounded = (raw / roundTo).round() * roundTo;
    // The %-based target can round back down to (or below) the current
    // best for small values — always force at least one real step up.
    if (rounded <= best) rounded += roundTo;
    return rounded;
  }
}
