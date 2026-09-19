import 'package:flutter/foundation.dart';

/// Why a trip was excluded from competition.
///
/// The two plausibility reasons are **not** interchangeable, even though
/// they share thresholds: [impossibleJump] is evidence from `lat/lng`
/// (the position moved further than any road vehicle could), while
/// [suspiciousSpeedPattern] is evidence from the reported speed channel
/// (the speed series itself is physically inconsistent). A spoofer who
/// fakes coordinates trips the first; a device reporting glitched speeds
/// over sane coordinates trips the second.
enum EligibilityFailureReason {
  insufficientGpsQuality,
  impossibleJump,
  invalidTimestampSequence,
  suspiciousSpeedPattern,
  mockLocationDetected,
  insufficientTripData;

  static EligibilityFailureReason? fromName(String name) =>
      EligibilityFailureReason.values
          .where((r) => r.name == name)
          .firstOrNull;
}

/// The verdict on whether one trip counts toward competition.
///
/// A trip that fails is still recorded and still shows in History —
/// "recorded" and "leaderboard-eligible" are separate decisions.
///
/// These are client-side heuristics, not authoritative anti-cheat. The
/// security boundary arrives with the backend migration, whose trigger
/// is the first time a user's ranking position, score, or competitive
/// outcome is determined by a value written by another user's client.
@immutable
class CompetitionEligibility {
  const CompetitionEligibility({
    this.reasons = const [],
    this.mockedSampleCount = 0,
  });

  /// Every rule that failed, not just the first — a trip can be both
  /// low-quality and implausible, and the record should say so.
  final List<EligibilityFailureReason> reasons;

  final int mockedSampleCount;

  bool get eligible => reasons.isEmpty;

  /// The reason to lead with in UI copy.
  EligibilityFailureReason? get primaryReason => reasons.firstOrNull;
}
