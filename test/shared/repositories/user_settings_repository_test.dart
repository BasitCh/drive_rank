import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/paywall_service.dart'
    show ProEntitlementCheck;
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

void main() {
  late AppDatabase db;
  late UserSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'US')),
      _MockFreeTripCounterService(),
    );
  });

  tearDown(() async => db.close());

  group('setGoals', () {
    test('persists both goals together', () async {
      await repo.setGoals(speedGoalKmh: 175, distanceGoalKm: 75);
      final row = await repo.read();
      expect(row.speedGoalKmh, 175);
      expect(row.distanceGoalKm, 75);
    });

    test('updating only the speed goal leaves a previously-set distance '
        'goal untouched', () async {
      // Regression test: `setGoals` must use `Value.absent()` for an
      // omitted parameter, not `Value(null)` — the latter would wipe
      // the other goal to null instead of leaving it alone.
      await repo.setGoals(speedGoalKmh: 160, distanceGoalKm: 60);
      await repo.setGoals(speedGoalKmh: 175);
      final row = await repo.read();
      expect(row.speedGoalKmh, 175);
      expect(row.distanceGoalKm, 60);
    });

    test(
      'updating only the distance goal leaves the speed goal untouched',
      () async {
        await repo.setGoals(speedGoalKmh: 160, distanceGoalKm: 60);
        await repo.setGoals(distanceGoalKm: 90);
        final row = await repo.read();
        expect(row.speedGoalKmh, 160);
        expect(row.distanceGoalKm, 90);
      },
    );

    test('goals default to null before any trip completes', () async {
      final row = await repo.read();
      expect(row.speedGoalKmh, isNull);
      expect(row.distanceGoalKm, isNull);
    });
  });

  group('syncUid', () {
    test('migrates the settings row and every trip tagged with its old '
        'uid to the new uid', () async {
      final before = await repo.read(); // creates the row, uid = 'local'
      await db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: before.uid,
              topSpeedKmh: 120,
              avgSpeedKmh: 60,
              distanceKm: 10,
              durationSeconds: 600,
              startedAt: DateTime(2026, 1, 1),
            ),
          );

      await repo.syncUid('firebase-uid-1');

      final after = await repo.read();
      expect(after.uid, 'firebase-uid-1');
      final trips = await db.select(db.trips).get();
      expect(trips, hasLength(1));
      expect(trips.single.uid, 'firebase-uid-1');
    });

    test('is a no-op when the row already matches', () async {
      final before = await repo.read();
      await repo.syncUid(before.uid); // already 'local' — no-op
      final after = await repo.read();
      expect(after.uid, before.uid);
    });
  });

  group('reassignUidOnly — account-switching isolation', () {
    test("repoints the settings row WITHOUT touching a different account's "
        'trips — this is the guarantee the account-switching guard '
        '(isSafeToClaimLocalData) relies on: signing into Account B on a '
        "device that already holds Account A's claimed local data must "
        "never migrate or expose A's trips under B.", () async {
      final before = await repo.read();
      await db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: before.uid,
              topSpeedKmh: 200,
              avgSpeedKmh: 90,
              distanceKm: 25,
              durationSeconds: 1200,
              startedAt: DateTime(2026, 1, 1),
            ),
          );

      // Simulate: this device already claimed the data for Account A.
      await repo.syncUid('account-a-uid');

      // Now Account B signs in on the same device — the guard decided
      // this is NOT safe to claim, so the caller uses reassignUidOnly
      // instead of syncUid.
      await repo.reassignUidOnly('account-b-uid');

      final after = await repo.read();
      expect(after.uid, 'account-b-uid');

      // A's trip must still exist, still tagged with A's uid — never
      // deleted, never migrated to B.
      final trips = await db.select(db.trips).get();
      expect(trips, hasLength(1));
      expect(trips.single.uid, 'account-a-uid');
    });

    test("Account A's trips become visible again automatically once the "
        'settings row uid matches A again — no explicit restore step, '
        'just the existing uid-scoped query behavior', () async {
      final before = await repo.read();
      await db
          .into(db.trips)
          .insert(
            TripsCompanion.insert(
              uid: before.uid,
              topSpeedKmh: 150,
              avgSpeedKmh: 70,
              distanceKm: 15,
              durationSeconds: 900,
              startedAt: DateTime(2026, 1, 1),
            ),
          );
      await repo.syncUid('account-a-uid');
      await repo.reassignUidOnly('account-b-uid'); // switch to B

      var currentUid = (await repo.read()).uid;
      var visibleToCurrentUid = await (db.select(
        db.trips,
      )..where((t) => t.uid.equals(currentUid))).get();
      expect(visibleToCurrentUid, isEmpty); // B sees nothing yet

      await repo.reassignUidOnly('account-a-uid'); // A signs back in

      currentUid = (await repo.read()).uid;
      visibleToCurrentUid = await (db.select(
        db.trips,
      )..where((t) => t.uid.equals(currentUid))).get();
      expect(visibleToCurrentUid, hasLength(1)); // A's trip is back
    });

    test('is a no-op when the row already matches', () async {
      final before = await repo.read();
      await repo.reassignUidOnly(before.uid);
      final after = await repo.read();
      expect(after.uid, before.uid);
    });
  });

  group('free-trip limit — 1-free-trip monetization change', () {
    test(
      'a newly created row is granted the current default limit (1), '
      'not the old global constant (3)',
      () async {
        final row = await repo.read(); // triggers ensureExists()
        expect(row.freeTripLimit, AppConstants.defaultFreeTripLimit);
        expect(row.freeTripLimit, 1);
      },
    );

    test(
      'a row that already existed before the free_trip_limit column was '
      'added keeps its migration-backfilled allowance (3), not the new '
      'default — this is what the v10 migration itself does; here we '
      'simulate that state directly and confirm the repository respects '
      'whatever is persisted rather than overwriting it',
      () async {
        final existing = await repo.read();
        // Simulate what the v10 migration's backfill does to a
        // pre-existing row: set free_trip_limit to the OLD default (3),
        // independent of whatever AppConstants.defaultFreeTripLimit is
        // today.
        await (db.update(
          db.userSettings,
        )..where((t) => t.id.equals(existing.id))).write(
          const UserSettingsCompanion(freeTripLimit: Value(3)),
        );
        final after = await repo.read();
        expect(after.freeTripLimit, 3);
        expect(after.freeTripLimit, isNot(AppConstants.defaultFreeTripLimit));
      },
    );
  });

  group('applyEntitlementCheck — fail-open on network errors', () {
    test('active sets isPro true', () async {
      await repo.applyEntitlementCheck(ProEntitlementCheck.active);
      expect((await repo.read()).isPro, isTrue);
    });

    test(
      'inactive (confirmed, not an error) sets isPro false — revokes a '
      'stale local Pro flag',
      () async {
        await repo.patch(const UserSettingsCompanion(isPro: Value(true)));
        await repo.applyEntitlementCheck(ProEntitlementCheck.inactive);
        expect((await repo.read()).isPro, isFalse);
      },
    );

    test(
      'unknown (transient failure) leaves an existing Pro flag untouched '
      '— a known-Pro user must never be revoked by a network error',
      () async {
        await repo.patch(const UserSettingsCompanion(isPro: Value(true)));
        await repo.applyEntitlementCheck(ProEntitlementCheck.unknown);
        expect((await repo.read()).isPro, isTrue);
      },
    );

    test(
      'unknown also leaves a non-Pro flag untouched (does not '
      'spuriously grant Pro either)',
      () async {
        await repo.applyEntitlementCheck(ProEntitlementCheck.unknown);
        expect((await repo.read()).isPro, isFalse);
      },
    );
  });
}
