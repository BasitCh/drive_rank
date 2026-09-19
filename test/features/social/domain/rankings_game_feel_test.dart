import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_tier.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/compare_with_opponent.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/get_qualifying_days.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BenchmarkTier', () {
    BenchmarkTier tierFor(double value) => BenchmarkTier.forValue(
      value: value,
      metric: CompetitionMetric.distance,
      period: LeaderboardPeriod.weekly,
    );

    test('a value below the gentlest pace has cleared nothing, and is '
        'pointed at the gentlest one', () {
      final tier = tierFor(10);
      expect(tier.cleared, 0);
      expect(tier.total, 6);
      expect(tier.isTopped, isFalse);
      expect(tier.nextValue, 75); // Weekend Cruiser, the gentlest
    });

    test('clearing the ladder tops it out and names nothing further', () {
      final tier = tierFor(10000);
      expect(tier.cleared, 6);
      expect(tier.isTopped, isTrue);
      expect(tier.nextName, isNull);
      expect(tier.nextValue, isNull);
    });

    test('matching a benchmark exactly counts as clearing it — a target '
        'you reached is a target you met, which is the same rule that '
        'gives ties to the real person on the board', () {
      // Exactly Road Regular's 120, on top of Weekend Cruiser's 75.
      final tier = tierFor(120);
      expect(tier.cleared, 2);
      expect(tier.nextValue, 190); // Daily Driver is next
    });

    test('the next target is always the cheapest one still ahead', () {
      final tier = tierFor(300);
      // Cleared 75 / 120 / 190 / 285; Highway Hunter's 412 is next, not
      // Road Warrior's 574.
      expect(tier.cleared, 4);
      expect(tier.nextValue, 412);
    });

    test('the ladder is the same size on every metric and period, so '
        '"3 of 6" means one thing', () {
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          final tier = BenchmarkTier.forValue(
            value: 0,
            metric: metric,
            period: period,
          );
          expect(tier.total, greaterThan(0), reason: '$metric/$period');
        }
      }
    });
  });

  group('CompetitionWindow.countdownAt', () {
    test('a weekly window reports the days left and its final day', () {
      // Friday 2026-09-04; the week runs Mon 31 Aug → Sun 6 Sep.
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 4, 18),
      );
      final countdown = window.countdownAt(DateTime(2026, 9, 4, 18))!;
      expect(countdown.daysLeft, 2);
      expect(countdown.endsAfter, DateTime(2026, 9, 6));
    });

    test('the final day reads as ending today rather than going '
        'negative', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 6, 23, 30),
      );
      expect(window.countdownAt(DateTime(2026, 9, 6, 23, 30))!.daysLeft, 0);
    });

    test('a monthly window counts to the end of the month', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.monthly,
        DateTime(2026, 9, 6),
      );
      final countdown = window.countdownAt(DateTime(2026, 9, 6))!;
      expect(countdown.endsAfter, DateTime(2026, 9, 30));
      expect(countdown.daysLeft, 24);
    });

    test('all-time has no countdown — there is no deadline to invent', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.allTime,
        DateTime(2026, 9, 6),
      );
      expect(window.countdownAt(DateTime(2026, 9, 6)), isNull);
    });
  });

  group('with a database', () {
    late AppDatabase db;
    late SocialRepositoryImpl repo;
    late GetQualifyingDays qualifyingDays;
    late CompareWithOpponent compare;

    const uid = 'user-1';
    final now = DateTime(2026, 9, 4, 12); // Friday
    final window = CompetitionWindow.forPeriod(
      LeaderboardPeriod.weekly,
      DateTime(2026, 9, 4, 12),
    );

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = SocialRepositoryImpl(SocialLocalDataSource(db));
      qualifyingDays = GetQualifyingDays(repo);
      compare = CompareWithOpponent(
        repo,
        const DefaultCompetitionMetricCalculator(),
      );
    });

    tearDown(() async => db.close());

    Future<int> addTrip({
      required DateTime startedAt,
      double distanceKm = 20,
      int durationSeconds = 1800,
      bool eligible = true,
    }) async {
      final id = await db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: uid,
              topSpeedKmh: 90,
              avgSpeedKmh: 50,
              distanceKm: distanceKm,
              durationSeconds: durationSeconds,
              startedAt: startedAt,
            ),
          );
      await repo.recordTripEligibility(
        tripId: id,
        eligibility: eligible
            ? const CompetitionEligibility()
            : const CompetitionEligibility(
                reasons: [EligibilityFailureReason.mockLocationDetected],
              ),
        startedAt: startedAt,
      );
      return id;
    }

    int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

    group('GetQualifyingDays', () {
      test('returns the days that actually had a qualifying drive', () async {
        await addTrip(startedAt: DateTime(2026, 8, 31, 8)); // Monday
        await addTrip(startedAt: DateTime(2026, 9, 2, 19)); // Wednesday

        final days = await qualifyingDays(uid: uid, window: window);
        expect(days, {
          dayKey(DateTime(2026, 8, 31)),
          dayKey(DateTime(2026, 9, 2)),
        });
      });

      test('two drives on one day count once — this measures days driven, '
          'not drives taken', () async {
        await addTrip(startedAt: DateTime(2026, 9, 2, 8));
        await addTrip(startedAt: DateTime(2026, 9, 2, 18));

        expect(await qualifyingDays(uid: uid, window: window), hasLength(1));
      });

      test('ignores ineligible trips and sub-threshold ones, so the strip '
          'can never disagree with the consistency metric', () async {
        await addTrip(
          startedAt: DateTime(2026, 9, 1, 8),
          eligible: false,
        );
        // Under the 1 km / 5 minute qualification bar.
        await addTrip(
          startedAt: DateTime(2026, 9, 3, 8),
          distanceKm: 0.4,
          durationSeconds: 120,
        );

        expect(await qualifyingDays(uid: uid, window: window), isEmpty);
      });

      test('a drive from last week is outside the window', () async {
        await addTrip(startedAt: DateTime(2026, 8, 30, 12)); // Sunday before
        expect(await qualifyingDays(uid: uid, window: window), isEmpty);
      });
    });

    group('CompareWithOpponent — against a benchmark', () {
      test('puts both sides on every metric the benchmark publishes',
          () async {
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 300);

        final result = await compare.againstBenchmark(
          uid: uid,
          benchmarkId: 'road_warrior',
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result, isNotNull);
        expect(result!.opponent.displayName, 'Road Warrior');
        expect(result.opponent.isBenchmark, isTrue);
        expect(result.rows, isNotEmpty);
        final distance = result.rows.firstWhere(
          (r) => r.metric == CompetitionMetric.distance,
        );
        expect(distance.mine, 300);
        expect(distance.theirs, 574);
        expect(distance.iLead, isFalse);
      });

      test('the score counts only the metrics actually led', () async {
        // Beats the gentlest benchmark on distance, not on consistency.
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 400);

        final result = await compare.againstBenchmark(
          uid: uid,
          benchmarkId: 'weekend_cruiser',
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.metricsLed, lessThan(result.metricCount));
        expect(
          result.rows
              .firstWhere((r) => r.metric == CompetitionMetric.distance)
              .iLead,
          isTrue,
        );
      });

      test('an unknown opponent returns null rather than a row of zeroes — '
          'no published pace is not the same as a pace of nothing',
          () async {
        final result = await compare.againstBenchmark(
          uid: uid,
          benchmarkId: 'someone_who_does_not_exist',
          period: LeaderboardPeriod.weekly,
          now: now,
        );
        expect(result, isNull);
      });

      test('the shared scale puts a losing side below half', () async {
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 100);

        final result = await compare.againstBenchmark(
          uid: uid,
          benchmarkId: 'road_warrior',
          period: LeaderboardPeriod.weekly,
          now: now,
        );
        final distance = result!.rows.firstWhere(
          (r) => r.metric == CompetitionMetric.distance,
        );
        expect(distance.myShare, lessThan(0.5));
        expect(distance.myShare, closeTo(100 / 674, 0.001));
      });
    });

    group('CompareWithOpponent — against a friend', () {
      CompetitionMirror friend({
        Map<(CompetitionMetric, LeaderboardPeriod), double?>? totals,
        DateTime? updatedAt,
      }) => CompetitionMirror(
        uid: 'bob-uid',
        username: 'bob',
        carMake: 'Toyota',
        carModel: 'Corolla',
        countryCode: 'PK',
        inviteCode: 'CODE1234',
        updatedAt: updatedAt ?? now.subtract(const Duration(hours: 2)),
        totals:
            totals ??
            {
              (CompetitionMetric.distance, LeaderboardPeriod.weekly): 200,
              (CompetitionMetric.longestTrip, LeaderboardPeriod.weekly): 80,
              (CompetitionMetric.consistency, LeaderboardPeriod.weekly): 3,
            },
      );

      test('a friend who published everything fills all three rows — the '
          'first opponent to exercise the whole sheet, since a weekly '
          'consistency ladder is shorter than the metric set', () async {
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 300);

        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(),
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.rows, hasLength(CompetitionMetric.values.length));
        final distance = result.rows.firstWhere(
          (r) => r.metric == CompetitionMetric.distance,
        );
        expect(distance.mine, 300);
        expect(distance.theirs, 200);
        expect(distance.iLead, isTrue);
      });

      test('the opponent carries their identity, so the sheet can show '
          'their car and flag where a benchmark shows a glyph', () async {
        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(),
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.opponent.isBenchmark, isFalse);
        expect(result.opponent.displayName, 'bob');
        expect(result.opponent.countryCode, 'PK');
        expect(result.opponent.carMake, 'Toyota');
      });

      test('a metric the friend never published is skipped, not compared '
          'against zero — the sheet would otherwise award the viewer a '
          'win over a figure that was never reported', () async {
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 300);

        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(
            totals: const {
              (CompetitionMetric.distance, LeaderboardPeriod.weekly): 200,
            },
          ),
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.rows, hasLength(1));
        expect(result.rows.single.metric, CompetitionMetric.distance);
        expect(result.metricsLed, 1);
        expect(result.metricCount, 1);
      });

      test('the score counts only the metrics actually led', () async {
        // Ahead on distance, behind on consistency.
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 300);

        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(),
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.metricsLed, lessThan(result.metricCount));
        expect(
          result.rows
              .firstWhere((r) => r.metric == CompetitionMetric.consistency)
              .iLead,
          isFalse,
        );
      });

      test('an old snapshot is marked on the opponent, and still compared '
          '— the numbers are the truest thing the app knows about them',
          () async {
        await addTrip(startedAt: DateTime(2026, 9, 2), distanceKm: 300);

        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(updatedAt: now.subtract(const Duration(days: 6))),
          period: LeaderboardPeriod.weekly,
          now: now,
        );

        expect(result!.opponent.isStale, isTrue);
        expect(result.rows, isNotEmpty);
      });

      test('a fresh snapshot is not marked', () async {
        final result = await compare.againstFriend(
          uid: uid,
          friend: friend(),
          period: LeaderboardPeriod.weekly,
          now: now,
        );
        expect(result!.opponent.isStale, isFalse);
      });
    });
  });
}
