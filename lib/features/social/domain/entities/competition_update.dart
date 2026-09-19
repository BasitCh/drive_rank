import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:flutter/foundation.dart';

/// Everything the competition engine concluded from one completed trip.
///
/// Rank movement is deliberately absent: nothing produces ranks yet
/// (there's no leaderboard until the ranking phase). It's added here
/// additively when it exists, which is why callers should treat this as
/// a growing result bundle rather than a fixed record.
@immutable
class CompetitionUpdate {
  const CompetitionUpdate({
    required this.tripId,
    required this.uid,
    required this.eligibility,
    this.updatedProgress = const [],
    this.completedChallengeIds = const [],
    this.expiredChallengeIds = const [],
    this.unlockedTrophies = const [],
  });

  /// A trip that was recorded but not evaluated further — used for the
  /// pre-auth `'local'` placeholder uid, where writing per-user social
  /// rows would strand them under an id that's about to be rewritten.
  const CompetitionUpdate.eligibilityOnly({
    required this.tripId,
    required this.uid,
    required this.eligibility,
  }) : updatedProgress = const [],
       completedChallengeIds = const [],
       expiredChallengeIds = const [],
       unlockedTrophies = const [];

  final int tripId;
  final String uid;
  final CompetitionEligibility eligibility;
  final List<ChallengeProgress> updatedProgress;
  final List<String> completedChallengeIds;
  final List<String> expiredChallengeIds;

  /// Trophies unlocked *by this trip* — already-held trophies are not
  /// repeated here, so this is safe to drive a celebration from.
  final List<Trophy> unlockedTrophies;

  bool get hasSomethingToShow =>
      completedChallengeIds.isNotEmpty ||
      unlockedTrophies.isNotEmpty ||
      updatedProgress.isNotEmpty;
}
