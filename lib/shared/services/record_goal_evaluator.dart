import 'package:drive_rank/shared/services/goal_calculator.dart';
import 'package:flutter/foundation.dart';

/// Pure decision logic for "did this trip set a record / hit a goal,
/// and what's the next goal" — no I/O, no telemetry, no notifications.
/// `TrackingBloc` calls [RecordGoalEvaluator.evaluate] right after
/// saving a trip and turns the result into telemetry events, the
/// record-celebration notification, and a `UserSettingsRepository
/// .setGoals` write. Kept separate specifically so this decision logic
/// is unit-testable without standing up the bloc's full dependency
/// graph (GPS, sensors, notifications, etc).
@immutable
class RecordGoalEvaluation {
  const RecordGoalEvaluation({
    required this.newSpeedRecord,
    required this.newDistanceRecord,
    required this.speedGoalAchieved,
    required this.distanceGoalAchieved,
    required this.nextSpeedGoalKmh,
    required this.nextDistanceGoalKm,
  });

  /// This trip beat the prior all-time top speed. Always false when
  /// `isFirstTrip` was true — there's nothing to "beat" on trip #1.
  final bool newSpeedRecord;

  /// Same as [newSpeedRecord] for distance.
  final bool newDistanceRecord;

  /// This trip met or exceeded the speed goal that was active going
  /// into it. False when there was no active goal yet.
  final bool speedGoalAchieved;

  /// Same as [speedGoalAchieved] for distance.
  final bool distanceGoalAchieved;

  /// Non-null when a new speed goal should be persisted — either the
  /// user's first-ever goal, or a fresh one because the prior goal was
  /// just achieved. Null means "leave the existing goal alone."
  final double? nextSpeedGoalKmh;

  /// Same as [nextSpeedGoalKmh] for distance.
  final double? nextDistanceGoalKm;
}

class RecordGoalEvaluator {
  const RecordGoalEvaluator._();

  static RecordGoalEvaluation evaluate({
    required bool isFirstTrip,
    required double priorBestSpeedKmh,
    required double priorLongestKm,
    required double? activeSpeedGoalKmh,
    required double? activeDistanceGoalKm,
    required double tripSpeedKmh,
    required double tripDistanceKm,
  }) {
    // "Beats prior" is the true comparison used for the up-to-date best
    // (needed even on trip #1, where this trip's stats — not 0 — must
    // become the baseline the first goal is computed from). Whether it
    // counts as a *celebration-worthy* record is a separate question:
    // isFirstTrip suppresses that, since there's nothing to "beat" on
    // a first trip even though it trivially exceeds a prior best of 0.
    final beatsSpeed = tripSpeedKmh > priorBestSpeedKmh;
    final beatsDistance = tripDistanceKm > priorLongestKm;
    final newSpeedRecord = !isFirstTrip && beatsSpeed;
    final newDistanceRecord = !isFirstTrip && beatsDistance;

    final bestSpeedNow = beatsSpeed ? tripSpeedKmh : priorBestSpeedKmh;
    final bestDistanceNow = beatsDistance ? tripDistanceKm : priorLongestKm;

    final speedGoalAchieved =
        activeSpeedGoalKmh != null && tripSpeedKmh >= activeSpeedGoalKmh;
    final distanceGoalAchieved =
        activeDistanceGoalKm != null && tripDistanceKm >= activeDistanceGoalKm;

    final nextSpeedGoalKmh = (activeSpeedGoalKmh == null || speedGoalAchieved)
        ? GoalCalculator.nextSpeedGoalKmh(bestSpeedNow)
        : null;
    final nextDistanceGoalKm =
        (activeDistanceGoalKm == null || distanceGoalAchieved)
        ? GoalCalculator.nextDistanceGoalKm(bestDistanceNow)
        : null;

    return RecordGoalEvaluation(
      newSpeedRecord: newSpeedRecord,
      newDistanceRecord: newDistanceRecord,
      speedGoalAchieved: speedGoalAchieved,
      distanceGoalAchieved: distanceGoalAchieved,
      nextSpeedGoalKmh: nextSpeedGoalKmh,
      nextDistanceGoalKm: nextDistanceGoalKm,
    );
  }
}
