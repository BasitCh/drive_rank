import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_visibility_policy.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('benchmarksFor', () {
    test('every metric and period has a full ladder', () {
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          final benchmarks = benchmarksFor(metric: metric, period: period);
          expect(
            benchmarks,
            hasLength(benchmarkIdsByDifficulty.length),
            reason: 'missing benchmarks for $metric/$period',
          );
          expect(
            benchmarks.map((b) => b.id),
            benchmarkIdsByDifficulty,
            reason: 'wrong order for $metric/$period',
          );
        }
      }
    });

    test('values descend from hardest to gentlest, with no ties', () {
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          final values = benchmarksFor(metric: metric, period: period)
              .map((b) => b.value)
              .toList();
          for (var i = 1; i < values.length; i++) {
            expect(
              values[i],
              lessThan(values[i - 1]),
              reason: '$metric/$period is not strictly descending: $values',
            );
          }
        }
      }
    });

    test('every value is positive and finite', () {
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          for (final benchmark in benchmarksFor(
            metric: metric,
            period: period,
          )) {
            expect(benchmark.value, greaterThan(0));
            expect(benchmark.value.isFinite, isTrue);
          }
        }
      }
    });

    test('weekly consistency never asks for more days than a week has — '
        'a benchmark nobody could ever reach is not a pace, it is a '
        'wall', () {
      final weekly = benchmarksFor(
        metric: CompetitionMetric.consistency,
        period: LeaderboardPeriod.weekly,
      );
      for (final benchmark in weekly) {
        expect(benchmark.value, lessThanOrEqualTo(7));
      }
    });

    test('monthly consistency stays inside a short month', () {
      final monthly = benchmarksFor(
        metric: CompetitionMetric.consistency,
        period: LeaderboardPeriod.monthly,
      );
      for (final benchmark in monthly) {
        expect(benchmark.value, lessThanOrEqualTo(28));
      }
    });

    test('the published weekly-distance headline figure is 574 km', () {
      final weekly = benchmarksFor(
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.weekly,
      );
      expect(weekly.first.id, benchmarkRoadWarrior);
      expect(weekly.first.value, 574);
    });

    test('names are descriptive, never plausible personal names — a '
        'benchmark must not be mistakable for a real rival', () {
      for (final name in benchmarkDisplayNames.values) {
        expect(name.split(' ').length, greaterThanOrEqualTo(2));
      }
    });

    test('longer periods never ask for less than shorter ones', () {
      for (final metric in CompetitionMetric.values) {
        for (final id in benchmarkIdsByDifficulty) {
          double valueFor(LeaderboardPeriod period) =>
              benchmarksFor(metric: metric, period: period)
                  .firstWhere((b) => b.id == id)
                  .value;

          expect(
            valueFor(LeaderboardPeriod.monthly),
            greaterThanOrEqualTo(valueFor(LeaderboardPeriod.weekly)),
            reason: '$metric/$id shrinks from weekly to monthly',
          );
          expect(
            valueFor(LeaderboardPeriod.allTime),
            greaterThanOrEqualTo(valueFor(LeaderboardPeriod.monthly)),
            reason: '$metric/$id shrinks from monthly to all-time',
          );
        }
      }
    });
  });

  group('immutability — the load-bearing property', () {
    test('repeated lookups return byte-identical values, so a benchmark '
        'can never drift between two reads', () {
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          final first = benchmarksFor(metric: metric, period: period);
          final second = benchmarksFor(metric: metric, period: period);
          expect(
            second.map((b) => b.value).toList(),
            first.map((b) => b.value).toList(),
          );
          expect(
            second.map((b) => b.displayName).toList(),
            first.map((b) => b.displayName).toList(),
          );
        }
      }
    });

    test('the published values are pinned to exact numbers, so making '
        'them dynamic — scaled to the viewer, tuned by a remote config, '
        'anything — fails here rather than shipping quietly', () {
      // The catalogue's signature admits no user data at all, which is
      // the real guarantee; this snapshot is what catches someone
      // widening it later. See get_global_leaderboard_test for the
      // varying-user-value version of this check.
      expect(
        benchmarksFor(
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
        ).map((b) => b.value).toList(),
        [574.0, 412.0, 285.0, 190.0, 120.0, 75.0],
      );
      expect(
        benchmarksFor(
          metric: CompetitionMetric.consistency,
          period: LeaderboardPeriod.weekly,
        ).map((b) => b.value).toList(),
        [7.0, 6.0, 5.0, 4.0, 3.0, 2.0],
      );
    });

    test('no two metric/period combinations share a value table by '
        'accident', () {
      final seen = <String, List<double>>{};
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          seen['$metric/$period'] = benchmarksFor(
            metric: metric,
            period: period,
          ).map((b) => b.value).toList();
        }
      }
      // Distance and longest-trip ladders must not be the same numbers;
      // if they were, one of the tables was copy-pasted.
      expect(
        seen['${CompetitionMetric.distance}/${LeaderboardPeriod.weekly}'],
        isNot(
          seen['${CompetitionMetric.longestTrip}/${LeaderboardPeriod.weekly}'],
        ),
      );
    });
  });

  group('BenchmarkVisibilityPolicy', () {
    const policy = BenchmarkVisibilityPolicy();

    test('shows benchmarks on a board with only the viewer on it', () {
      expect(policy.showBenchmarks(realCompetitors: 1), isTrue);
    });

    test('keeps showing them while the board is still thin', () {
      expect(policy.showBenchmarks(realCompetitors: 3), isTrue);
      expect(
        policy.showBenchmarks(
          realCompetitors: kBenchmarkHiddenAtRealCompetitors - 1,
        ),
        isTrue,
      );
    });

    test('retires them once there are enough real competitors', () {
      expect(
        policy.showBenchmarks(
          realCompetitors: kBenchmarkHiddenAtRealCompetitors,
        ),
        isFalse,
      );
      expect(policy.showBenchmarks(realCompetitors: 500), isFalse);
    });

    test('the threshold is configurable without touching call sites', () {
      const strict = BenchmarkVisibilityPolicy(hiddenAtRealCompetitors: 2);
      expect(strict.showBenchmarks(realCompetitors: 1), isTrue);
      expect(strict.showBenchmarks(realCompetitors: 2), isFalse);
    });
  });
}
