import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';

/// What one driver publishes about themselves for others to rank against.
///
/// **This is the MVP trust model, and it is self-reported.** Every value
/// here is computed on the owner's device and written by the owner's
/// client. Firestore rules can guarantee *who wrote it* — nobody can
/// inflate someone else's figures, delete them, or post under their name
/// — but they cannot guarantee the numbers are true. Friends-scale
/// competition is the setting that makes that acceptable: the worst
/// available cheat is overstating your own driving to people who invited
/// you, and every write is attributable to the account that made it.
///
/// **Escalation trigger.** The moment a ranking carries real stakes —
/// prizes, paid competition, or a public global ranking of strangers —
/// this stops being sufficient and the values must come from a
/// server-authoritative path instead. Widening the mirror's read rule to
/// build a strangers' leaderboard is a one-line change and exactly the
/// thing not to do: it is the point at which validation has to move off
/// the client, not the point at which the existing surface gets shared
/// more widely.
///
/// Deliberately narrow: identity plus totals. No trips, no coordinates,
/// no routes, no photo. A public mirror is a directory, and a directory
/// should hold the least that makes the feature work.
@immutable
class CompetitionMirror {
  const CompetitionMirror({
    required this.uid,
    required this.username,
    required this.carMake,
    required this.carModel,
    required this.countryCode,
    required this.inviteCode,
    required this.totals,
  });

  final String uid;
  final String username;
  final String carMake;
  final String carModel;
  final String countryCode;

  /// The short code this driver shares to be added as a friend, derived
  /// from their uid. Published here because a lookup needs somewhere to
  /// look — see `inviteCodeFor`.
  final String inviteCode;

  /// One value per metric and period — nine in all. Keyed rather than
  /// nine named fields so adding a metric doesn't reshape the document.
  final Map<(CompetitionMetric, LeaderboardPeriod), double> totals;

  /// Firestore field name for one metric/period pair, e.g.
  /// `distance_weekly`. Flat keys rather than nested maps so a rules
  /// field whitelist can name them.
  static String fieldFor(CompetitionMetric metric, LeaderboardPeriod period) =>
      '${metric.name}_${period.name}';

  /// Every field name the document may carry — the rules whitelist and
  /// this list have to agree, so it is generated from the same source
  /// rather than typed twice.
  static List<String> get allFields => [
    'username',
    'usernameLower',
    'carMake',
    'carModel',
    'countryCode',
    'inviteCode',
    'updatedAt',
    for (final metric in CompetitionMetric.values)
      for (final period in LeaderboardPeriod.values) fieldFor(metric, period),
  ];

  double totalFor(CompetitionMetric metric, LeaderboardPeriod period) =>
      totals[(metric, period)] ?? 0;
}
