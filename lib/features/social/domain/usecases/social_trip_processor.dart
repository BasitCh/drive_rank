import 'package:drive_rank/features/social/domain/entities/competition_update.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';

/// Master switch for running the competition engine on trip completion.
///
/// A compile-time constant rather than a remote flag — there's no
/// remote-config channel in the app yet. It exists so a hotfix can stop
/// all social processing by flipping one line, without having to unpick
/// the tracking hook. The remotely-configurable rankings kill switch is
/// a separate, later concern: that one hides ranking *surfaces*, while
/// this one stops *writing* competition state.
const bool kSocialProcessingEnabled = true;

/// Runs the competition engine for one completed trip: eligibility,
/// challenge/target progress, and trophies.
///
/// Deliberately separate from `TrackingBloc` — the bloc owns the trip
/// lifecycle and nothing more. Callers invoke this fire-and-forget after
/// the trip is durably saved; it must never be something the save waits
/// on.
///
/// Takes the trip's data as parameters rather than reading it back:
/// `points` must be the in-memory capture-order list (see
/// `evaluateCompetitionEligibility` for why), and `uid` must be the uid
/// the trip was saved under, not one resolved later — those can differ
/// while sign-in is still settling.
// ignore: one_member_abstracts
abstract interface class SocialTripProcessor {
  Future<CompetitionUpdate> processCompletedTrip({
    required int tripId,
    required String uid,
    required List<TripPoint> points,
    required double distanceKm,
    required int durationSeconds,
    required DateTime startedAt,
    String? tripRemoteId,
  });
}
