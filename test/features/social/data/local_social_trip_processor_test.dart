import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/processors/local_social_trip_processor.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_update.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late LocalSocialTripProcessor processor;

  const uid = 'user-1';
  // A Thursday, mid-week, so a weekly window has room on both sides.
  final tripStart = DateTime(2026, 9, 3, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    processor = LocalSocialTripProcessor(
      repo,
      const DefaultCompetitionMetricCalculator(),
      RefreshTargetProgress(repo, const DefaultCompetitionMetricCalculator()),
    );
  });

  tearDown(() async => db.close());

  /// A clean 1 Hz drive that passes every eligibility rule.
  List<TripPoint> cleanPoints({DateTime? from, bool isMocked = false}) {
    final base = from ?? tripStart;
    return [
      for (var i = 0; i < 30; i++)
        TripPoint(
          lat: 31.5 + i * 0.000135,
          lng: 74.3,
          speedKmh: 54,
          accuracyMeters: 8,
          timestamp: base.add(Duration(seconds: i)),
          isMocked: isMocked,
        ),
    ];
  }

  Future<int> saveTrip({
    DateTime? startedAt,
    double distanceKm = 10,
    int durationSeconds = 600,
  }) {
    return db
        .into(db.trips)
        .insert(
          TripsCompanion.insert(
            uid: uid,
            topSpeedKmh: 90,
            avgSpeedKmh: 54,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            startedAt: startedAt ?? tripStart,
            remoteId: Value(const Uuid().v4()),
          ),
        );
  }

  Future<Challenge> createTarget({
    double targetValue = 20,
    CompetitionMetric metric = CompetitionMetric.distance,
    String? opponentUid,
    DateTime? startAt,
    DateTime? endAt,
    ChallengeStatus status = ChallengeStatus.active,
  }) {
    final created = DateTime(2026, 9);
    return repo.createChallenge(
      Challenge(
        id: const Uuid().v4(),
        creatorUid: uid,
        opponentUid: opponentUid,
        metric: metric,
        targetValue: targetValue,
        period: LeaderboardPeriod.weekly,
        startAt: startAt ?? DateTime(2026, 8, 31),
        endAt: endAt ?? DateTime(2026, 9, 7),
        status: status,
        createdAt: created,
        updatedAt: created,
      ),
    );
  }

  Future<CompetitionUpdate> process(
    int tripId, {
    String user = uid,
    List<TripPoint>? points,
  }) {
    return processor.processCompletedTrip(
      tripId: tripId,
      uid: user,
      points: points ?? cleanPoints(),
      distanceKm: 10,
      durationSeconds: 600,
      startedAt: tripStart,
    );
  }

  group('eligibility', () {
    test('records a verdict for a clean trip', () async {
      final tripId = await saveTrip();
      final update = await process(tripId);

      expect(update.eligibility.eligible, isTrue);
      final stored = await repo.getTripEligibility(tripId);
      expect(stored, isNotNull);
      expect(stored!.eligible, isTrue);
    });

    test('records the failure reasons for a spoofed trip, and the trip '
        'itself stays in the database — recorded and leaderboard-eligible '
        'are separate decisions', () async {
      final tripId = await saveTrip();
      await process(tripId, points: cleanPoints(isMocked: true));

      final stored = await repo.getTripEligibility(tripId);
      expect(stored!.eligible, isFalse);
      expect(
        stored.reasons,
        contains(EligibilityFailureReason.mockLocationDetected),
      );
      expect(stored.mockedSampleCount, 30);
      expect(await db.select(db.trips).get(), hasLength(1));
    });

    test('reprocessing the same trip replaces its verdict rather than '
        'inserting a second one', () async {
      final tripId = await saveTrip();
      await process(tripId, points: cleanPoints(isMocked: true));
      await process(tripId);

      expect(await db.select(db.tripEligibility).get(), hasLength(1));
      final stored = await repo.getTripEligibility(tripId);
      expect(stored!.eligible, isTrue);
    });

    test('an ineligible trip is excluded from challenge progress', () async {
      final target = await createTarget();
      final tripId = await saveTrip();
      await process(tripId, points: cleanPoints(isMocked: true));

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 0);
    });
  });

  group("the pre-auth 'local' uid", () {
    test('gets an eligibility record but no per-user rows — those would '
        'be stranded when syncUid rewrites the trips to a real account, '
        'and then re-earned under it', () async {
      final target = await createTarget();
      final tripId = await db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: kLocalPlaceholderUid,
              topSpeedKmh: 90,
              avgSpeedKmh: 54,
              distanceKm: 600,
              durationSeconds: 600,
              startedAt: tripStart,
            ),
          );

      final update = await process(tripId, user: kLocalPlaceholderUid);

      expect(await repo.getTripEligibility(tripId), isNotNull);
      expect(update.updatedProgress, isEmpty);
      expect(update.unlockedTrophies, isEmpty);
      expect(
        await repo.getProgress(challengeId: target.id, uid: uid),
        isNull,
      );
      expect(await repo.getTrophies(kLocalPlaceholderUid), isEmpty);
    });
  });

  group('challenge progress', () {
    test('recomputes the tally from the trips in the challenge window', () async {
      final target = await createTarget(targetValue: 50);
      await process(await saveTrip(distanceKm: 10));
      await process(await saveTrip(distanceKm: 15));

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 25);
      expect(progress.completedAt, isNull);
    });

    test('reprocessing the same trip twice does not double-count — the '
        'engine recomputes rather than increments, which is what makes '
        'the restore and debug-seed paths safe', () async {
      final target = await createTarget(targetValue: 50);
      final tripId = await saveTrip(distanceKm: 10);
      await process(tripId);
      await process(tripId);

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 10);
    });

    test('ignores trips outside the challenge window', () async {
      final target = await createTarget(targetValue: 50);
      await process(await saveTrip(distanceKm: 10));
      // Same challenge, a trip from the following week.
      final laterTripId = await saveTrip(
        distanceKm: 90,
        startedAt: DateTime(2026, 9, 10),
      );
      await processor.processCompletedTrip(
        tripId: laterTripId,
        uid: uid,
        points: cleanPoints(from: DateTime(2026, 9, 10)),
        distanceKm: 90,
        durationSeconds: 600,
        startedAt: DateTime(2026, 9, 10),
      );

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 10);
    });

    test('two overlapping challenges both update', () async {
      final distanceTarget = await createTarget(targetValue: 100);
      final longestTarget = await createTarget(
        targetValue: 100,
        metric: CompetitionMetric.longestTrip,
      );
      await process(await saveTrip(distanceKm: 12));

      expect(
        (await repo.getProgress(challengeId: distanceTarget.id, uid: uid))!
            .currentValue,
        12,
      );
      expect(
        (await repo.getProgress(challengeId: longestTarget.id, uid: uid))!
            .currentValue,
        12,
      );
    });

    test('completing a personal target stamps completion and closes the '
        'challenge', () async {
      final target = await createTarget(targetValue: 10);
      final update = await process(await saveTrip(distanceKm: 12));

      expect(update.completedChallengeIds, [target.id]);
      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.completedAt, isNotNull);
      final challenge = await repo.getChallengeById(target.id);
      expect(challenge!.status, ChallengeStatus.completed);
    });

    test('a head-to-head challenge stays active when the user hits the '
        'target — the winner depends on the opponent too', () async {
      final challenge = await createTarget(
        targetValue: 10,
        opponentUid: 'user-2',
      );
      await process(await saveTrip(distanceKm: 12));

      final stored = await repo.getChallengeById(challenge.id);
      expect(stored!.status, ChallengeStatus.active);
      final progress = await repo.getProgress(
        challengeId: challenge.id,
        uid: uid,
      );
      expect(progress!.completedAt, isNotNull);
    });

    test('completion survives a recompute that lowers the tally — a '
        'deleted trip must not un-complete a challenge already met. Uses '
        'a head-to-head challenge because that stays active after the '
        'target is hit (the winner still depends on the opponent), so it '
        'keeps recomputing', () async {
      final challenge = await createTarget(
        targetValue: 10,
        opponentUid: 'user-2',
      );
      final bigTripId = await saveTrip(distanceKm: 12);
      await process(bigTripId);

      final completedAt = (await repo.getProgress(
        challengeId: challenge.id,
        uid: uid,
      ))!
          .completedAt;
      expect(completedAt, isNotNull);

      // The user deletes the trip that got them there, then drives a
      // shorter one.
      await (db.delete(db.trips)..where((t) => t.id.equals(bigTripId))).go();
      await process(await saveTrip(distanceKm: 2));

      final progress = await repo.getProgress(
        challengeId: challenge.id,
        uid: uid,
      );
      expect(progress!.currentValue, 2);
      expect(progress.completedAt, completedAt);
    });

    test('a completed personal target is frozen entirely — it stops '
        'recomputing, so deleting the trip that finished it cannot '
        'rewrite the historical result', () async {
      final target = await createTarget(targetValue: 10);
      final bigTripId = await saveTrip(distanceKm: 12);
      await process(bigTripId);

      await (db.delete(db.trips)..where((t) => t.id.equals(bigTripId))).go();
      await process(await saveTrip(distanceKm: 2));

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 12);
      expect(progress.completedAt, isNotNull);
      final stored = await repo.getChallengeById(target.id);
      expect(stored!.status, ChallengeStatus.completed);
    });

    test('a challenge that already completed is not reported as newly '
        'completed again', () async {
      await createTarget(targetValue: 5);
      final first = await process(await saveTrip(distanceKm: 6));
      expect(first.completedChallengeIds, hasLength(1));

      // The challenge is closed now, so a later trip finds nothing
      // active to update.
      final second = await process(await saveTrip(distanceKm: 6));
      expect(second.completedChallengeIds, isEmpty);
    });

    test('a pending challenge is untouched — only accepted ones accrue '
        'progress', () async {
      final pending = await createTarget(status: ChallengeStatus.pending);
      await process(await saveTrip(distanceKm: 12));

      expect(
        await repo.getProgress(challengeId: pending.id, uid: uid),
        isNull,
      );
      final stored = await repo.getChallengeById(pending.id);
      expect(stored!.status, ChallengeStatus.pending);
    });

    test('consistency progress counts qualifying days', () async {
      final target = await createTarget(
        targetValue: 7,
        metric: CompetitionMetric.consistency,
      );
      await process(await saveTrip(startedAt: DateTime(2026, 9, 1, 8)));
      await process(await saveTrip(startedAt: DateTime(2026, 9, 1, 19)));
      await process(await saveTrip(startedAt: DateTime(2026, 9, 2, 8)));

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 2);
    });
  });

  group('expiry', () {
    test('an active challenge whose window has closed expires on the next '
        'trip', () async {
      final lapsed = await createTarget(
        startAt: DateTime(2026, 8, 1),
        endAt: DateTime(2026, 8, 8),
      );
      final update = await process(await saveTrip());

      expect(update.expiredChallengeIds, [lapsed.id]);
      final stored = await repo.getChallengeById(lapsed.id);
      expect(stored!.status, ChallengeStatus.expired);
    });

    test('an expired challenge is never revived or re-reported', () async {
      final lapsed = await createTarget(
        startAt: DateTime(2026, 8, 1),
        endAt: DateTime(2026, 8, 8),
      );
      await process(await saveTrip());
      final second = await process(await saveTrip());

      expect(second.expiredChallengeIds, isEmpty);
      final stored = await repo.getChallengeById(lapsed.id);
      expect(stored!.status, ChallengeStatus.expired);
    });
  });

  group('trophies', () {
    test('roadWarrior unlocks once a weekly distance threshold is passed, '
        'and only once for that week', () async {
      final first = await process(
        await saveTrip(distanceKm: kRoadWarriorWeeklyKm + 1),
      );
      expect(
        first.unlockedTrophies.map((Trophy t) => t.type),
        contains(TrophyType.roadWarrior),
      );

      final second = await process(await saveTrip(distanceKm: 10));
      expect(second.unlockedTrophies, isEmpty);
      expect(await repo.getTrophies(uid), hasLength(1));
    });

    test('roadWarrior is not awarded below the threshold', () async {
      final update = await process(await saveTrip(distanceKm: 10));
      expect(update.unlockedTrophies, isEmpty);
    });

    test('a weekly trophy is scoped to the week the trip was attributed '
        'to, not the week it happened to be processed in — a drive that '
        'starts 23:50 on a Sunday belongs to the closing week', () async {
      // Sunday 23:50, the last night of the week of Mon 2026-08-31.
      final sundayNight = DateTime(2026, 9, 6, 23, 50);
      final tripId = await saveTrip(
        distanceKm: kRoadWarriorWeeklyKm + 1,
        startedAt: sundayNight,
      );

      final update = await processor.processCompletedTrip(
        tripId: tripId,
        uid: uid,
        points: cleanPoints(from: sundayNight),
        distanceKm: kRoadWarriorWeeklyKm + 1,
        durationSeconds: 600,
        startedAt: sundayNight,
      );

      expect(
        update.unlockedTrophies.map((Trophy t) => t.type),
        contains(TrophyType.roadWarrior),
      );
      // Keyed to that week, so the same drive can't earn it again and
      // the next week starts fresh.
      expect(update.unlockedTrophies.single.id, contains('2026-W36'));
    });

    test('consistent unlocks after every day of the week qualifies', () async {
      for (var day = 31; day <= 31; day++) {
        await process(await saveTrip(startedAt: DateTime(2026, 8, day, 9)));
      }
      for (var day = 1; day <= 5; day++) {
        await process(await saveTrip(startedAt: DateTime(2026, 9, day, 9)));
      }
      final beforeLastDay = await repo.getTrophies(uid);
      expect(
        beforeLastDay.map((Trophy t) => t.type),
        isNot(contains(TrophyType.consistent)),
      );

      final update = await process(
        await saveTrip(startedAt: DateTime(2026, 9, 6, 9)),
      );
      expect(
        update.unlockedTrophies.map((Trophy t) => t.type),
        contains(TrophyType.consistent),
      );
    });

    test('firstTarget unlocks when a personal target completes, and never '
        'again — its id carries no period, so the second target the user '
        'finishes collides with the first', () async {
      await createTarget(targetValue: 5);
      final first = await process(await saveTrip(distanceKm: 6));
      expect(
        first.unlockedTrophies.map((Trophy t) => t.type),
        contains(TrophyType.firstTarget),
      );

      await createTarget(targetValue: 5);
      final second = await process(await saveTrip(distanceKm: 6));
      expect(
        second.unlockedTrophies.map((Trophy t) => t.type),
        isNot(contains(TrophyType.firstTarget)),
      );
      final firstTargets = (await repo.getTrophies(uid))
          .where((Trophy t) => t.type == TrophyType.firstTarget);
      expect(firstTargets, hasLength(1));
    });

    test('completing a head-to-head challenge does not award firstTarget', () async {
      await createTarget(targetValue: 5, opponentUid: 'user-2');
      final update = await process(await saveTrip(distanceKm: 6));
      expect(
        update.unlockedTrophies.map((Trophy t) => t.type),
        isNot(contains(TrophyType.firstTarget)),
      );
    });
  });

  group('serialization', () {
    test('two trips processed concurrently both land, and the final tally '
        'reflects both — a skip-if-running mutex would drop one', () async {
      final target = await createTarget(targetValue: 100);
      final firstTripId = await saveTrip(distanceKm: 10);
      final secondTripId = await saveTrip(distanceKm: 15);

      await Future.wait([process(firstTripId), process(secondTripId)]);

      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 25);
      expect(await db.select(db.tripEligibility).get(), hasLength(2));
    });

    test('a failure on one trip does not poison the queue for the next', () async {
      final target = await createTarget(targetValue: 100);
      // No trip row exists for this id, so recording its verdict trips
      // the foreign key.
      await expectLater(process(999999), throwsA(anything));

      await process(await saveTrip(distanceKm: 10));
      final progress = await repo.getProgress(
        challengeId: target.id,
        uid: uid,
      );
      expect(progress!.currentValue, 10);
    });
  });
}
