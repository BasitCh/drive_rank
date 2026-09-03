import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';

/// Source of friends, friend requests, challenges and trophies.
///
/// Phase 1 is local-only (Drift-backed). A later phase adds
/// leaderboard/remote-sync methods here — purely additive, so nothing
/// above needs to change when that happens. See the backend-migration
/// note in the Social Competition plan: the trigger for moving this
/// behind a trusted backend is the first time a user's ranking position,
/// score, or competitive outcome is determined by a value written by
/// another user's client.
abstract class SocialRepository {
  // Friends
  Future<List<Friend>> getFriends(String uid);
  Stream<List<Friend>> watchFriends(String uid);
  Future<Friend> addFriend({required String ownerUid, required String friendUid});
  Future<void> removeFriend({required String ownerUid, required String friendUid});
  Future<bool> areFriends(String uidA, String uidB);

  // Friend requests
  Stream<List<FriendRequest>> watchIncomingRequests(String uid);
  Future<List<FriendRequest>> getOutgoingRequests(String uid);
  Future<FriendRequest> sendFriendRequest({
    required String fromUid,
    required String toUid,
  });
  Future<void> respondToFriendRequest({
    required String requestId,
    required FriendRequestStatus response,
  });
  Future<void> cancelFriendRequest(String requestId);

  // Challenges
  Stream<List<Challenge>> watchChallenges(String uid); // creator OR opponent
  Future<Challenge?> getChallengeById(String id);
  Future<Challenge> createChallenge(Challenge challenge);
  Future<void> updateChallengeStatus({
    required String challengeId,
    required ChallengeStatus status,
  });
  Future<void> deleteChallenge(String challengeId);

  // Challenge progress
  Future<List<ChallengeProgress>> getProgressForChallenge(String challengeId);
  Future<void> upsertProgress(ChallengeProgress progress);

  // Trophies
  Stream<List<Trophy>> watchTrophies(String uid);
  Future<Trophy> awardTrophy(Trophy trophy);
}
