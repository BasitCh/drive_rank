import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:flutter/foundation.dart';

/// What counts as a real drive for the consistency metric.
///
/// A fixed product rule, never personalized — consistency compares users
/// against each other, so the bar can't move per account. (Note it sits
/// *above* the user-configurable `minTripLengthMeters` discard floor,
/// which defaults to 500 m: a 700 m drive is saved and counts toward
/// distance, but doesn't earn a consistency day.)
@immutable
class ConsistencyQualificationPolicy {
  const ConsistencyQualificationPolicy({
    this.minimumDistanceKm = 1,
    this.minimumDuration = const Duration(minutes: 5),
  });

  final double minimumDistanceKm;
  final Duration minimumDuration;

  /// Whether [trip] is a real enough drive to earn its day.
  ///
  /// Duration is judged on the trip's recorded active duration, not
  /// `endedAt - startedAt` — those differ whenever a trip was paused,
  /// and the active figure is the one the rest of the app treats as the
  /// trip's length.
  bool qualifies(CompetitionTrip trip) =>
      trip.distanceKm >= minimumDistanceKm &&
      trip.durationSeconds >= minimumDuration.inSeconds;
}
