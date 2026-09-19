import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/create_target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late CreateTarget createTarget;
  late GetTargets getTargets;

  const uid = 'user-1';
  // A Thursday, so a weekly window has room on both sides.
  final now = DateTime(2026, 9, 3, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    const calculator = DefaultCompetitionMetricCalculator();
    createTarget = CreateTarget(
      repo,
      RefreshTargetProgress(repo, calculator),
    );
    getTargets = GetTargets(repo, calculator);
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
              ),
        startedAt: start,
      );
    }
    return tripId;
  }

  group('CreateTarget', () {
    test('creates an active personal target with no opponent', () async {
      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.weekly,
        targetValue: 250,
        now: now,
      );

      expect(created.isPersonal, isTrue);
      expect(created.opponentUid, isNull);
      expect(created.status, ChallengeStatus.active);
      expect(created.targetValue, 250);
    });

    test('rejects a non-positive target', () async {
      await expectLater(
        createTarget(
          uid: uid,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          targetValue: 0,
          now: now,
        ),
        throwsArgumentError,
      );
      await expectLater(
        createTarget(
          uid: uid,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          targetValue: -5,
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('takes its window from CompetitionWindow, never from the '
        'caller — one definition of "this week" for the target, the '
        'calculator and the board', () async {
      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.weekly,
        targetValue: 100,
        now: now,
      );
      final expected = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        now,
      );

      expect(created.startAt, expected.start);
      expect(created.endAt, expected.end);
    });

    test('a monthly target spans the calendar month', () async {
      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.monthly,
        targetValue: 1000,
        now: now,
      );
      expect(created.startAt, DateTime(2026, 9));
      expect(created.endAt, DateTime(2026, 10));
    });

    test('an all-time target still gets a concrete end, since a target '
        'you can never fail is not a target', () async {
      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.allTime,
        targetValue: 5000,
        now: now,
      );
      expect(created.endAt.isAfter(now), isTrue);
    });

    test('picks up driving that already happened, instead of starting at '
        'zero until the next trip', () async {
      await addTrip(distanceKm: 120);

      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.weekly,
        targetValue: 250,
        now: now,
      );

      final progress = await repo.getProgress(
        challengeId: created.id,
        uid: uid,
      );
      expect(progress!.currentValue, 120);
    });

    test('a target already met at creation is stamped complete '
        'immediately', () async {
      await addTrip(distanceKm: 300);

      final created = await createTarget(
        uid: uid,
        metric: CompetitionMetric.distance,
        period: LeaderboardPeriod.weekly,
        targetValue: 250,
        now: now,
      );

      final progress = await repo.getProgress(
        challengeId: created.id,
        uid: uid,
      );
      expect(progress!.completedAt, isNotNull);
      final stored = await repo.getChallengeById(created.id);
      expect(stored!.status, ChallengeStatus.completed);
    });

    group('window boundaries', () {
      test('a weekly target created in the final minute of the week gets '
          "that week's real end — never a window already in the past",
          () async {
        // Sunday 23:59; the week ends at Monday 00:00.
        final lastMinute = DateTime(2026, 9, 6, 23, 59);
        final created = await createTarget(
          uid: uid,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          targetValue: 100,
          now: lastMinute,
        );

        expect(created.startAt, DateTime(2026, 8, 31));
        expect(created.endAt, DateTime(2026, 9, 7));
        expect(created.endAt.isAfter(lastMinute), isTrue);
        expect(created.startAt.isBefore(created.endAt), isTrue);
      });

      test('a monthly target created in the final minute of the month '
          'behaves the same way', () async {
        final lastMinute = DateTime(2026, 9, 30, 23, 59);
        final created = await createTarget(
          uid: uid,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.monthly,
          targetValue: 100,
          now: lastMinute,
        );

        expect(created.startAt, DateTime(2026, 9));
        expect(created.endAt, DateTime(2026, 10));
        expect(created.endAt.isAfter(lastMinute), isTrue);
      });

      test('such a target is genuinely short-lived, and the engine '
          'expires it on the next drive rather than leaving it active '
          'forever — documented here so the outcome is known', () async {
        final lastMinute = DateTime(2026, 9, 6, 23, 59);
        final created = await createTarget(
          uid: uid,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          targetValue: 100,
          now: lastMinute,
        );

        // Still active while the window is open.
        final duringWindow = await repo.getActiveChallengesAt(
          uid: uid,
          at: lastMinute,
        );
        expect(duringWindow.map((c) => c.id), contains(created.id));

        // Once the week has turned, it's no longer picked up as active.
        final afterWindow = await repo.getActiveChallengesAt(
          uid: uid,
          at: DateTime(2026, 9, 7, 0, 1),
        );
        expect(afterWindow.map((c) => c.id), isNot(contains(created.id)));
        final lapsed = await repo.getLapsedActiveChallenges(
          uid: uid,
          at: DateTime(2026, 9, 7, 0, 1),
        );
        expect(lapsed.map((c) => c.id), contains(created.id));
      });
    });
  });

  group('GetTargets', () {
    Future<Challenge> target({
      double targetValue = 250,
      CompetitionMetric metric = CompetitionMetric.distance,
      LeaderboardPeriod period = LeaderboardPeriod.weekly,
    }) => createTarget(
      uid: uid,
      metric: metric,
      period: period,
      targetValue: targetValue,
      now: now,
    );

    test('returns the target with its live value and progress', () async {
      await target();
      await addTrip(distanceKm: 100);

      final targets = await getTargets(uid: uid);
      expect(targets, hasLength(1));
      expect(targets.single.currentValue, 100);
      expect(targets.single.targetValue, 250);
      expect(targets.single.progress, closeTo(0.4, 0.0001));
      expect(targets.single.remaining, 150);
      expect(targets.single.isComplete, isFalse);
    });

    test('an ineligible trip does not move a target', () async {
      await target();
      await addTrip(distanceKm: 200, eligible: false);

      final targets = await getTargets(uid: uid);
      expect(targets.single.currentValue, 0);
    });

    test('trips outside the target window do not count', () async {
      await target();
      await addTrip(
        distanceKm: 400,
        startedAt: now.subtract(const Duration(days: 20)),
      );

      final targets = await getTargets(uid: uid);
      expect(targets.single.currentValue, 0);
    });

    test('progress never exceeds 1 and remaining bottoms out at 0', () async {
      await target(targetValue: 50);
      await addTrip(distanceKm: 300);

      final targets = await getTargets(uid: uid);
      expect(targets.single.progress, 1);
      expect(targets.single.remaining, 0);
    });

    test('a completed target keeps its stamp even after the live value '
        'falls back below the target — finishing something is a fact '
        'about the past', () async {
      final tripId = await addTrip(distanceKm: 300);
      final created = await target(targetValue: 250);
      expect((await getTargets(uid: uid)).single.isComplete, isTrue);

      await (db.delete(db.trips)..where((t) => t.id.equals(tripId))).go();

      final after = await getTargets(uid: uid);
      expect(after.single.currentValue, 0);
      expect(after.single.isComplete, isTrue);
      expect(after.single.challenge.id, created.id);
    });

    test('head-to-head challenges never appear — they need an '
        "opponent's value, which nothing can supply yet", () async {
      await target();
      await repo.createChallenge(
        Challenge(
          id: const Uuid().v4(),
          creatorUid: uid,
          opponentUid: 'user-2',
          metric: CompetitionMetric.distance,
          targetValue: 500,
          period: LeaderboardPeriod.weekly,
          startAt: DateTime(2026, 8, 31),
          endAt: DateTime(2026, 9, 7),
          status: ChallengeStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final targets = await getTargets(uid: uid);
      expect(targets, hasLength(1));
      expect(targets.single.challenge.isPersonal, isTrue);
    });

    test('cancelled targets are left out', () async {
      final created = await target();
      await repo.updateChallengeStatus(
        challengeId: created.id,
        status: ChallengeStatus.cancelled,
      );
      expect(await getTargets(uid: uid), isEmpty);
    });

    test('active targets sort ahead of completed ones', () async {
      await addTrip(distanceKm: 300);
      await target(targetValue: 100); // completes immediately
      await target(targetValue: 5000); // still going

      final targets = await getTargets(uid: uid);
      expect(targets, hasLength(2));
      expect(targets.first.isComplete, isFalse);
      expect(targets.last.isComplete, isTrue);
    });

    test('consistency targets count days, not distance', () async {
      await target(
        targetValue: 3,
        metric: CompetitionMetric.consistency,
      );
      await addTrip(distanceKm: 20, startedAt: DateTime(2026, 9, 1, 9));
      await addTrip(distanceKm: 20, startedAt: DateTime(2026, 9, 1, 18));
      await addTrip(distanceKm: 20, startedAt: DateTime(2026, 9, 2, 9));

      final targets = await getTargets(uid: uid);
      expect(targets.single.currentValue, 2);
    });

    test('is empty for a user with no targets', () async {
      expect(await getTargets(uid: uid), isEmpty);
    });
  });
}
