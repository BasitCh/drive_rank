import 'dart:ui';

import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart';
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart';
import 'package:drive_rank/features/social/data/services/competition_mirror_sink.dart';
import 'package:drive_rank/features/social/data/services/competition_value_publisher.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:drive_rank/shared/services/username_reservation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

/// Records what would have been published.
class _RecordingSink implements CompetitionMirrorSink {
  final List<CompetitionMirror> writes = [];
  bool fail = false;

  @override
  Future<void> write(CompetitionMirror mirror) async {
    if (fail) throw StateError('offline');
    writes.add(mirror);
  }
}

/// An in-memory namespace, so the claim logic is tested without Firestore.
class _FakeReservations implements UsernameReservationService {
  final Map<String, String> holders = {};
  bool fail = false;

  @override
  Future<UsernameClaim> claim({
    required String uid,
    required String username,
  }) async {
    if (fail) return UsernameClaim.unknown;
    final key = usernameKey(username);
    final holder = holders[key];
    if (holder == null) {
      holders[key] = uid;
      return UsernameClaim.claimed;
    }
    return holder == uid ? UsernameClaim.alreadyMine : UsernameClaim.taken;
  }

  @override
  Future<UsernameClaim> check({
    required String username,
    String? forUid,
  }) async {
    if (fail) return UsernameClaim.unknown;
    final holder = holders[usernameKey(username)];
    if (holder == null) return UsernameClaim.claimed;
    return holder == forUid ? UsernameClaim.alreadyMine : UsernameClaim.taken;
  }
}

