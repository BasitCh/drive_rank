import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';

/// Source of friends, friend requests, challenges, trophies, and the
/// trips competition is computed from.
///
/// Local-only (Drift-backed) for now. See the backend-migration note in
/// the Social Competition plan: the trigger for moving this behind a
/// trusted backend is the first time a user's ranking position, score,
/// or competitive outcome is determined by a value written by another
/// user's client.
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

  /// Moves a challenge to [status], unless it's already in a terminal
  /// one — completed and expired results are immutable history.
  /// Returns whether the transition happened.
  Future<bool> updateChallengeStatus({
    required String challengeId,
    required ChallengeStatus status,
  });
  Future<void> deleteChallenge(String challengeId);

  /// The user's active challenges whose window contains [at], and those
  /// whose window has already closed — the two sets the competition
  /// engine acts on when a trip lands.
  Future<List<Challenge>> getActiveChallengesAt({
    required String uid,
    required DateTime at,
  });
  Future<List<Challenge>> getLapsedActiveChallenges({
    required String uid,
    required DateTime at,
  });

  // Challenge progress
  Future<List<ChallengeProgress>> getProgressForChallenge(String challengeId);
  Future<ChallengeProgress?> getProgress({
    required String challengeId,
    required String uid,
  });

  /// Writes a recomputed tally. Touches only the value — completion is
  /// stamped separately by [markProgressComplete] and never cleared,
  /// because a recompute can legitimately *lower* the value (the user
  /// deleted a trip) and that must not un-complete a finished target.
  Future<void> upsertProgressValue(ChallengeProgress progress);
  Future<void> markProgressComplete({
    required String challengeId,
    required String uid,
    required DateTime completedAt,
  });

  // Trophies
  Stream<List<Trophy>> watchTrophies(String uid);
  Future<List<Trophy>> getTrophies(String uid);

  /// Awards a trophy idempotently, returning it when it was newly
  /// unlocked and **null** when the user already had it — so callers can
  /// celebrate only real unlocks. Requires a deterministic id from
  /// `trophyRemoteId`.
  Future<Trophy?> awardTrophy(Trophy trophy);

  // Competition inputs
  /// Trips of [uid] started inside [window], each carrying its
  /// eligibility verdict (a trip with no verdict reads as eligible).
  Future<List<CompetitionTrip>> getCompetitionTrips({
    required String uid,
    required CompetitionWindow window,
  });

  Future<void> recordTripEligibility({
    required int tripId,
    required CompetitionEligibility eligibility,
    required DateTime startedAt,
    String? tripRemoteId,
  });
  Future<CompetitionEligibility?> getTripEligibility(int tripId);

  // --- Later phases add leaderboard + remote-sync methods here, e.g.:
  //   Stream<List<LeaderboardEntry>> watchLeaderboard(...);
  //   Future<void> syncFromRemote(...);
  // Purely additive — no existing signature above needs to change.
}
