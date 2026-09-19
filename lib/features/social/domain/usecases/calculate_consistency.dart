import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/consistency_qualification_policy.dart';

/// Number of distinct local calendar days inside [window] that contain
/// at least one eligible, qualifying trip.
///
/// Days are keyed off each trip's local `startedAt` day — never off its
/// waypoint timestamps. After a pause/resume a single trip's points can
/// span two calendar days with no driving in between, so bucketing by
/// points would invent consistency days the user didn't earn.
double calculateConsistencyDays({
  required List<CompetitionTrip> trips,
  required CompetitionWindow window,
  ConsistencyQualificationPolicy policy =
      const ConsistencyQualificationPolicy(),
}) {
  final days = <int>{};
  for (final trip in trips) {
    if (!trip.eligible) continue;
    if (!window.contains(trip.startedAt)) continue;
    if (!policy.qualifies(trip)) continue;
    days.add(trip.localDayKey);
  }
  return days.length.toDouble();
}
