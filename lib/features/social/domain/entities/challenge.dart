import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';

/// A competition metric a leaderboard, challenge, or target is measured
/// on. Deliberately excludes top speed — that stays a personal-best
/// metric, never a public ranking one.
enum CompetitionMetric {
  distance,
  longestTrip,
  consistency;

  static CompetitionMetric fromName(String name) => CompetitionMetric.values
      .firstWhere((m) => m.name == name, orElse: () => distance);
}

enum ChallengeStatus {
  pending,
  active,
  completed,
  expired,
  declined,
  cancelled;

  static ChallengeStatus fromName(String name) => ChallengeStatus.values
      .firstWhere((s) => s.name == name, orElse: () => pending);
}

/// A head-to-head challenge against [opponentUid], or a personal target
/// when [opponentUid] is null — targets aren't competitive against
/// another user, so [isPersonal] call sites should treat them as
/// self-improvement mechanics, not a rivalry.
///
/// [id] is a stable UUID (not the local Drift row id) so this entity can
/// later be sourced from Firestore without changing shape.
@immutable
class Challenge {
  const Challenge({
    required this.id,
    required this.creatorUid,
    required this.metric,
    required this.targetValue,
    required this.period,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.opponentUid,
  });

  final String id;
  final String creatorUid;
  final String? opponentUid;
  final CompetitionMetric metric;
  final double targetValue;
  final LeaderboardPeriod period;
  final DateTime startAt;
  final DateTime endAt;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPersonal => opponentUid == null;
}
