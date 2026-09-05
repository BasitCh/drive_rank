import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:flutter/foundation.dart';

/// A personal target with its live progress.
///
/// A view type, not a stored one: [currentValue] is recomputed from
/// eligible trips every time it's read, like every other aggregate in
/// this feature. That's what lets a target created *after* the driving
/// show its real progress immediately instead of sitting at zero until
/// the next trip.
///
/// [completedAt] is the exception — it comes from the persisted
/// `challenge_progress` row, because "when did I finish this" is a fact
/// about the past that must survive a later trip deletion pushing the
/// live value back below the target.
@immutable
class Target {
  const Target({
    required this.challenge,
    required this.currentValue,
    this.completedAt,
  });

  final Challenge challenge;
  final double currentValue;
  final DateTime? completedAt;

  double get targetValue => challenge.targetValue;

  bool get isComplete => completedAt != null;

  /// How far along, clamped to `[0, 1]`. A non-positive target reads as
  /// no progress rather than dividing by zero into a full bar.
  double get progress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// What's left to do. Zero once reached, never negative.
  double get remaining {
    final left = targetValue - currentValue;
    return left <= 0 ? 0 : left;
  }
}
