/// The one place benchmark values are defined.
///
/// Every value here is a hand-set constant, identical for every user on
/// every device, forever. Nothing in this file may read user data,
/// settings, locale, or the clock. If a value needs changing, change it
/// here deliberately and note why — silently tuning these would make
/// past screenshots and past trophies mean something different.
///
/// The six identities are shared across metrics and periods so a user
/// switching from weekly distance to monthly consistency still sees the
/// same cast in the same order, which makes the ladder legible: Road
/// Warrior is always the hardest pace, Weekend Cruiser always the
/// gentlest.
///
/// Values in kilometres for `distance` and `longestTrip`, and in
/// qualifying days for `consistency` (weekly caps at 7 by definition, so
/// the weekly consistency ladder is simply one benchmark per day count).
library;

import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';

const String benchmarkRoadWarrior = 'road_warrior';
const String benchmarkHighwayHunter = 'highway_hunter';
const String benchmarkRoadExplorer = 'road_explorer';
const String benchmarkDailyDriver = 'daily_driver';
const String benchmarkRoadRegular = 'road_regular';
const String benchmarkWeekendCruiser = 'weekend_cruiser';

/// Hardest first — the order benchmarks appear in when their values tie.
const List<String> benchmarkIdsByDifficulty = [
  benchmarkRoadWarrior,
  benchmarkHighwayHunter,
  benchmarkRoadExplorer,
  benchmarkDailyDriver,
  benchmarkRoadRegular,
  benchmarkWeekendCruiser,
];

const Map<String, String> benchmarkDisplayNames = {
  benchmarkRoadWarrior: AppStrings.benchmarkRoadWarrior,
  benchmarkHighwayHunter: AppStrings.benchmarkHighwayHunter,
  benchmarkRoadExplorer: AppStrings.benchmarkRoadExplorer,
  benchmarkDailyDriver: AppStrings.benchmarkDailyDriver,
  benchmarkRoadRegular: AppStrings.benchmarkRoadRegular,
  benchmarkWeekendCruiser: AppStrings.benchmarkWeekendCruiser,
};

/// Weekly distance (km). Road Warrior's 574 is the published headline
/// figure — roughly a long-haul week, well beyond a normal commute, so
/// topping it reads as a genuine achievement. The rest step down to a
/// couple of weekend outings.
const Map<String, double> _weeklyDistanceKm = {
  benchmarkRoadWarrior: 574,
  benchmarkHighwayHunter: 412,
  benchmarkRoadExplorer: 285,
  benchmarkDailyDriver: 190,
  benchmarkRoadRegular: 120,
  benchmarkWeekendCruiser: 75,
};

/// Monthly distance (km) — not a flat 4× the weekly figures: sustaining
/// a heavy week for a whole month is much rarer than having one, so the
/// top of the ladder is deliberately less than 4× while the bottom is
/// closer to it.
const Map<String, double> _monthlyDistanceKm = {
  benchmarkRoadWarrior: 2100,
  benchmarkHighwayHunter: 1500,
  benchmarkRoadExplorer: 1050,
  benchmarkDailyDriver: 700,
  benchmarkRoadRegular: 440,
  benchmarkWeekendCruiser: 260,
};

/// All-time distance (km). Sized so a committed user passes the lower
/// rungs within a few months and the top one stays a long-term goal
/// rather than something unreachable.
const Map<String, double> _allTimeDistanceKm = {
  benchmarkRoadWarrior: 12000,
  benchmarkHighwayHunter: 8000,
  benchmarkRoadExplorer: 5200,
  benchmarkDailyDriver: 3000,
  benchmarkRoadRegular: 1600,
  benchmarkWeekendCruiser: 800,
};

/// Weekly longest single trip (km) — a road-trip ladder rather than a
/// volume one, so the values are much lower than weekly totals.
const Map<String, double> _weeklyLongestTripKm = {
  benchmarkRoadWarrior: 214,
  benchmarkHighwayHunter: 158,
  benchmarkRoadExplorer: 112,
  benchmarkDailyDriver: 74,
  benchmarkRoadRegular: 45,
  benchmarkWeekendCruiser: 28,
};

