import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// One metric, both sides.
@immutable
class ComparisonRow {
  const ComparisonRow({
    required this.metric,
    required this.mine,
    required this.theirs,
  });

  final CompetitionMetric metric;
  final double mine;
  final double theirs;

  bool get iLead => mine > theirs;

  /// Where the pair sits on a shared 0..1 scale, so two bars drawn from
  /// opposite sides are comparable rather than each filling its own half.
  double get myShare {
    final total = mine + theirs;
    if (total <= 0) return 0;
    return mine / total;
  }
}

/// You against one benchmark, across every metric.
@immutable
class BenchmarkComparison {
  const BenchmarkComparison({
    required this.benchmarkId,
    required this.benchmarkName,
    required this.period,
    required this.rows,
  });

  final String benchmarkId;
  final String benchmarkName;
  final LeaderboardPeriod period;
  final List<ComparisonRow> rows;

  int get metricsLed => rows.where((r) => r.iLead).length;
  int get metricCount => rows.length;
}

/// Builds the head-to-head between the viewer and a benchmark.
///
/// Both sides are real: the viewer's figures come from the same
/// `CompetitionMetricCalculator` the board uses, and the benchmark's are
/// the published constants from `benchmarksFor`. Neither side is a mock,
/// and the benchmark's numbers are the same for every user on every
/// device — which is what keeps this a measurement rather than a staged
/// rivalry.
///
/// This is deliberately the shape a real opponent will take. When
/// friends arrive, their values replace the constants and nothing about
/// the screen has to change.
@injectable
class CompareWithBenchmark {
  const CompareWithBenchmark(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  /// Returns null for an id that isn't in the catalogue, rather than a
  /// row of zeroes — an unknown opponent has no published pace, and
  /// showing 0 would read as "they drove nothing".
  Future<BenchmarkComparison?> call({
    required String uid,
    required String benchmarkId,
    required LeaderboardPeriod period,
    DateTime? now,
  }) async {
    final name = benchmarkDisplayNames[benchmarkId];
    if (name == null) return null;

    final window = CompetitionWindow.forPeriod(period, now ?? DateTime.now());
    final trips = await _social.getCompetitionTrips(uid: uid, window: window);

    final rows = <ComparisonRow>[];
    for (final metric in CompetitionMetric.values) {
      final ladder = benchmarksFor(metric: metric, period: period);
      final theirs = ladder
          .where((b) => b.id == benchmarkId)
          .map((b) => b.value)
          .firstOrNull;
      // A benchmark can legitimately be absent from one metric's ladder
      // (weekly consistency caps at seven days, so its ladder is
      // shorter). Skipping keeps the comparison to metrics both sides
      // actually have a figure for.
      if (theirs == null) continue;

      rows.add(
        ComparisonRow(
          metric: metric,
          mine: _calculator.calculate(
            metric: metric,
            trips: trips,
            window: window,
          ),
          theirs: theirs,
        ),
      );
    }

    return BenchmarkComparison(
      benchmarkId: benchmarkId,
      benchmarkName: name,
      period: period,
      rows: rows,
    );
  }
}
