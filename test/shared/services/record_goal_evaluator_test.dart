import 'package:drive_rank/shared/services/record_goal_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('first trip ever', () {
    test('never counts as a record, even with a fast/long drive', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: true,
        priorBestSpeedKmh: 0,
        priorLongestKm: 0,
        activeSpeedGoalKmh: null,
        activeDistanceGoalKm: null,
        tripSpeedKmh: 180,
        tripDistanceKm: 60,
      );
      expect(result.newSpeedRecord, isFalse);
      expect(result.newDistanceRecord, isFalse);
    });

    test("still creates the initial goals from this trip's stats", () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: true,
        priorBestSpeedKmh: 0,
        priorLongestKm: 0,
        activeSpeedGoalKmh: null,
        activeDistanceGoalKm: null,
        tripSpeedKmh: 100,
        tripDistanceKm: 20,
      );
      expect(result.nextSpeedGoalKmh, isNotNull);
      expect(result.nextSpeedGoalKmh, greaterThan(100));
      expect(result.nextDistanceGoalKm, isNotNull);
      expect(result.nextDistanceGoalKm, greaterThan(20));
      // Nothing was "achieved" on the very first trip — there was no
      // prior goal to beat.
      expect(result.speedGoalAchieved, isFalse);
      expect(result.distanceGoalAchieved, isFalse);
    });

    test(
      'a trip with no GPS fix (0 speed/distance) does not produce a goal',
      () {
        // A trip that never got a real GPS fix (e.g. GPS unavailable
        // for the whole drive) saves with 0 top speed and 0 distance.
        // GoalCalculator.nextSpeedGoalKmh(0)/nextDistanceGoalKm(0) both
        // return 0 for that input — that must read as "no goal yet",
        // not get persisted as a literal 0, or Trip Summary renders a
        // useless "0 -> 0" goal card forever.
        final result = RecordGoalEvaluator.evaluate(
          isFirstTrip: true,
          priorBestSpeedKmh: 0,
          priorLongestKm: 0,
          activeSpeedGoalKmh: null,
          activeDistanceGoalKm: null,
          tripSpeedKmh: 0,
          tripDistanceKm: 0,
        );
        expect(result.nextSpeedGoalKmh, isNull);
        expect(result.nextDistanceGoalKm, isNull);
      },
    );
  });

  group('later trips', () {
    test('beating the prior best is a new record', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: null,
        activeDistanceGoalKm: null,
        tripSpeedKmh: 160,
        tripDistanceKm: 35, // shorter than the prior longest
      );
      expect(result.newSpeedRecord, isTrue);
      expect(result.newDistanceRecord, isFalse);
    });

    test('tying the prior best is NOT a new record (strictly greater)', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: null,
        activeDistanceGoalKm: null,
        tripSpeedKmh: 150,
        tripDistanceKm: 40,
      );
      expect(result.newSpeedRecord, isFalse);
      expect(result.newDistanceRecord, isFalse);
    });

    test('meeting the active goal exactly counts as achieved', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: 160,
        activeDistanceGoalKm: null,
        tripSpeedKmh: 160,
        tripDistanceKm: 10,
      );
      expect(result.speedGoalAchieved, isTrue);
      expect(result.nextSpeedGoalKmh, isNotNull);
      // The new goal is set relative to the new best (this trip's
      // speed, since it just became the record), not the old goal.
      expect(result.nextSpeedGoalKmh, greaterThan(160));
    });

    test('falling short of the active goal leaves it untouched', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: 160,
        activeDistanceGoalKm: 50,
        tripSpeedKmh: 155,
        tripDistanceKm: 45,
      );
      expect(result.speedGoalAchieved, isFalse);
      expect(result.distanceGoalAchieved, isFalse);
      expect(result.nextSpeedGoalKmh, isNull);
      expect(result.nextDistanceGoalKm, isNull);
    });

    test('a new record below the active goal is a record but not a goal '
        'achievement', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: 200, // ambitious goal, not yet reached
        activeDistanceGoalKm: null,
        tripSpeedKmh: 165, // beats 150, still short of 200
        tripDistanceKm: 10,
      );
      expect(result.newSpeedRecord, isTrue);
      expect(result.speedGoalAchieved, isFalse);
      // Goal doesn't change — it wasn't achieved, so it stays active.
      expect(result.nextSpeedGoalKmh, isNull);
    });

    test('both metrics can independently record/achieve in one trip', () {
      final result = RecordGoalEvaluator.evaluate(
        isFirstTrip: false,
        priorBestSpeedKmh: 150,
        priorLongestKm: 40,
        activeSpeedGoalKmh: 155,
        activeDistanceGoalKm: 45,
        tripSpeedKmh: 160,
        tripDistanceKm: 50,
      );
      expect(result.newSpeedRecord, isTrue);
      expect(result.newDistanceRecord, isTrue);
      expect(result.speedGoalAchieved, isTrue);
      expect(result.distanceGoalAchieved, isTrue);
      expect(result.nextSpeedGoalKmh, isNotNull);
      expect(result.nextDistanceGoalKm, isNotNull);
    });
  });
}
