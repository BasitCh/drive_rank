import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/consistency_qualification_policy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:injectable/injectable.dart';

/// Which days inside a window actually had a qualifying drive.
///
/// `calculateConsistencyDays` builds exactly this set and then returns
/// only its size, so the streak strip would otherwise have to re-derive
/// it — and would drift from the metric the moment the qualification bar
/// changed. Same policy, same eligibility filter, same day keying; the
/// only difference is that the set survives.
///
/// Days are keyed the way `CompetitionTrip.localDayKey` keys them
/// (`y*10000 + m*100 + d`, off the trip's local `startedAt`), so a drive
/// that ran past midnight belongs to the day it began — the same rule
/// consistency scoring already uses.
@injectable
class GetQualifyingDays {
  const GetQualifyingDays(this._social);

  final SocialRepository _social;

  Future<Set<int>> call({
    required String uid,
    required CompetitionWindow window,
    ConsistencyQualificationPolicy policy =
        const ConsistencyQualificationPolicy(),
  }) async {
    final trips = await _social.getCompetitionTrips(uid: uid, window: window);
    final days = <int>{};
    for (final trip in trips) {
      if (!trip.eligible) continue;
      if (!window.contains(trip.startedAt)) continue;
      if (!policy.qualifies(trip)) continue;
      days.add(trip.localDayKey);
    }
    return days;
  }
}
