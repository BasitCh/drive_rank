import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/features/social/domain/usecases/rank_entries.dart';
import 'package:injectable/injectable.dart';

/// The board, scoped to people the viewer actually knows.
///
/// Produces the same `Leaderboard` as `GetGlobalLeaderboard`, so the
/// podium, the rows, the rank card and the compare sheet are all
/// indifferent to which one ran — that indifference is what 3c's UI was
/// built for.
///
/// **The three sides of a row come from three different places, and
/// deliberately so:**
///
///  * the viewer's value is *computed* from local trips, exactly as on
///    the global board. Never read back from what they published — a
///    stale snapshot of yourself must not become the source of truth
///    for your own rank;
///  * a friend's value is whatever their device last published. Self-
///    reported, which is the trust model this phase inherits, and
///    timestamped so a row can say when it's old;
///  * a benchmark's value is a fixed constant.
@injectable
class GetFriendsLeaderboard {
  const GetFriendsLeaderboard(this._social, this._calculator);

  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  /// [friendProfiles] is what the caller managed to fetch — a friend
  /// missing from it is a friend who hasn't published, not a friend who
  /// drove nothing.
  Future<Leaderboard> call({
    required String uid,
    required String displayName,
    required CompetitionMetric metric,
    required LeaderboardPeriod period,
    required List<CompetitionMirror> friendProfiles,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final window = CompetitionWindow.forPeriod(period, at);

    final trips = await _social.getCompetitionTrips(uid: uid, window: window);
    final me = LeaderboardEntry(
      id: uid,
      displayName: displayName,
      value: _calculator.calculate(
        metric: metric,
        trips: trips,
        window: window,
      ),
      participantType: LeaderboardParticipantType.realUser,
      isCurrentUser: true,
    );

    final friends = <LeaderboardEntry>[];
    for (final profile in friendProfiles) {
      // Absent is not zero. A friend who never published this metric —
      // or published before the field existed — is unknown, and ranking
      // them at the bottom would assert something about them that their
      // data doesn't say.
      if (!profile.hasTotalFor(metric, period)) continue;

      friends.add(
        LeaderboardEntry(
          id: profile.uid,
          displayName: profile.username.isEmpty
              ? profile.uid
              : profile.username,
          value: profile.totalFor(metric, period),
          participantType: LeaderboardParticipantType.realUser,
          countryCode: profile.countryCode,
          carMake: profile.carMake,
          carModel: profile.carModel,
          publishedAt: profile.updatedAt,
          isStale: profile.isStaleAt(at),
        ),
      );
    }

    // Real people only. A friends board is the people you chose, so a
    // published constant has no place among them — and the podium it
    // leaves always holds somebody who actually drove.
    final realCompetitors = [me, ...friends];

    return Leaderboard(
      positions: rankEntries(realCompetitors),
      realCompetitorCount: realCompetitors.length,
      benchmarksShown: false,
    );
  }
}
