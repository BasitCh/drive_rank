import 'package:flutter/foundation.dart';

/// A user that appears in the username search result list — minimal
/// projection of the public `/users/{uid}` doc.
@immutable
class FriendSearchResult {
  const FriendSearchResult({
    required this.uid,
    required this.username,
    required this.carName,
    required this.requestSent,
    required this.alreadyFriend,
  });

  final String uid;
  final String username;
  final String carName;

  /// True if the current user has already sent a pending request to
  /// this user — used to flip the Add button to "Sent ✓".
  final bool requestSent;

  /// True if this user is already in the current user's friends list.
  final bool alreadyFriend;

  FriendSearchResult copyWith({
    bool? requestSent,
    bool? alreadyFriend,
  }) {
    return FriendSearchResult(
      uid: uid,
      username: username,
      carName: carName,
      requestSent: requestSent ?? this.requestSent,
      alreadyFriend: alreadyFriend ?? this.alreadyFriend,
    );
  }
}

/// One incoming friend request — the profile renders these with
/// Accept / Decline buttons.
@immutable
class IncomingFriendRequest {
  const IncomingFriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromUsername;
  final DateTime createdAt;
}

/// A confirmed friend in the current user's friend list. Watched
/// reactively by the leaderboard's Friends tab.
@immutable
class Friend {
  const Friend({
    required this.uid,
    required this.username,
    required this.addedAt,
  });

  final String uid;
  final String username;
  final DateTime addedAt;
}

/// Status of a sent friend request — drives the Add button UI state.
enum FriendRequestStatus { pending, accepted, declined }
