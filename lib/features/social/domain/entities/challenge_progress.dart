import 'package:flutter/foundation.dart';

/// A participant's running tally toward a challenge's target.
///
/// Identity is the `(challengeId, uid)` pair itself — a pure junction
/// entity, so unlike the other social entities it carries no separate
/// UUID `id` of its own.
@immutable
class ChallengeProgress {
  const ChallengeProgress({
    required this.challengeId,
    required this.uid,
    required this.currentValue,
    required this.targetValue,
    this.lastCalculatedAt,
    this.completedAt,
  });

  final String challengeId;
  final String uid;
  final double currentValue;
  final double targetValue;
  final DateTime? lastCalculatedAt;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;
}
