import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';

/// Longest single eligible trip (km) inside [window], or 0 when none.
double calculateLongestTripKm({
  required List<CompetitionTrip> trips,
  required CompetitionWindow window,
}) {
  var longest = 0.0;
  for (final trip in trips) {
    if (!trip.eligible) continue;
    if (!window.contains(trip.startedAt)) continue;
    if (trip.distanceKm > longest) longest = trip.distanceKm;
  }
  return longest;
}
