import 'package:flutter/foundation.dart';

/// An accepted friendship between [ownerUid] and [friendUid].
///
/// [id] is a stable UUID (not the local Drift row id) so this entity can
/// later be sourced from Firestore without changing shape.
@immutable
class Friend {
  const Friend({
    required this.id,
    required this.ownerUid,
    required this.friendUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String friendUid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