/// Monthly longest single trip (km). Only modestly above the weekly
/// figures: a month gives more chances at a long drive, but the drive
/// itself doesn't get longer just because the window did.
const Map<String, double> _monthlyLongestTripKm = {
  benchmarkRoadWarrior: 320,
  benchmarkHighwayHunter: 240,
  benchmarkRoadExplorer: 165,
  benchmarkDailyDriver: 105,
  benchmarkRoadRegular: 62,
  benchmarkWeekendCruiser: 38,
};

/// All-time longest single trip (km) — a lifetime best, so this is the
/// "have you ever done a proper road trip" ladder.
const Map<String, double> _allTimeLongestTripKm = {
  benchmarkRoadWarrior: 640,
  benchmarkHighwayHunter: 430,
  benchmarkRoadExplorer: 300,
  benchmarkDailyDriver: 180,
  benchmarkRoadRegular: 110,
  benchmarkWeekendCruiser: 60,
};

/// Weekly consistency (qualifying days). Capped at 7 by definition, so
/// this is one benchmark per day count from a full week down to a
/// weekend.
const Map<String, double> _weeklyConsistencyDays = {
  benchmarkRoadWarrior: 7,
  benchmarkHighwayHunter: 6,
  benchmarkRoadExplorer: 5,
  benchmarkDailyDriver: 4,
  benchmarkRoadRegular: 3,
  benchmarkWeekendCruiser: 2,
};

/// Monthly consistency (qualifying days). 26 is near-daily without
/// demanding a perfect month, which no real driver manages.
const Map<String, double> _monthlyConsistencyDays = {
  benchmarkRoadWarrior: 26,
  benchmarkHighwayHunter: 22,
  benchmarkRoadExplorer: 18,
  benchmarkDailyDriver: 13,
  benchmarkRoadRegular: 9,
  benchmarkWeekendCruiser: 5,
};

/// All-time consistency (qualifying days) — total distinct driving days
/// ever, so this ladder rewards longevity rather than intensity.
const Map<String, double> _allTimeConsistencyDays = {
  benchmarkRoadWarrior: 240,
  benchmarkHighwayHunter: 160,
  benchmarkRoadExplorer: 110,
  benchmarkDailyDriver: 70,
  benchmarkRoadRegular: 40,
  benchmarkWeekendCruiser: 18,
};

/// The benchmarks for one metric over one period, hardest first.
///
/// Takes no user input by design — the only arguments are the board's
/// own coordinates, so the same call always returns the same values.
List<Benchmark> benchmarksFor({
  required CompetitionMetric metric,
  required LeaderboardPeriod period,
}) {
  final values = switch ((metric, period)) {
    (CompetitionMetric.distance, LeaderboardPeriod.weekly) =>
      _weeklyDistanceKm,
    (CompetitionMetric.distance, LeaderboardPeriod.monthly) =>
      _monthlyDistanceKm,
    (CompetitionMetric.distance, LeaderboardPeriod.allTime) =>
      _allTimeDistanceKm,
    (CompetitionMetric.longestTrip, LeaderboardPeriod.weekly) =>
      _weeklyLongestTripKm,
    (CompetitionMetric.longestTrip, LeaderboardPeriod.monthly) =>
      _monthlyLongestTripKm,
    (CompetitionMetric.longestTrip, LeaderboardPeriod.allTime) =>
      _allTimeLongestTripKm,
    (CompetitionMetric.consistency, LeaderboardPeriod.weekly) =>
      _weeklyConsistencyDays,
    (CompetitionMetric.consistency, LeaderboardPeriod.monthly) =>
      _monthlyConsistencyDays,
    (CompetitionMetric.consistency, LeaderboardPeriod.allTime) =>
      _allTimeConsistencyDays,
  };

  return [
    for (final id in benchmarkIdsByDifficulty)
      Benchmark(
        id: id,
        displayName: benchmarkDisplayNames[id]!,
        value: values[id]!,
      ),
  ];
}
