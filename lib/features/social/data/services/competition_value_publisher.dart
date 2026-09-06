import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/social/data/processors/local_social_trip_processor.dart'
    show kLocalPlaceholderUid;
import 'package:drive_rank/features/social/data/services/competition_mirror_sink.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/invite_code.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Publishes this user's own competitive totals so friends can rank
/// against them.
///
/// Recomputes rather than accumulates, like every other aggregate in
/// this feature — which is what makes a deleted trip lower the published
/// figure instead of leaving an inflated total behind, and what makes
/// the write idempotent.
///
/// **Self-reported by design at this stage** — see [CompetitionMirror]
/// for the trust model and the trigger that ends it.
///
/// Runs on three occasions, all of which change what should be
/// published:
///  * a trip finishes — the totals moved;
///  * the app starts — a window may have rolled over, so last week's
///    figures are no longer this week's;
///  * an identity field changes — username, car or country. Without
///    this one, someone who changes cars after their last drive shows
///    their old car to every friend until they next drive, and the
///    mirror is what friend boards and profiles render from.
@lazySingleton
class CompetitionValuePublisher {
  CompetitionValuePublisher(this._settings, this._social, this._calculator);

  final UserSettingsRepository _settings;
  final SocialRepository _social;
  final CompetitionMetricCalculator _calculator;

  /// Resolved lazily, not injected. `SyncManager` documents the bug this
  /// avoids: a constructor-injected sink captured the pre-Firebase no-op
  /// permanently, and every trip silently went to `users/local/...`
  /// instead of the real account.
  CompetitionMirrorSink get _sink => getIt<CompetitionMirrorSink>();

  /// Placeholder identities never publish. The social feature has
  /// refused to write per-user rows under these since Phase 2 — a
  /// mirror keyed on `'local'` would be a public document belonging to
  /// nobody, and it would be stranded the moment the real uid arrived.
  static const Set<String> _placeholderUids = {kLocalPlaceholderUid, 'pending'};

  Future<void> publishNow() async {
    try {
      final row = await _settings.read();
      final uid = row.uid;
      if (uid.isEmpty || _placeholderUids.contains(uid)) {
        if (kDebugMode) {
          debugPrint('[CompetitionMirror] skip — placeholder uid "$uid"');
        }
        return;
      }

      final now = DateTime.now();
      final totals = <(CompetitionMetric, LeaderboardPeriod), double>{};
      for (final period in LeaderboardPeriod.values) {
        final window = CompetitionWindow.forPeriod(period, now);
        // One repository read per window, shared across the three
        // metrics that use it.
        final trips = await _social.getCompetitionTrips(
          uid: uid,
          window: window,
        );
        for (final metric in CompetitionMetric.values) {
          totals[(metric, period)] = _calculator.calculate(
            metric: metric,
            trips: trips,
            window: window,
          );
        }
      }

      await _sink.write(
        CompetitionMirror(
          uid: uid,
          username: row.username,
          carMake: row.carMake,
          carModel: row.carModel,
          countryCode: row.country ?? '',
          inviteCode: inviteCodeFor(uid),
          totals: totals,
        ),
      );
    } catch (e, st) {
      // Swallowed like a trip upload: the values live locally and are
      // recomputed from scratch next time, so a failed publish costs
      // freshness rather than data.
      if (kDebugMode) {
        debugPrint('[CompetitionMirror] publish failed: $e\n$st');
      }
    }
  }
}
