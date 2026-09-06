import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/compare_with_benchmark.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/compare_sheet.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserSettingsRow viewer() => UserSettingsRow(
    id: 1,
    uid: 'user-1',
    username: 'basit',
    carMake: 'BMW',
    carModel: 'M3',
    vehicleType: 'car',
    country: 'PK',
    unitSystem: 'metric',
    selectedMapTheme: 'regular',
    minTripLengthMeters: 500,
    freeTripsUsed: 0,
    isPro: false,
    rankingsEnabled: true,
    onboardingComplete: true,
    oemAdviceShown: false,
    bgLocationDisclosureAcked: true,
    createdAt: DateTime(2026),
  );

  BenchmarkComparison comparison({
    double distanceMine = 300,
    double longestMine = 212,
    double consistencyMine = 4,
  }) => BenchmarkComparison(
    benchmarkId: 'road_warrior',
    benchmarkName: 'Road Warrior',
    period: LeaderboardPeriod.weekly,
    rows: [
      ComparisonRow(
        metric: CompetitionMetric.distance,
        mine: distanceMine,
        theirs: 574,
      ),
      ComparisonRow(
        metric: CompetitionMetric.longestTrip,
        mine: longestMine,
        theirs: 180,
      ),
      ComparisonRow(
        metric: CompetitionMetric.consistency,
        mine: consistencyMine,
        theirs: 6,
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, BenchmarkComparison c) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompareSheet(
            comparison: c,
            periodLabel: 'This Week',
            metricLabel: (m) => switch (m) {
              CompetitionMetric.distance => 'Distance',
              CompetitionMetric.longestTrip => 'Longest Trip',
              CompetitionMetric.consistency => 'Consistency',
            },
            formatValue: (m, v) => m == CompetitionMetric.consistency
                ? '${v.round()} d'
                : '${v.round()} km',
            viewer: viewer(),
          ),
        ),
      ),
    );
  }

  testWidgets('puts every metric on the screen with both sides', (tester) async {
    await pump(tester, comparison());

    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('LONGEST TRIP'), findsOneWidget);
    expect(find.text('CONSISTENCY'), findsOneWidget);
    expect(find.text('300 km'), findsOneWidget); // mine
    expect(find.text('574 km'), findsOneWidget); // theirs
    expect(find.text('4 d'), findsOneWidget);
    expect(find.text('6 d'), findsOneWidget);
  });

  testWidgets('scores only the metrics actually led', (tester) async {
    // Longest trip is the only one ahead.
    await pump(tester, comparison());
    expect(find.text(AppStrings.compareScore(1, 3)), findsOneWidget);
  });

  testWidgets('says so plainly when nothing is led, rather than "0 of 3"',
      (tester) async {
    await pump(
      tester,
      comparison(distanceMine: 10, longestMine: 10, consistencyMine: 1),
    );
    expect(find.text(AppStrings.compareScoreNone), findsOneWidget);
  });

  testWidgets('celebrates a clean sweep', (tester) async {
    await pump(
      tester,
      comparison(distanceMine: 900, longestMine: 400, consistencyMine: 7),
    );
    expect(find.text(AppStrings.compareAllLed), findsOneWidget);
  });

  testWidgets('gives the viewer their car and the benchmark a badge, never '
      'an avatar — the rule does not relax because the screen got bigger',
      (tester) async {
    await pump(tester, comparison());

    // Exactly one car silhouette: the viewer's. The benchmark gets the
    // gauge glyph instead.
    expect(find.byType(CarSilhouette), findsOneWidget);
    expect(find.byType(BenchmarkBadge), findsOneWidget);
    expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
    expect(find.text('Road Warrior'), findsOneWidget);
    expect(find.text(AppStrings.compareYou), findsOneWidget);
  });

  testWidgets('shows the period it is comparing over', (tester) async {
    await pump(tester, comparison());
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('survives a metric where neither side has driven anything — '
      'a fresh week is zero against zero, not a divide by zero',
      (tester) async {
    await pump(
      tester,
      const BenchmarkComparison(
        benchmarkId: 'road_warrior',
        benchmarkName: 'Road Warrior',
        period: LeaderboardPeriod.weekly,
        rows: [
          ComparisonRow(
            metric: CompetitionMetric.distance,
            mine: 0,
            theirs: 0,
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.compareScoreNone), findsOneWidget);
  });
}
