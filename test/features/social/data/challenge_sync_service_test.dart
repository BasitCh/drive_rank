import 'dart:ui';

import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/data/services/challenge_sync_service.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

/// The cloud as a device sees it on launch: the challenges, a live
/// listener that only ever replays a stale snapshot, and a server read
/// that holds the frozen figures.
class _FakeDirectory implements SocialDirectory {
  List<Challenge> challenges = const [];

  /// What the server holds, per challenge.
  final Map<String, Map<String, double>> server = {};

  /// Makes the server read fail, the way it does offline.
  bool offline = false;

  int serverReads = 0;

  @override
  Future<List<Challenge>> challengesFor(String uid) async => challenges;

  @override
  Stream<List<Challenge>> watchChallenges(String uid) =>
      Stream.value(challenges);

  @override
  Stream<Map<String, double>> watchProgress(String challengeId) =>
      const Stream.empty();

  @override
  Future<Map<String, double>> progressFor(String challengeId) async {
    serverReads++;
    if (offline) throw StateError('unavailable');
    return server[challengeId] ?? const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError("${invocation.memberName} is not the sync's");
}

void main() {
  const me = 'me-uid';
  const rival = 'rival-uid';

  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late UserSettingsRepository settings;
  late _FakeDirectory directory;
  late ChallengeSyncService sync;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    settings = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'US')),
      _MockFreeTripCounterService(),
    );
    directory = _FakeDirectory();
    getIt.registerSingleton<SocialDirectory>(directory);
    await settings.syncUid(me);
    sync = ChallengeSyncService(repo, settings);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Challenge challenge({
    required DateTime endAt,
    ChallengeStatus status = ChallengeStatus.active,
  }) => Challenge(
    id: 'c1',
    creatorUid: rival,
    opponentUid: me,
    metric: CompetitionMetric.distance,
    targetValue: 50,
    period: LeaderboardPeriod.weekly,
    startAt: endAt.subtract(const Duration(days: 3)),
    endAt: endAt,
    status: status,
    createdAt: endAt.subtract(const Duration(days: 3)),
    updatedAt: endAt.subtract(const Duration(days: 3)),
  );

  /// The rival's figure as this device last saw it — before it closed.
  Future<void> heldBeforeClosing(Challenge c, double km) async {
    await repo.upsertChallenge(c);
    await repo.upsertProgressValue(
        ChallengeProgress(
          challengeId: c.id,
          uid: rival,
          currentValue: km,
          targetValue: c.targetValue,
          lastCalculatedAt: c.endAt.subtract(const Duration(hours: 1)),
        ),
      );
  }

  Future<double?> rivalFigure() async =>
      (await repo.getProgress(challengeId: 'c1', uid: rival))?.currentValue;

  // Found planning the two-device run: the live listeners stop at the
  // freeze, so a phone closed through the grace kept the opponent's
  // figure from before it and settled against that stale number.
  group('a device that was closed through the finalization grace', () {
    test('picks up the figure the rival published during the grace', () async {
      final c = challenge(
        endAt: DateTime.now().subtract(const Duration(hours: 8)),
      );
      directory.challenges = [c];
      await heldBeforeClosing(c, 41.67);
      // Their honest late upload, made while this device was closed.
      directory.server['c1'] = {rival: 31.25, me: 20.83};

      await sync.syncNow();

      expect(await rivalFigure(), 31.25);
    });

    test('reads the frozen figures once, not on every launch', () async {
      final c = challenge(
        endAt: DateTime.now().subtract(const Duration(hours: 8)),
      );
      directory.challenges = [c];
      await heldBeforeClosing(c, 41.67);
      directory.server['c1'] = {rival: 31.25};

      await sync.syncNow();
      await sync.syncNow();
      await sync.syncNow();

      expect(directory.serverReads, 1);
      expect(await rivalFigure(), 31.25);
    });

    test('offline, keeps what it had and tries again next launch', () async {
      final c = challenge(
        endAt: DateTime.now().subtract(const Duration(hours: 8)),
      );
      directory.challenges = [c];
      await heldBeforeClosing(c, 41.67);
      directory.server['c1'] = {rival: 31.25};

      directory.offline = true;
      await sync.syncNow();
      expect(await rivalFigure(), 41.67);

      directory.offline = false;
      await sync.syncNow();
      expect(await rivalFigure(), 31.25);
    });

    test('an opponent who never published stays absent — not a zero',
        () async {
      final c = challenge(
        endAt: DateTime.now().subtract(const Duration(hours: 8)),
      );
      directory.challenges = [c];
      directory.server['c1'] = {me: 20.83};

      await sync.syncNow();

      expect(await rivalFigure(), isNull);
    });
  });

  test("the viewer's own side is what they published — a local "
      'recompute that never reached the server is replaced, not kept',
      () async {
    final c = challenge(
      endAt: DateTime.now().subtract(const Duration(hours: 8)),
    );
    directory.challenges = [c];
    await repo.upsertChallenge(c);
    // This phone computed 80 locally; nothing of it was ever published.
    await repo.upsertProgressValue(
      ChallengeProgress(
        challengeId: c.id,
        uid: me,
        currentValue: 80,
        targetValue: c.targetValue,
      ),
    );
    directory.server['c1'] = {rival: 50};

    await sync.syncNow();

    final frozen = await repo.getFrozenFigures(
      challengeId: 'c1',
      viewerUid: me,
      opponentUid: rival,
    );
    expect(frozen, isNotNull);
    expect(frozen!.mine, isNull);
    expect(frozen.theirs, 50);
  });

  test("the read-marker never shows up as somebody's progress", () async {
    final c = challenge(
      endAt: DateTime.now().subtract(const Duration(hours: 8)),
    );
    directory.challenges = [c];
    directory.server['c1'] = {rival: 50, me: 20};

    await sync.syncNow();

    final rows = await repo.getProgressForChallenge('c1');
    expect(rows.map((r) => r.uid).toSet(), {rival, me});
  });

  group('no extra reads where the listeners already cover it', () {
    test('a challenge still inside its grace is left to the listener',
        () async {
      final c = challenge(
        endAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      directory.challenges = [c];

      await sync.syncNow();

      expect(directory.serverReads, 0);
    });

    test('a challenge nobody accepted has no figures to read', () async {
      directory.challenges = [
        challenge(
          endAt: DateTime.now().subtract(const Duration(hours: 8)),
          status: ChallengeStatus.pending,
        ),
      ];

      await sync.syncNow();

      expect(directory.serverReads, 0);
    });
  });
}
