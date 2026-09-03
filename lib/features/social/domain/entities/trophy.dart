import 'package:flutter/foundation.dart';

enum TrophyType {
  firstGoal,
  firstChallenge,
  firstWin,
  rankClimber,
  roadWarrior,
  consistent,
  rivalHunter;

  static TrophyType fromName(String name) =>
      TrophyType.values.firstWhere((t) => t.name == name, orElse: () => firstGoal);
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
