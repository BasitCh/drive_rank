import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/rank_change.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:drive_rank/features/social/domain/usecases/get_trip_rank_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late GetTripRankChange getRankChange;

  const uid = 'user-1';
  const displayName = 'Basit';
  final now = DateTime(2026, 9, 3, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    getRankChange = GetTripRankChange(
      GetGlobalLeaderboard(repo, const DefaultCompetitionMetricCalculator()),
    );
  });

  tearDown(() async => db.close());

  Future<int> addTrip({
    required double distanceKm,
    DateTime? startedAt,
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
            durationSeconds: 900,
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
              ),
        startedAt: start,
      );
    }
    return tripId;
  }

  Future<RankChange?> changeFor(int tripId) => getRankChange(
    tripId: tripId,
    uid: uid,
    displayName: displayName,
    now: now,
  );

  test('a trip that overtakes benchmarks reports the climb and names '
      'who was passed', () async {
    // Weekly distance benchmarks: 574, 412, 285, 190, 120, 75.
    // Without the trip the user is at 0 and last (#7).
    final tripId = await addTrip(distanceKm: 130);

    final change = await changeFor(tripId);
    expect(change, isNotNull);
    expect(change!.previousRank, 7);
    // 130 beats Road Regular (120) and Weekend Cruiser (75).
    expect(change.newRank, 5);
    expect(change.positionsMoved, 2);
    expect(change.improved, isTrue);
    expect(change.passedNames, ['Road Regular', 'Weekend Cruiser']);
  });

  test('a trip that changes nothing returns null rather than "+0 '
      'places"', () async {
    // 10 km beats no benchmark, so the user stays last either way.
    final tripId = await addTrip(distanceKm: 10);
    expect(await changeFor(tripId), isNull);
  });

  test('an ineligible trip reports no movement — it never counted', () async {
    final tripId = await addTrip(distanceKm: 400, eligible: false);
    expect(await changeFor(tripId), isNull);
  });

  test('a trip outside the window reports no movement', () async {
    final tripId = await addTrip(
      distanceKm: 400,
      startedAt: now.subtract(const Duration(days: 30)),
    );
    expect(await changeFor(tripId), isNull);
  });

  test('the movement is attributable to this trip alone — other trips in '
      'the window are present in both boards, so they cannot inflate it',
      () async {
    await addTrip(distanceKm: 100); // already banked
    final tripId = await addTrip(distanceKm: 30); // pushes 100 -> 130

    final change = await changeFor(tripId);
    // Without this trip the user is on 100 (rank 6, past Weekend
    // Cruiser only); with it they're on 130 and also past Road Regular.
    expect(change!.previousRank, 6);
    expect(change.newRank, 5);
    expect(change.positionsMoved, 1);
    expect(change.passedNames, ['Road Regular']);
  });

  test('a first-ever trip that beats the whole ladder reports the full '
      'climb to the top', () async {
    final tripId = await addTrip(distanceKm: 600);

    final change = await changeFor(tripId);
    expect(change!.previousRank, 7);
    expect(change.newRank, 1);
    expect(change.positionsMoved, 6);
    expect(change.passedNames, hasLength(6));
    expect(change.passedNames.first, 'Road Warrior');
  });

  test('the answer is recomputed against the board as it stands, so '
      'deleting another trip changes it — the honest trade-off of not '
      'storing a snapshot', () async {
    final other = await addTrip(distanceKm: 100);
    final tripId = await addTrip(distanceKm: 500);

    // 100 + 500 = 600 clears Road Warrior (574), so with this trip the
    // user is first; without it they're on 100, at #6.
    final before = await changeFor(tripId);
    expect(before!.previousRank, 6);
    expect(before.newRank, 1);

    await (db.delete(db.trips)..where((t) => t.id.equals(other))).go();

    // Now the same trip is all the user has: 500 falls short of Road
    // Warrior, so it wins #2 from last place. Different numbers,
    // because the board really is different — and still only ever the
    // positions this trip's own distance earns.
    final after = await changeFor(tripId);
    expect(after!.previousRank, 7);
    expect(after.newRank, 2);
    expect(after.improved, isTrue);
    expect(after.passedNames, isNot(contains('Road Warrior')));
  });

  test('carries the metric and period it was measured on', () async {
    final tripId = await addTrip(distanceKm: 130);
    final change = await changeFor(tripId);
    expect(change!.metric.name, 'distance');
    expect(change.period.name, 'weekly');
  });
}
