import 'dart:ui';

import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/create_target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/domain/usecases/get_trip_rank_change.dart';
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_social_bloc.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

void main() {
  late AppDatabase db;
  late SocialRepositoryImpl repo;
  late UserSettingsRepository settings;
  late TripRepository trips;
  late CreateTarget createTarget;
  late TripSocialBloc bloc;
  late String uid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    settings = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'US')),
      _MockFreeTripCounterService(),
    );
    trips = TripRepository(db, GeocodingService());
    const calculator = DefaultCompetitionMetricCalculator();
    createTarget = CreateTarget(
      repo,
      RefreshTargetProgress(repo, calculator),
    );
    bloc = TripSocialBloc(
      trips,
      settings,
      repo,
      GetTripRankChange(GetGlobalLeaderboard(repo, calculator)),
      GetTargets(repo, calculator),
    );
    uid = (await settings.read()).uid;
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  /// A time inside the current weekly window that is never in the
  /// future — the bloc calls through without an injectable clock, so the
  /// fixture has to respect the real one.
  DateTime insideThisWeek() {
    final now = DateTime.now();
    final weekStart = CompetitionWindow.forPeriod(
      LeaderboardPeriod.weekly,
      now,
    ).start;
    final anHourAgo = now.subtract(const Duration(hours: 1));
    return anHourAgo.isAfter(weekStart) ? anHourAgo : weekStart;
  }

  Future<int> addTrip({required double distanceKm, bool eligible = true}) async {
    final start = insideThisWeek();
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
    await repo.recordTripEligibility(
      tripId: tripId,
      eligibility: eligible
          ? const CompetitionEligibility()
          : const CompetitionEligibility(
              reasons: [EligibilityFailureReason.mockLocationDetected],
            ),
      startedAt: start,
    );
    return tripId;
  }

  Future<TripSocialState> load(int tripId) {
    bloc.add(TripSocialLoaded(tripId));
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  test('a trip that climbs past a benchmark reports the movement it '
      'caused', () async {
    // Enough to clear the lower benchmarks in one drive.
    final tripId = await addTrip(distanceKm: 300);
    final state = await load(tripId);

    expect(state.rankChange, isNotNull);
    expect(state.rankChange!.improved, isTrue);
    expect(state.rankChange!.passedNames, isNotEmpty);
    expect(state.hasContent, isTrue);
  });

  test('a trip with no competitive effect has nothing to show, so the '
      'card can be absent rather than announce "+0 places"', () async {
    // A first, tiny drive: it beats no benchmark and there is no target.
    final tripId = await addTrip(distanceKm: 0.4);
    final state = await load(tripId);

    expect(state.rankChange, isNull);
    expect(state.completedTargets, isEmpty);
    expect(state.activeTargets, isEmpty);
    expect(state.unlockedTrophies, isEmpty);
    expect(state.hasContent, isFalse);
  });

  test('an ineligible trip is reported as ineligible and nothing else — '
      'a drive that did not count cannot also claim it moved you',
      () async {
    final tripId = await addTrip(distanceKm: 300, eligible: false);
    final state = await load(tripId);

    expect(state.isIneligible, isTrue);
    expect(state.rankChange, isNull);
    expect(state.unlockedTrophies, isEmpty);
    // Still worth a card: silence would leave the user wondering why
    // 300 km did nothing.
    expect(state.hasContent, isTrue);
  });

  test('a trip that no longer exists resolves to an empty, non-loading '
      'state rather than throwing — the row can be deleted while the '
      'page is open', () async {
    final tripId = await addTrip(distanceKm: 120);
    await (db.delete(db.trips)..where((t) => t.id.equals(tripId))).go();

    final state = await load(tripId);
    expect(state.isLoading, isFalse);
    expect(state.hasContent, isFalse);
    expect(state.eligibility, isNull);
  });

  test('an active target shows its progress, so a drive that advanced '
      'something always has something to say', () async {
    await addTrip(distanceKm: 40);
    await createTarget(
      uid: uid,
      metric: CompetitionMetric.distance,
      period: LeaderboardPeriod.weekly,
      targetValue: 250,
    );
    // A second, small drive — no rank movement, but the target moved.
    final tripId = await addTrip(distanceKm: 5);

    final state = await load(tripId);
    expect(state.rankChange, isNull);
    expect(state.activeTargets, hasLength(1));
    expect(state.activeTargets.single.currentValue, 45);
    expect(state.completedTargets, isEmpty);
    expect(state.hasContent, isTrue);
  });

  test('a target already met is credited to this trip, since its '
      'completion is stamped at or after the drive started', () async {
    await addTrip(distanceKm: 300);
    final tripId = await addTrip(distanceKm: 200);
    // Created last, so its completion stamp lands after both drives —
    // the target is met the moment it is set.
    await createTarget(
      uid: uid,
      metric: CompetitionMetric.distance,
      period: LeaderboardPeriod.weekly,
      targetValue: 400,
    );

    final state = await load(tripId);
    expect(state.completedTargets, hasLength(1));
    expect(state.activeTargets, isEmpty);
  });

  test('trophies unlocked before this trip started are not claimed by '
      'it', () async {
    final tripId = await addTrip(distanceKm: 120);
    final trip = await trips.getById(tripId);
    await repo.awardTrophy(
      Trophy(
        id: 'roadWarrior:$uid:old',
        uid: uid,
        type: TrophyType.roadWarrior,
        unlockedAt: trip!.startedAt.subtract(const Duration(days: 3)),
      ),
    );
    await repo.awardTrophy(
      Trophy(
        id: 'consistent:$uid:now',
        uid: uid,
        type: TrophyType.consistent,
        unlockedAt: trip.startedAt.add(const Duration(minutes: 5)),
      ),
    );

    final state = await load(tripId);
    expect(
      state.unlockedTrophies.map((t) => t.type),
      [TrophyType.consistent],
    );
  });

  test('the same trip reloaded from History months later recomputes the '
      'same answer — nothing about it was stored at the time', () async {
    final tripId = await addTrip(distanceKm: 300);
    final first = await load(tripId);

    final second = await load(tripId);
    expect(second.rankChange!.previousRank, first.rankChange!.previousRank);
    expect(second.rankChange!.newRank, first.rankChange!.newRank);
    expect(second.rankChange!.passedNames, first.rankChange!.passedNames);
  });
}
