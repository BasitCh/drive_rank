import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';

/// Total eligible distance (km) inside [window].
///
/// A trip belongs to the window containing its `startedAt` and is never
/// split across a boundary, so a drive from 23:50 Sunday to 00:30 Monday
/// counts entirely toward the Sunday week.
double calculateDistanceKm({
  required List<CompetitionTrip> trips,
  required CompetitionWindow window,
}) {
  var total = 0.0;
  for (final trip in trips) {
    if (!trip.eligible) continue;
    if (!window.contains(trip.startedAt)) continue;
    total += trip.distanceKm;
  }
  return total;
}
