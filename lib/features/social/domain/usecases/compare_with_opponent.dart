import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/opponent.dart';
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

/// You against one opponent, across every metric they have a figure for.
@immutable
class Comparison {
  const Comparison({
    required this.opponent,
    required this.period,
    required this.rows,
  });

  final Opponent opponent;
  final LeaderboardPeriod period;
  final List<ComparisonRow> rows;

  int get metricsLed => rows.where((r) => r.iLead).length;
  int get metricCount => rows.length;
}

/// Builds the head-to-head between the viewer and one opponent.
///
/// The viewer's side is always the same: figures from the very
/// `CompetitionMetricCalculator` the board uses, recomputed from local
/// trips. What varies is the other side —
///
///  * a **benchmark** contributes published constants, identical on
///    every device for every user, which is what keeps that comparison
///    a measurement rather than a staged rivalry;
///  * a **friend** contributes the snapshot their own device published.
///    Self-reported, as the whole of this phase's trust model is, and
///    carrying its publication time so the sheet can say when it's old.
///
/// Both go through one path so the two can't drift apart: the row maths,
/// the shared 0..1 scale, and the "you lead 2 of 3" score are computed
/// once and know nothing about which kind of opponent they got.
@injectable
class CompareWithOpponent {
  const CompareWithOpponent(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  /// Returns null for an id that isn't in the catalogue, rather than a
  /// row of zeroes — an unknown opponent has no published pace, and
  /// showing 0 would read as "they drove nothing".
  Future<Comparison?> againstBenchmark({
    required String uid,
    required String benchmarkId,
    required LeaderboardPeriod period,
    DateTime? now,
  }) async {
    final name = benchmarkDisplayNames[benchmarkId];
    if (name == null) return null;

    return _build(
      uid: uid,
      period: period,
      now: now,
      opponent: Opponent.benchmark(id: benchmarkId, displayName: name),
      // A benchmark can legitimately be absent from one metric's ladder
      // (weekly consistency caps at seven days, so its ladder is
      // shorter). Returning null skips that metric, keeping the sheet to
      // metrics both sides actually have a figure for.
      theirValueFor: (metric) => benchmarksFor(metric: metric, period: period)
          .where((b) => b.id == benchmarkId)
          .map((b) => b.value)
          .firstOrNull,
    );
  }

  /// The same comparison against a friend's published mirror.
  ///
  /// A metric the friend never published is skipped for the same reason
  /// the board omits them from it: absent is silence, not a claim that
  /// they drove nothing. A friend who published everything exercises all
  /// three rows, which no benchmark ladder does.
  Future<Comparison?> againstFriend({
    required String uid,
    required CompetitionMirror friend,
    required LeaderboardPeriod period,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    return _build(
      uid: uid,
      period: period,
      now: at,
      opponent: Opponent.person(
        id: friend.uid,
        displayName: friend.username.isEmpty ? friend.uid : friend.username,
        countryCode: friend.countryCode,
        carMake: friend.carMake,
        carModel: friend.carModel,
        publishedAt: friend.updatedAt,
        isStale: friend.isStaleAt(at),
      ),
      theirValueFor: (metric) => friend.hasTotalFor(metric, period)
          ? friend.totalFor(metric, period)
          : null,
    );
  }

  Future<Comparison> _build({
    required String uid,
    required LeaderboardPeriod period,
    required DateTime? now,
    required Opponent opponent,
    required double? Function(CompetitionMetric) theirValueFor,
  }) async {
    final window = CompetitionWindow.forPeriod(period, now ?? DateTime.now());
    final trips = await _social.getCompetitionTrips(uid: uid, window: window);

    final rows = <ComparisonRow>[];
    for (final metric in CompetitionMetric.values) {
      final theirs = theirValueFor(metric);
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

    return Comparison(opponent: opponent, period: period, rows: rows);
  }
}
