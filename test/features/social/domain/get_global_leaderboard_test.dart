import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_catalog.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_visibility_policy.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late GetGlobalLeaderboard getLeaderboard;

  const uid = 'user-1';
  const displayName = 'Basit';
  // A Thursday, so a weekly window has room either side.
  final now = DateTime(2026, 9, 3, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    getLeaderboard = GetGlobalLeaderboard(
      repo,
      const DefaultCompetitionMetricCalculator(),
    );
  });

  tearDown(() async => db.close());

  Future<int> addTrip({
    required double distanceKm,
    DateTime? startedAt,
    int durationSeconds = 900,
    bool? eligible,
  }) async {
    final start = startedAt ?? now.subtract(const Duration(hours: 2));
    final tripId = await db
        .into(db.trips)
        .insert(
          TripsCompanion.insert(
            uid: uid,
            topSpeedKmh: 90,
            avgSpeedKmh: 50,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            startedAt: start,
          ),
        );
    if (eligible != null) {
      await repo.recordTripEligibility(
        tripId: tripId,
        eligibility: eligible
            ? const CompetitionEligibility()
            : const CompetitionEligibility(
                reasons: [EligibilityFailureReason.mockLocationDetected],
                mockedSampleCount: 12,
              ),
        startedAt: start,
      );
    }
    return tripId;
  }

  Future<Leaderboard> board({
    CompetitionMetric metric = CompetitionMetric.distance,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    BenchmarkVisibilityPolicy policy = const BenchmarkVisibilityPolicy(),
  }) {
    return getLeaderboard(
      uid: uid,
      displayName: displayName,
      metric: metric,
      period: period,
      now: now,
      policy: policy,
    );
  }

  group('the viewer', () {
    test('is on the board even with no trips at all — a ranking that '
        'hides you until you qualify cannot tell you what to do next',
        () async {
      final result = await board();
      expect(result.me, isNotNull);
      expect(result.me!.entry.value, 0);
      expect(result.me!.entry.displayName, displayName);
      expect(result.me!.entry.isCurrentUser, isTrue);
      expect(
        result.me!.entry.participantType,
        LeaderboardParticipantType.realUser,
      );
    });

    test('is ranked last when they have driven nothing', () async {
      final result = await board();
      expect(result.me!.rank, result.positions.length);
    });

    test('climbs past benchmarks as their value grows', () async {
      await addTrip(distanceKm: 130);
      final result = await board();
      // 130 km beats the two gentlest weekly benchmarks (120, 75).
      expect(result.me!.rank, result.positions.length - 2);
    });

    test('tops the board once they beat every benchmark', () async {
      await addTrip(distanceKm: 600);
      final result = await board();
      expect(result.me!.rank, 1);
      expect(result.gapToNextAbove, isNull);
      expect(result.nextBelow, isNotNull);
    });

    test('value comes from eligible trips only — an ineligible trip must '
        'not move a ranking', () async {
      await addTrip(distanceKm: 200, eligible: false);
      final result = await board();
      expect(result.me!.entry.value, 0);
    });

    test('a trip with no eligibility verdict still counts', () async {
      await addTrip(distanceKm: 200);
      final result = await board();
      expect(result.me!.entry.value, 200);
    });

    test('trips outside the window do not count', () async {
      await addTrip(
        distanceKm: 400,
        startedAt: now.subtract(const Duration(days: 30)),
      );
      final result = await board();
      expect(result.me!.entry.value, 0);
    });
  });

  group('ranking', () {
    test('is ordered best first with contiguous 1-based ranks', () async {
      final result = await board();
      expect(result.positions.first.rank, 1);
      for (var i = 0; i < result.positions.length; i++) {
        expect(result.positions[i].rank, i + 1);
        if (i > 0) {
          expect(
            result.positions[i].entry.value,
            lessThanOrEqualTo(result.positions[i - 1].entry.value),
          );
        }
      }
    });

    test('a tie between the viewer and a benchmark goes to the viewer — '
        'matching a published target means reaching it, not losing to '
        'something that never drove anywhere', () async {
      // Exactly the Road Regular weekly figure.
      await addTrip(distanceKm: 120);
      final result = await board();

      final tied = result.positions.where((p) => p.entry.value == 120);
      expect(tied, hasLength(2));
      expect(tied.first.entry.isCurrentUser, isTrue);
      expect(tied.last.entry.isBenchmark, isTrue);
      expect(result.me!.rank, lessThan(tied.last.rank));
    });

    test('benchmarks tied with each other keep catalogue order', () async {
      final result = await board(metric: CompetitionMetric.consistency);
      final benchmarkIds = result.positions
          .where((p) => p.entry.isBenchmark)
          .map((p) => p.entry.id)
          .toList();
      expect(benchmarkIds, benchmarkIdsByDifficulty);
    });

    test('no rank is stored on an entry — it exists only as the position '
        "that placed it, so it cannot go stale or be a client's own "
        'claim', () async {
      final result = await board();
      // The entity simply has no rank field; the position wraps it.
      expect(result.positions.first.entry.value, isA<double>());
      expect(result.positions.first.rank, 1);
    });
  });

  group('benchmarks', () {
    test('appear on a board with only the viewer on it', () async {
      final result = await board();
      expect(result.benchmarksShown, isTrue);
      expect(
        result.positions.where((p) => p.entry.isBenchmark),
        hasLength(benchmarkIdsByDifficulty.length),
      );
    });

    test('every benchmark row is typed as a benchmark, never as a user',
        () async {
      final result = await board();
      for (final position in result.positions) {
        if (position.entry.isCurrentUser) continue;
        expect(
          position.entry.participantType,
          LeaderboardParticipantType.benchmark,
        );
      }
    });

    test('are omitted entirely once the policy retires them', () async {
      final result = await board(
        policy: const BenchmarkVisibilityPolicy(hiddenAtRealCompetitors: 1),
      );
      expect(result.benchmarksShown, isFalse);
      expect(result.positions.where((p) => p.entry.isBenchmark), isEmpty);
      // The viewer is then alone and therefore first.
      expect(result.positions, hasLength(1));
      expect(result.me!.rank, 1);
    });

    test('their values are identical no matter what the viewer has '
        "driven — this is the check that proves they aren't scaled to "
        'the user', () async {
      List<double> benchmarkValues(Leaderboard result) => result.positions
          .where((p) => p.entry.isBenchmark)
          .map((p) => p.entry.value)
          .toList();

      final atZero = benchmarkValues(await board());

      await addTrip(distanceKm: 5);
      final afterShortDrive = benchmarkValues(await board());

      await addTrip(distanceKm: 900);
      final afterHugeWeek = benchmarkValues(await board());

      await addTrip(distanceKm: 25000);
      final afterAbsurdWeek = benchmarkValues(await board());

      expect(afterShortDrive, atZero);
      expect(afterHugeWeek, atZero);
      expect(afterAbsurdWeek, atZero);
    });

    test('do not count toward the real-competitor total, so a board full '
        'of them still reports itself as sparse', () async {
      final result = await board();
      expect(result.realCompetitorCount, 1);
      expect(result.isSparse, isTrue);
      expect(result.positions.length, greaterThan(1));
    });
  });

  group('metrics and periods', () {
    test('every combination produces a ranked board with the viewer on '
        'it', () async {
      await addTrip(distanceKm: 42);
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          final result = await board(metric: metric, period: period);
          expect(
            result.me,
            isNotNull,
            reason: 'viewer missing from $metric/$period',
          );
          expect(result.positions.first.rank, 1);
        }
      }
    });

    test('longest trip takes the single best drive, not the total',
        () async {
      await addTrip(distanceKm: 30);
      await addTrip(distanceKm: 50);
      final distance = await board();
      final longest = await board(metric: CompetitionMetric.longestTrip);
      expect(distance.me!.entry.value, 80);
      expect(longest.me!.entry.value, 50);
    });

    test('consistency counts qualifying days', () async {
      await addTrip(distanceKm: 10, startedAt: DateTime(2026, 9, 1, 9));
      await addTrip(distanceKm: 10, startedAt: DateTime(2026, 9, 1, 18));
      await addTrip(distanceKm: 10, startedAt: DateTime(2026, 9, 2, 9));
      final result = await board(metric: CompetitionMetric.consistency);
      expect(result.me!.entry.value, 2);
    });

    test('a wider period can include trips a narrower one excludes',
        () async {
      await addTrip(
        distanceKm: 60,
        startedAt: DateTime(2026, 9, 1),
      );
      await addTrip(
        distanceKm: 40,
        // Earlier in the month, before this week began.
        startedAt: DateTime(2026, 8, 20),
      );
      final weekly = await board();
      final monthly = await board(period: LeaderboardPeriod.monthly);
      expect(weekly.me!.entry.value, 60);
      expect(monthly.me!.entry.value, 60);

      final allTime = await board(period: LeaderboardPeriod.allTime);
      expect(allTime.me!.entry.value, 100);
    });
  });

  group('gap helpers', () {
    test('report the distance to the position directly above', () async {
      await addTrip(distanceKm: 100);
      final result = await board();
      final above = result.nextAbove!;
      expect(above.rank, result.me!.rank - 1);
      expect(result.gapToNextAbove, above.entry.value - 100);
    });

    test('are null above the top of the board', () async {
      await addTrip(distanceKm: 5000);
      final result = await board();
      expect(result.nextAbove, isNull);
      expect(result.gapToNextAbove, isNull);
    });
  });
}
