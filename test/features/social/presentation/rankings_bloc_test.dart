import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/create_target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:drive_rank/features/social/presentation/bloc/rankings_bloc.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

void main() {
  late AppDatabase db;
  late UserSettingsRepository settings;
  late TripRepository trips;
  late RankingsBloc bloc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'US')),
      _MockFreeTripCounterService(),
    );
    trips = TripRepository(db, GeocodingService());
    final repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    const calculator = DefaultCompetitionMetricCalculator();
    bloc = RankingsBloc(
      settings,
      trips,
      GetGlobalLeaderboard(repo, calculator),
      GetTargets(repo, calculator),
      CreateTarget(repo, RefreshTargetProgress(repo, calculator)),
      repo,
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  /// Waits for the bloc to settle on a state matching [predicate].
  Future<RankingsState> settle(bool Function(RankingsState) predicate) {
    if (predicate(bloc.state)) return Future.value(bloc.state);
    return bloc.stream.firstWhere(predicate);
  }

  Future<RankingsState> loaded() => settle((s) => !s.isLoading);

  Future<int> addTrip({
    required String uid,
    required double distanceKm,
    DateTime? startedAt,
  }) {
    return db
        .into(db.trips)
        .insert(
          TripsCompanion.insert(
            uid: uid,
            topSpeedKmh: 90,
            avgSpeedKmh: 50,
            distanceKm: distanceKm,
            durationSeconds: 900,
            startedAt: startedAt ?? DateTime.now(),
          ),
        );
  }

  test('loads a board on start, with the viewer on it', () async {
    bloc.add(const RankingsStarted());
    final state = await loaded();

    expect(state.board, isNotNull);
    expect(state.board!.me, isNotNull);
    expect(state.metric, CompetitionMetric.distance);
    expect(state.period, LeaderboardPeriod.weekly);
    expect(state.rankingsEnabled, isTrue);
  });

  test('changing the metric rebuilds the board', () async {
    final row = await settings.read();
    await addTrip(uid: row.uid, distanceKm: 30);
    await addTrip(uid: row.uid, distanceKm: 50);

    bloc.add(const RankingsStarted());
    final initial = await loaded();
    expect(initial.board!.me!.entry.value, 80);

    bloc.add(const RankingsMetricChanged(CompetitionMetric.longestTrip));
    final switched = await settle(
      (s) => s.metric == CompetitionMetric.longestTrip && s.board != null,
    );
    // Longest single drive, not the sum.
    expect(switched.board!.me!.entry.value, 50);
  });

  test('changing the period rebuilds the board', () async {
    final row = await settings.read();
    // Last month — outside this week, inside all-time.
    await addTrip(
      uid: row.uid,
      distanceKm: 200,
      startedAt: DateTime.now().subtract(const Duration(days: 40)),
    );

    bloc.add(const RankingsStarted());
    final weekly = await loaded();
    expect(weekly.board!.me!.entry.value, 0);

    bloc.add(const RankingsPeriodChanged(LeaderboardPeriod.allTime));
    final allTime = await settle(
      (s) => s.period == LeaderboardPeriod.allTime && s.board != null,
    );
    expect(allTime.board!.me!.entry.value, 200);
  });

  test('re-selecting the current metric changes nothing', () async {
    final row = await settings.read();
    await addTrip(uid: row.uid, distanceKm: 45);

    bloc.add(const RankingsStarted());
    final before = await settle((s) => (s.board?.me?.entry.value ?? 0) == 45);

    bloc.add(const RankingsMetricChanged(CompetitionMetric.distance));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.metric, before.metric);
    expect(bloc.state.board!.me!.entry.value, 45);
  });

  test('a selector change lands as one state, never a frame of the new '
      'label over the old numbers', () async {
    final row = await settings.read();
    await addTrip(uid: row.uid, distanceKm: 30);
    await addTrip(uid: row.uid, distanceKm: 50);

    bloc.add(const RankingsStarted());
    await settle((s) => (s.board?.me?.entry.value ?? 0) == 80);

    final seen = <(CompetitionMetric, double)>[];
    final sub = bloc.stream.listen(
      (s) => seen.add((s.metric, s.board?.me?.entry.value ?? -1)),
    );

    bloc.add(const RankingsMetricChanged(CompetitionMetric.longestTrip));
    await settle((s) => s.metric == CompetitionMetric.longestTrip);
    await sub.cancel();

    // Every emitted state pairs its metric with that metric's value —
    // 80 is the distance total, 50 the longest single drive, and no
    // state may mix "longestTrip" with 80.
    for (final (metric, value) in seen) {
      if (metric == CompetitionMetric.longestTrip) {
        expect(value, 50, reason: 'stale board shown under a new metric');
      }
    }
  });

  test('a new trip recomputes the board without any explicit refresh',
      () async {
    final row = await settings.read();
    bloc.add(const RankingsStarted());
    final initial = await loaded();
    expect(initial.board!.me!.entry.value, 0);

    await addTrip(uid: row.uid, distanceKm: 64);
    final updated = await settle((s) => (s.board?.me?.entry.value ?? 0) > 0);
    expect(updated.board!.me!.entry.value, 64);
  });

  test('the uid changing mid-session re-scopes the board — this is the '
      'staleness bug that PersonalBestsRepository.watch() has, and a '
      'screen showing competitive standing cannot inherit it', () async {
    final row = await settings.read();
    // Trips already claimed by the account we are about to become.
    await addTrip(uid: 'firebase-uid-1', distanceKm: 300);
    // …and one under the pre-auth placeholder, which syncUid migrates.
    await addTrip(uid: row.uid, distanceKm: 20);

    bloc.add(const RankingsStarted());
    final before = await loaded();
    expect(before.board!.me!.entry.value, 20);

    await settings.syncUid('firebase-uid-1');

    final after = await settle(
      (s) => (s.board?.me?.entry.value ?? 0) == 320,
    );
    // 300 already-owned + the 20 that migrated across.
    expect(after.board!.me!.entry.value, 320);
  });

  test('the display name follows the username once onboarding sets it',
      () async {
    bloc.add(const RankingsStarted());
    final anonymous = await loaded();
    expect(anonymous.board!.me!.entry.displayName, 'You');

    await settings.patch(const UserSettingsCompanion(username: Value('basit')));
    final named = await settle(
      (s) => s.board?.me?.entry.displayName == 'basit',
    );
    expect(named.board!.me!.entry.displayName, 'basit');
  });

  group('kill switch', () {
    test('starts enabled', () async {
      bloc.add(const RankingsStarted());
      final state = await loaded();
      expect(state.rankingsEnabled, isTrue);
    });

    test('flipping it off disables the screen mid-session', () async {
      bloc.add(const RankingsStarted());
      await loaded();

      await settings.setRankingsEnabled(enabled: false);
      final disabled = await settle((s) => !s.rankingsEnabled);
      expect(disabled.rankingsEnabled, isFalse);
    });

    test('flipping it back on recovers without a restart — proving the '
        'screen follows the stream rather than a one-shot read at '
        'startup', () async {
      await settings.setRankingsEnabled(enabled: false);
      bloc.add(const RankingsStarted());
      final disabled = await settle((s) => !s.rankingsEnabled);
      expect(disabled.rankingsEnabled, isFalse);

      await settings.setRankingsEnabled(enabled: true);
      final enabled = await settle((s) => s.rankingsEnabled);
      expect(enabled.rankingsEnabled, isTrue);
    });
  });
}
