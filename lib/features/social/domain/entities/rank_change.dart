import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';

/// Rank movement **caused by one specific trip**.
///
/// Deferred from Phase 1 because nothing produced ranks then. It's
/// derived, never stored: the board is built twice — once as it stands
/// and once with the trip excluded — and the two ranks diffed. That's
/// what makes the movement attributable. A stored "previous rank" would
/// drift with every other change to the board and let the card claim
/// credit for movement this trip had nothing to do with.
///
/// [passedNames] are the entries actually overtaken, so the copy can
/// name them rather than assert an unattributable count.
@immutable
class RankChange {
  const RankChange({
    required this.metric,
    required this.period,
    required this.previousRank,
    required this.newRank,
    this.passedNames = const [],
  });

  final CompetitionMetric metric;
  final LeaderboardPeriod period;

  /// Where the viewer would sit without this trip.
  final int previousRank;

  /// Where they sit with it.
  final int newRank;

  /// Best first — whoever was overtaken.
  final List<String> passedNames;

  /// Positive when the viewer climbed. A lower rank number is better,
  /// so this is deliberately the inverse of the raw difference.
  int get positionsMoved => previousRank - newRank;

  bool get improved => positionsMoved > 0;
}
