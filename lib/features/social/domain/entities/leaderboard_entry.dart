import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:flutter/foundation.dart';

/// One competitor on a leaderboard, with the value they're ranked on but
/// **not** the rank itself.
///
/// Rank is derived by sorting values, never stored — a stored rank
/// written by a client is a number the client got to choose, and it goes
/// stale the moment anyone else drives. See `LeaderboardPosition` for a
/// row that has been placed.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.value,
    required this.participantType,
    this.isCurrentUser = false,
  });

  /// A real user's uid, or the benchmark's stable id.
  final String id;

  final String displayName;

  /// The metric value, in the metric's own unit — kilometres for
  /// distance and longest trip, days for consistency.
  final double value;

  final LeaderboardParticipantType participantType;

  /// Whether this row is the viewer. Kept on the entry so the UI never
  /// has to compare uids itself.
  final bool isCurrentUser;

  bool get isBenchmark =>
      participantType == LeaderboardParticipantType.benchmark;
}