void main() {
  late AppDatabase db;
  late UserSettingsRepository settings;
  late SocialRepositoryImpl repo;
  late CompetitionValuePublisher publisher;
  late _RecordingSink sink;
  late _FakeReservations reservations;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'DE')),
      _MockFreeTripCounterService(),
    );
    repo = SocialRepositoryImpl(SocialLocalDataSource(db));
    sink = _RecordingSink();
    reservations = _FakeReservations();
    publisher = CompetitionValuePublisher(
      settings,
      repo,
      const DefaultCompetitionMetricCalculator(),
    );

    getIt
      ..registerSingleton<CompetitionMirrorSink>(sink)
      ..registerSingleton<UsernameReservationService>(reservations)
      ..registerSingleton<PublicProfileService>(NoopPublicProfileService())
      ..registerSingleton<CompetitionValuePublisher>(publisher);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Future<void> signIn(String uid) => settings.syncUid(uid);

  Future<int> addTrip({double distanceKm = 100, DateTime? startedAt}) {
    return db.into(db.trips).insert(
      TripsCompanion.insert(
        uid: 'user-1',
        topSpeedKmh: 90,
        avgSpeedKmh: 50,
        distanceKm: distanceKm,
        durationSeconds: 1800,
        startedAt: startedAt ?? DateTime.now(),
      ),
    );
  }

  group('publishing your own totals', () {
    test('publishes every metric over every window', () async {
      await signIn('user-1');
      await addTrip(distanceKm: 120);

      await publisher.publishNow();

      expect(sink.writes, hasLength(1));
      final mirror = sink.writes.single;
      expect(mirror.uid, 'user-1');
      for (final metric in CompetitionMetric.values) {
        for (final period in LeaderboardPeriod.values) {
          expect(
            mirror.totals.containsKey((metric, period)),
            isTrue,
            reason: 'missing $metric/$period',
          );
        }
      }
      expect(
        mirror.totalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
        120,
      );
    });

    test('recomputes rather than accumulating, so deleting a trip lowers '
        'the published figure instead of leaving an inflated total',
        () async {
      await signIn('user-1');
      final id = await addTrip(distanceKm: 120);
      await addTrip(distanceKm: 30);
      await publisher.publishNow();
      expect(
        sink.writes.last.totalFor(
          CompetitionMetric.distance,
          LeaderboardPeriod.weekly,
        ),
        150,
      );

      await (db.delete(db.trips)..where((t) => t.id.equals(id))).go();
      await publisher.publishNow();

      expect(
        sink.writes.last.totalFor(
          CompetitionMetric.distance,
          LeaderboardPeriod.weekly,
        ),
        30,
      );
    });

    test('is idempotent — publishing twice writes the same values, which '
        'is what makes a retry safe', () async {
      await signIn('user-1');
      await addTrip(distanceKm: 75);

      await publisher.publishNow();
      await publisher.publishNow();

      expect(sink.writes, hasLength(2));
      expect(sink.writes.first.totals, sink.writes.last.totals);
    });

    test('carries the identity fields the mirror renders friends with',
        () async {
      await signIn('user-1');
      await settings.setUsername('basit');
      await settings.setCar(make: 'BMW', model: 'M3');
      await settings.setCountry('PK');
      sink.writes.clear();

      await publisher.publishNow();

      final mirror = sink.writes.single;
      expect(mirror.username, 'basit');
      expect(mirror.carMake, 'BMW');
      expect(mirror.carModel, 'M3');
      expect(mirror.countryCode, 'PK');
    });

    test('an identity change republishes on its own — otherwise someone '
        'who changes car after their last drive shows the old one to '
        'every friend until they next drive', () async {
      await signIn('user-1');
      await publisher.publishNow();
      sink.writes.clear();

      await settings.setCar(make: 'Audi', model: 'RS3');

      expect(sink.writes, hasLength(1));
      expect(sink.writes.single.carMake, 'Audi');
    });

    test('a change to something the mirror does not carry publishes '
        'nothing', () async {
      await signIn('user-1');
      await publisher.publishNow();
      sink.writes.clear();

      await settings.setMinTripLengthMeters(750);

      expect(sink.writes, isEmpty);
    });

    test('publishes nothing under the pre-auth placeholder — a public '
        'document belonging to nobody would be stranded the moment a '
        'real uid arrived', () async {
      await addTrip(distanceKm: 50);

      await publisher.publishNow();

      expect(sink.writes, isEmpty);
    });

    test('a failed publish is swallowed, because the values are local and '
        'recomputed from scratch next time', () async {
      await signIn('user-1');
      await addTrip();
      sink.fail = true;

      await publisher.publishNow();

      expect(sink.writes, isEmpty);
    });
  });

  group('claiming a username', () {
    test('claims a free name and records that the account holds it',
        () async {
      await signIn('user-1');
      await settings.setUsername('basit');

      expect(await settings.claimUsername(), UsernameClaim.claimed);
      expect((await settings.read()).usernameClaimed, isTrue);
    });

    test('re-claiming your own name is a no-op, which is what makes it '
        'safe to run on every launch', () async {
      await signIn('user-1');
      await settings.setUsername('basit');
      await settings.claimUsername();

      expect(await settings.claimUsername(), UsernameClaim.alreadyMine);
      expect((await settings.read()).usernameClaimed, isTrue);
    });

    test('a name somebody else holds leaves the account unclaimed — and '
        'crucially does not rename them', () async {
      reservations.holders['basit'] = 'someone-else';
      await signIn('user-1');
      await settings.setUsername('basit');

      expect(await settings.claimUsername(), UsernameClaim.taken);
      final row = await settings.read();
      expect(row.usernameClaimed, isFalse);
      expect(row.username, 'basit', reason: 'the local name is untouched');
    });

    test('an unreachable namespace leaves the account unclaimed rather '
        'than concluding the name is taken — offline and taken are not '
        'the same answer', () async {
      await signIn('user-1');
      await settings.setUsername('basit');
      reservations.fail = true;

      expect(await settings.claimUsername(), UsernameClaim.unknown);
      expect((await settings.read()).usernameClaimed, isFalse);

      // …and the retry on a later launch succeeds.
      reservations.fail = false;
      expect(await settings.claimUsername(), UsernameClaim.claimed);
      expect((await settings.read()).usernameClaimed, isTrue);
    });

    test('never claims under the pre-auth placeholder uid', () async {
      await settings.setUsername('basit');

      expect(await settings.claimUsername(), UsernameClaim.unknown);
      expect(reservations.holders, isEmpty);
    });

    test('a name is matched case-insensitively, so Basit and basit are '
        'one address', () async {
      reservations.holders['basit'] = 'someone-else';
      await signIn('user-1');
      await settings.setUsername('BASIT');

      expect(await settings.claimUsername(), UsernameClaim.taken);
    });
  });
}
