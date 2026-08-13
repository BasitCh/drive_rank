import 'dart:ui';

import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
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
}
