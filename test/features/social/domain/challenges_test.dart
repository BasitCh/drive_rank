import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/create_challenge.dart';
import 'package:drive_rank/features/social/domain/usecases/get_challenges.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/domain/usecases/settle_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late CreateChallenge create;
  late GetChallenges getChallenges;
  late GetTargets getTargets;

  const me = 'me-uid';
  const them = 'them-uid';
  // A Thursday, deliberately mid-week: the whole point of the window
  // decision below is what happens when a challenge is opened part-way
  // through a period.
  final thursday = DateTime(2026, 9, 10, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    const calculator = DefaultCompetitionMetricCalculator();
    create = CreateChallenge(repo);
    getChallenges = GetChallenges(repo, calculator, const SettleChallenge());
    getTargets = GetTargets(repo, calculator);
  });

  tearDown(() async => db.close());

  Future<void> addTrip({
    required double distanceKm,
    required DateTime startedAt,
    String uid = me,
  }) async {
    final id = await db
        .into(db.trips)
        .insert(
          TripsCompanion.insert(
            uid: uid,
            topSpeedKmh: 100,
            avgSpeedKmh: 60,
            distanceKm: distanceKm,
            durationSeconds: 3600,
            startedAt: startedAt,
          ),
        );
    await repo.recordTripEligibility(
      tripId: id,
      eligibility: const CompetitionEligibility(),
      startedAt: startedAt,
    );
  }

  Future<Challenge> open({
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    double targetValue = 100,
    DateTime? at,
  }) => create(
    creatorUid: me,
    opponentUid: them,
    metric: CompetitionMetric.distance,
    period: period,
    targetValue: targetValue,
    now: at ?? thursday,
  );

  group('opening one', () {
    test('starts NOW, not at the period boundary — a weekly challenge '
        'opened on Thursday must not hand its creator the driving they '
        'already did since Monday, which the opponent cannot see and '
        'the creator chose the moment to bank', () async {
      final challenge = await open();

      expect(challenge.startAt, thursday);
      // The period still decides the deadline: end of this week.
      expect(challenge.endAt, DateTime(2026, 9, 14));
    });

    test('so driving from earlier in the week does not count', () async {
      // Monday and Tuesday, before the challenge existed.
      await addTrip(distanceKm: 200, startedAt: DateTime(2026, 9, 7, 8));
      await addTrip(distanceKm: 50, startedAt: DateTime(2026, 9, 8, 8));
      // …and one after it was opened.
      await addTrip(distanceKm: 30, startedAt: DateTime(2026, 9, 11, 8));
      await open();

      final views = await getChallenges(uid: me, now: DateTime(2026, 9, 12));
      expect(views.single.settlement.mine, 30);
    });

    test('waits to be accepted, unlike a target', () async {
      expect((await open()).status, ChallengeStatus.pending);
    });

    test('refuses an all-time challenge — a race with no finish line '
        'cannot be settled', () async {
      expect(
        () => open(period: LeaderboardPeriod.allTime),
        throwsArgumentError,
      );
    });

    test('refuses a challenge against yourself and a target of zero', () {
      expect(
        () => create(
          creatorUid: me,
          opponentUid: me,
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          targetValue: 100,
          now: thursday,
        ),
        throwsArgumentError,
      );
      expect(() => open(targetValue: 0), throwsArgumentError);
    });

    test('never shows up among personal targets — a target is one '
        "person's business and a challenge is two people's", () async {
      await open();
      expect(await getTargets(uid: me), isEmpty);
    });
  });

  group('reading them back', () {
    test("the viewer's figure is recomputed and the opponent's is read — "
        'a figure from local trips cannot go stale, and reading back '
        'what this device published would let a stale snapshot of '
        'yourself decide your own result', () async {
      final challenge = await open();
      await repo.updateChallengeStatus(
        challengeId: challenge.id,
        status: ChallengeStatus.active,
      );
      await addTrip(distanceKm: 80, startedAt: DateTime(2026, 9, 11));
      // The opponent's figure, as the sync would have stored it.
      await repo.upsertProgressValue(
        ChallengeProgress(
          challengeId: challenge.id,
          uid: them,
          currentValue: 60,
          targetValue: 100,
          lastCalculatedAt: thursday,
        ),
      );

      final view = (await getChallenges(
        uid: me,
        now: DateTime(2026, 9, 12),
      )).single;
      expect(view.settlement.mine, 80);
      expect(view.settlement.theirs, 60);
      expect(view.settlement.outcome, ChallengeOutcome.leading);
      expect(view.opponentUid, them);
      expect(view.isMine, isTrue);
    });

    test('an opponent who published nothing reads as null, not zero — '
        'the row the sync never wrote must not become a figure that '
        'hands the viewer a win', () async {
      final challenge = await open();
      await repo.updateChallengeStatus(
        challengeId: challenge.id,
        status: ChallengeStatus.active,
      );
      await addTrip(distanceKm: 80, startedAt: DateTime(2026, 9, 11));

      // Past the finalization boundary, where the distinction bites.
      final view = (await getChallenges(
        uid: me,
        now: DateTime(2026, 9, 14).add(kChallengeFinalizationGrace),
      )).single;
      expect(view.settlement.theirs, isNull);
      expect(view.settlement.outcome, ChallengeOutcome.undecided);
    });

    test('names the opponent from their published profile, and falls '
        'back to the uid rather than showing nothing', () async {
      await open();
      final named = (await getChallenges(
        uid: me,
        now: DateTime(2026, 9, 12),
        opponentProfiles: {
          them: const CompetitionMirror(
            uid: them,
            username: 'fahad',
            carMake: 'Toyota',
            carModel: 'Corolla',
            countryCode: 'PK',
            inviteCode: 'CODE1234',
            totals: {},
          ),
        },
      )).single;
      expect(named.opponentName, 'fahad');

      final unnamed = (await getChallenges(
        uid: me,
        now: DateTime(2026, 9, 12),
      )).single;
      expect(unnamed.opponentName, them);
    });

    test('the opponent sees the same challenge, from their side', () async {
      final challenge = await open();
      // The sync on their device would have written the same row.
      final theirView = (await getChallenges(
        uid: them,
        now: DateTime(2026, 9, 12),
      )).single;

      expect(theirView.challenge.id, challenge.id);
      expect(theirView.opponentUid, me);
      expect(theirView.isMine, isFalse);
      expect(theirView.needsMyAnswer, isTrue);
    });

    test('a withdrawn or refused challenge is history, not standings',
        () async {
      final cancelled = await open();
      await repo.updateChallengeStatus(
        challengeId: cancelled.id,
        status: ChallengeStatus.cancelled,
      );
      expect(await getChallenges(uid: me, now: thursday), isEmpty);
    });

    test('what needs an answer comes first, then what is undecided, '
        'then what is over', () async {
      final mine = await open(at: thursday);
      await repo.updateChallengeStatus(
        challengeId: mine.id,
        status: ChallengeStatus.active,
      );
      // One waiting on the viewer: opened by the other person.
      await repo.createChallenge(
        Challenge(
          id: 'theirs',
          creatorUid: them,
          opponentUid: me,
          metric: CompetitionMetric.distance,
          targetValue: 50,
          period: LeaderboardPeriod.weekly,
          startAt: thursday,
          endAt: DateTime(2026, 9, 14),
          status: ChallengeStatus.pending,
          createdAt: thursday,
          updatedAt: thursday,
        ),
      );

      final views = await getChallenges(uid: me, now: DateTime(2026, 9, 12));
      expect(views.first.needsMyAnswer, isTrue);
      expect(views.last.challenge.id, mine.id);
    });
  });
}
