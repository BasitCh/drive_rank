import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

enum TrophyType {
  /// First personal target completed — a `Challenge` with no opponent.
  /// Named "target", not "goal", to stay distinct from the
  /// speed/distance goals `RecordGoalEvaluator` drives, which are a
  /// separate personal-best mechanic.
  firstTarget,
  firstChallenge,
  firstWin,
  rankClimber,
  roadWarrior,
  consistent,
  rivalHunter;

  String get title => switch (this) {
    firstTarget => AppStrings.trophyFirstTargetTitle,
    firstChallenge => AppStrings.trophyFirstChallengeTitle,
    firstWin => AppStrings.trophyFirstWinTitle,
    rankClimber => AppStrings.trophyRankClimberTitle,
    roadWarrior => AppStrings.trophyRoadWarriorTitle,
    consistent => AppStrings.trophyConsistentTitle,
    rivalHunter => AppStrings.trophyRivalHunterTitle,
  };

  String get description => switch (this) {
    firstTarget => AppStrings.trophyFirstTargetBody,
    firstChallenge => AppStrings.trophyFirstChallengeBody,
    firstWin => AppStrings.trophyFirstWinBody,
    rankClimber => AppStrings.trophyRankClimberBody,
    roadWarrior => AppStrings.trophyRoadWarriorBody,
    consistent => AppStrings.trophyConsistentBody,
    rivalHunter => AppStrings.trophyRivalHunterBody,
  };

  /// One solid, high-contrast glyph each.
  ///
  /// These render at 22px inside a 44px badge, so anything with internal
  /// detail turns to mush — which is why the two-figure `sports_kabaddi`
  /// and the hairline `my_location` crosshair are not used. Each shape
  /// also has to be distinguishable from the other six at a glance in a
  /// two-column grid.
  IconData get icon => switch (this) {
    firstTarget => Icons.flag_rounded,
    firstChallenge => Icons.sports_mma_rounded,
    firstWin => Icons.emoji_events_rounded,
    rankClimber => Icons.trending_up_rounded,
    roadWarrior => Icons.local_fire_department_rounded,
    consistent => Icons.event_available_rounded,
    rivalHunter => Icons.military_tech_rounded,
  };

  /// Whether anything in the app can currently award this trophy.
  ///
  /// Four of the seven can't be: three need an opponent's data and one
  /// needs a real ranking, neither of which exists yet. A grid that
  /// showed them alongside the earnable ones with no distinction would
  /// be telling the user to chase something unreachable, so the UI
  /// states the reason instead — see [unavailableReason].
  bool get isEarnableNow => switch (this) {
    firstTarget || roadWarrior || consistent => true,
    firstChallenge || firstWin || rivalHunter || rankClimber => false,
  };

  /// Why an unearnable trophy can't be earned yet. Null when it can.
  String? get unavailableReason => switch (this) {
    firstTarget || roadWarrior || consistent => null,
    firstChallenge || firstWin || rivalHunter =>
      AppStrings.trophyNeedsFriends,
    rankClimber => AppStrings.trophyNeedsRivals,
  };

  static TrophyType fromName(String name) => TrophyType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => firstTarget,
  );
}

/// A trophy [uid] unlocked at [unlockedAt].
///
/// [id] is a stable UUID (not the local Drift row id) so this entity can
/// later be sourced from Firestore without changing shape.
@immutable
class Trophy {
  const Trophy({
    required this.id,
    required this.uid,
    required this.type,
    required this.unlockedAt,
    this.metadataJson,
  });

  final String id;
  final String uid;
  final TrophyType type;
  final DateTime unlockedAt;
  final String? metadataJson;
}
