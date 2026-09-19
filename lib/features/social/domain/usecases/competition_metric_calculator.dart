import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_consistency.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_distance.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_longest_trip.dart';
import 'package:injectable/injectable.dart';

/// Turns a set of trips into one competition value.
///
/// This interface is the backend-migration seam: today the value is
/// computed on the client from local trips, and later a trusted backend
/// becomes authoritative. Nothing above this line — challenges,
/// trophies, blocs, UI — should care which it was, so replacing the
/// implementation must be the whole change.
// ignore: one_member_abstracts
abstract interface class CompetitionMetricCalculator {
  double calculate({
    required CompetitionMetric metric,
    required List<CompetitionTrip> trips,
    required CompetitionWindow window,
  });
}

/// Dispatches to the per-metric pure functions. Deliberately holds no
/// state and does no I/O — the trips are handed to it.
@LazySingleton(as: CompetitionMetricCalculator)
class DefaultCompetitionMetricCalculator
    implements CompetitionMetricCalculator {
  const DefaultCompetitionMetricCalculator();

  @override
  double calculate({
    required CompetitionMetric metric,
    required List<CompetitionTrip> trips,
    required CompetitionWindow window,
  }) => switch (metric) {
    CompetitionMetric.distance => calculateDistanceKm(
      trips: trips,
      window: window,
    ),
    CompetitionMetric.longestTrip => calculateLongestTripKm(
      trips: trips,
      window: window,
    ),
    CompetitionMetric.consistency => calculateConsistencyDays(
      trips: trips,
      window: window,
    ),
  };
}
