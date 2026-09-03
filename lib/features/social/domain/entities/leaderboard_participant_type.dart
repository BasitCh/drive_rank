/// What kind of thing occupies a leaderboard position.
///
/// Every entry states this explicitly rather than leaving it to be
/// inferred, because the UI has to be able to label a benchmark as one:
/// a benchmark is a published pace to measure yourself against, never a
/// person, and must never be presentable as one.
enum LeaderboardParticipantType {
  realUser,
  benchmark;

  static LeaderboardParticipantType fromName(String name) =>
      LeaderboardParticipantType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => realUser,
      );
}
