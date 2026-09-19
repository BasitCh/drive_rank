import 'package:flutter/foundation.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,

  /// The friendship this request created has since been ended.
  ///
  /// Exists because requests are never deleted, and the sync's
  /// self-healing pass treats "accepted request, no friendship" as "the
  /// friendship write never landed" and creates it. After an unfriend
  /// that shape is identical — so without this state, the healing
  /// resurrects a friendship somebody deliberately ended, on any device
  /// that syncs. Found by the two-account walkthrough, which is the only
  /// place it could have been found.
  ///
  /// Unfriending therefore ends the request and deletes the friendship
  /// in one batch: both land or neither does.
  ///
  /// **Not terminal.** The sender may re-open an ended request as
  /// [pending], because a request id is derived from the pair — so
  /// "re-friending starts a new request" cannot mean a new document.
  /// While this was treated as final, two people who unfriended could
  /// never become friends again from either side; the rules refused the
  /// write and the local guard didn't even attempt it.
  ended;

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
