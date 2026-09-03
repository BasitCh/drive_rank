import 'package:flutter/foundation.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  static FriendRequestStatus fromName(String name) =>
      FriendRequestStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => pending,
      );
}

/// An invite from [fromUid] to [toUid] to become friends.
///
/// [id] is a stable UUID (not the local Drift row id) so this entity can
/// later be sourced from Firestore without changing shape.
@immutable
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
