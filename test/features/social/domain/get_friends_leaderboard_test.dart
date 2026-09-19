import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_visibility_policy.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/get_friends_leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late GetFriendsLeaderboard board;

  const me = 'me-uid';
  final now = DateTime(2026, 9, 4, 12); // Friday

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    board = GetFriendsLeaderboard(
      repo,
      const DefaultCompetitionMetricCalculator(),
    );
  });

  tearDown(() async => db.close());

  Future<void> addTrip({required double distanceKm, int daysAgo = 2}) async {
    final start = now.subtract(Duration(days: daysAgo));
    final id = await db
        .into(db.trips)
        .insert(
          TripsCompanion.insert(
            uid: me,
            topSpeedKmh: 100,
            avgSpeedKmh: 60,
            distanceKm: distanceKm,
            durationSeconds: 3600,
            startedAt: start,
          ),
        );
    await repo.recordTripEligibility(
      tripId: id,
      eligibility: const CompetitionEligibility(),
      startedAt: start,
    );
  }

  CompetitionMirror friend({
    required String uid,
    String username = 'friend',
    double? weeklyDistance = 100,
    DateTime? publishedAt,
    bool omitField = false,
  }) => CompetitionMirror(
    uid: uid,
    username: username,
    carMake: 'BMW',
    carModel: 'M3',
    countryCode: 'PK',
    inviteCode: 'CODE1234',
    updatedAt: publishedAt ?? now.subtract(const Duration(hours: 1)),
    totals: {
      for (final metric in CompetitionMetric.values)
        for (final period in LeaderboardPeriod.values)
          (metric, period): omitField ? null : 0,
      if (!omitField)
        (CompetitionMetric.distance, LeaderboardPeriod.weekly):
            weeklyDistance,
    },
  );

  Future<Leaderboard> weeklyBoard(
    List<CompetitionMirror> friends, {
    BenchmarkVisibilityPolicy policy =
        const BenchmarkVisibilityPolicy.friends(),
  }) => board(
    uid: me,
    displayName: 'You',
    metric: CompetitionMetric.distance,
    period: LeaderboardPeriod.weekly,
    friendProfiles: friends,
    now: now,
    policy: policy,
  );

  test("the viewer's own value is computed from local trips, never read "
      'back from what they published — a stale snapshot of yourself must '
      'not decide your own rank', () async {
    await addTrip(distanceKm: 250);

    // Their own mirror claims something completely different; it must be
    // ignored for their own row.
    final result = await weeklyBoard([
      friend(uid: me, username: 'stale-me', weeklyDistance: 9999),
    ]);

    expect(result.me!.entry.value, 250);
  });

  test('a friend ranks on the figure they published', () async {
    await addTrip(distanceKm: 100);
    final result = await weeklyBoard([
      friend(uid: 'bob', username: 'bob', weeklyDistance: 300),
    ]);

    final bob = result.positions.firstWhere((p) => p.entry.id == 'bob');
    expect(bob.entry.value, 300);
    expect(bob.rank, lessThan(result.me!.rank));
  });

  test('a friend who never published that metric is omitted, not ranked '
      'at zero — absent is silence, not a claim that they drove nothing',
      () async {
    await addTrip(distanceKm: 100);

    final result = await weeklyBoard([
      friend(uid: 'ghost', username: 'ghost', omitField: true),
    ]);

    expect(result.positions.any((p) => p.entry.id == 'ghost'), isFalse);
    expect(result.realCompetitorCount, 1);
  });

  test('a friend who genuinely published a zero IS ranked, at zero — '
      'that is a real figure they reported', () async {
    await addTrip(distanceKm: 100);

    final result = await weeklyBoard([
      friend(uid: 'idle', username: 'idle', weeklyDistance: 0),
    ]);

    final idle = result.positions.firstWhere((p) => p.entry.id == 'idle');
    expect(idle.entry.value, 0);
    expect(result.realCompetitorCount, 2);
  });

  test('a stale figure is marked and still ranks — a friend dropping off '
      'the board because their phone was off reads as a bug', () async {
    await addTrip(distanceKm: 100);

    final result = await weeklyBoard([
      friend(
        uid: 'quiet',
        username: 'quiet',
        weeklyDistance: 400,
        publishedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);

    final quiet = result.positions.firstWhere((p) => p.entry.id == 'quiet');
    expect(quiet.entry.isStale, isTrue);
    expect(
      quiet.rank,
      lessThan(result.me!.rank),
      reason: 'still ranks on its value, above the viewer',
    );
  });

  test('a fresh figure is not marked', () async {
    await addTrip(distanceKm: 100);
    final result = await weeklyBoard([
      friend(uid: 'bob', publishedAt: now.subtract(const Duration(hours: 3))),
    ]);
    expect(
      result.positions.firstWhere((p) => p.entry.id == 'bob').entry.isStale,
      isFalse,
    );
  });

  test('a friend carries their country and car so the row can name them, '
      'and a benchmark carries neither', () async {
    await addTrip(distanceKm: 100);
    final result = await weeklyBoard([friend(uid: 'bob')]);

    final bob = result.positions.firstWhere((p) => p.entry.id == 'bob');
    expect(bob.entry.countryCode, 'PK');
    expect(bob.entry.carMake, 'BMW');
    expect(bob.entry.hasPublishedIdentity, isTrue);

    final benchmark = result.positions.firstWhere((p) => p.entry.isBenchmark);
    expect(benchmark.entry.countryCode, isEmpty);
    expect(benchmark.entry.carMake, isEmpty);
    expect(benchmark.entry.hasPublishedIdentity, isFalse);
  });

  test('ranks are assigned after sorting, best first', () async {
    await addTrip(distanceKm: 200);
    final result = await weeklyBoard([
      friend(uid: 'a', username: 'a', weeklyDistance: 50),
      friend(uid: 'b', username: 'b', weeklyDistance: 500),
    ]);

    final values = result.positions.map((p) => p.entry.value).toList();
    final descending = [...values]..sort((x, y) => y.compareTo(x));
    expect(values, descending);
    expect(result.positions.first.rank, 1);
    expect(result.positions.last.rank, result.positions.length);
  });

  test('benchmarks stay while the board is thin, and retire on their own '
      'once enough friends are on it — the scope has its own threshold '
      'because ten friends who all publish is not a board that ever '
      'arrives', () async {
    await addTrip(distanceKm: 100);

    final thin = await weeklyBoard([friend(uid: 'bob')]);
    expect(thin.benchmarksShown, isTrue);

    // The viewer plus three friends: a ranking in its own right.
    final crowded = await weeklyBoard([
      for (var i = 0; i < 3; i++) friend(uid: 'f$i', username: 'f$i'),
    ]);
    expect(crowded.realCompetitorCount, 4);
    expect(crowded.benchmarksShown, isFalse);
    expect(crowded.positions.any((p) => p.entry.isBenchmark), isFalse);
  });

  test('a friend omitted for want of a figure does not count towards '
      'retiring the benchmarks — the board is as thin as it looks',
      () async {
    await addTrip(distanceKm: 100);

    final result = await weeklyBoard([
      for (var i = 0; i < 3; i++)
        friend(uid: 'f$i', username: 'f$i', omitField: true),
    ]);

    expect(result.realCompetitorCount, 1);
    expect(result.benchmarksShown, isTrue);
  });

  test('with no friends the viewer is still on their own board rather '
      'than facing an empty list', () async {
    await addTrip(distanceKm: 100);
    final result = await weeklyBoard([]);

    expect(result.me, isNotNull);
    expect(result.realCompetitorCount, 1);
    expect(result.isSparse, isTrue);
  });
}
