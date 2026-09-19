/// The time window a competition metric is aggregated over.
///
/// Standalone (not colocated with `Challenge`) since it's shared by
/// challenges now and by the leaderboard entities a later phase adds.
enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime;

  static LeaderboardPeriod fromName(String name) => LeaderboardPeriod.values
      .firstWhere((p) => p.name == name, orElse: () => weekly);
}
