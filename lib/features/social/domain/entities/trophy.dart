import 'package:flutter/foundation.dart';

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
