import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:flutter/foundation.dart';

/// One row's worth of standing.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.value,
    required this.participantType,
    this.isCurrentUser = false,
    this.countryCode = '',
    this.carMake = '',
    this.carModel = '',
    this.publishedAt,
    this.isStale = false,
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

  /// Where this driver drives and what they drive.
  ///
  /// Empty for a benchmark, always — a benchmark is not from anywhere
  /// and drives nothing, and inventing either would make a published
  /// constant look like a person. Empty for the viewer too: their own
  /// identity is read from their settings row, which is fresher than
  /// anything they published.
  final String countryCode;
  final String carMake;
  final String carModel;

  /// When a real competitor's figure was published, or null when it
  /// wasn't published at all — the viewer's own value is computed, and
  /// a benchmark's is a constant.
  final DateTime? publishedAt;

  /// Whether [value] is old enough that presenting it as current would
  /// be a small lie. The row says so; the value still ranks, because a
  /// friend vanishing because their phone was off reads as a bug to
  /// both of them.
  final bool isStale;

  bool get isBenchmark =>
      participantType == LeaderboardParticipantType.benchmark;

  /// Whether this row describes a person whose car and country are
  /// known — true for a friend, false for a benchmark and for the
  /// viewer, whose identity comes from settings instead.
  bool get hasPublishedIdentity =>
      !isBenchmark && (countryCode.isNotEmpty || carMake.isNotEmpty);
}
