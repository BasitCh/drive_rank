import 'package:drive_rank/shared/services/goal_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextSpeedGoalKmh', () {
    test('returns 0 for a non-positive best (no trips yet)', () {
      expect(GoalCalculator.nextSpeedGoalKmh(0), 0);
      expect(GoalCalculator.nextSpeedGoalKmh(-5), 0);
    });

    test('is always strictly greater than the current best', () {
      for (final best in [10.0, 45.0, 90.0, 168.0, 199.0, 250.0]) {
        expect(
          GoalCalculator.nextSpeedGoalKmh(best),
          greaterThan(best),
          reason: 'goal for best=$best should exceed the best itself',
        );
      }
    });

    test('is a multiple of 5', () {
      expect(GoalCalculator.nextSpeedGoalKmh(168) % 5, 0);
      expect(GoalCalculator.nextSpeedGoalKmh(97) % 5, 0);
    });

    test('small bests still get a real minimum step, not a 0 increment', () {
      // 1 * 1.05 = 1.05, which rounds to 0 on a 5-wide grid — without
      // the minimum-step guard this would return 0, which isn't even
      // greater than the input.
      expect(GoalCalculator.nextSpeedGoalKmh(1), 5);
    });
  });

  group('nextDistanceGoalKm', () {
    test('returns 0 for a non-positive best (no trips yet)', () {
      expect(GoalCalculator.nextDistanceGoalKm(0), 0);
    });

    test('is always strictly greater than the current best', () {
      for (final best in [5.0, 20.0, 51.3, 100.0]) {
        expect(GoalCalculator.nextDistanceGoalKm(best), greaterThan(best));
      }
    });

    test('is a multiple of 5', () {
      expect(GoalCalculator.nextDistanceGoalKm(51.3) % 5, 0);
    });
  });
}
