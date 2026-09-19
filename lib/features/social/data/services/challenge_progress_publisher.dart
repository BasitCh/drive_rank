import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Publishes **this account's own** figure for every live challenge.
///
/// The sibling of `CompetitionValuePublisher`, and the same trust model:
/// each device computes its own numbers from its own trips and writes
/// them where the other participant can read them. Nobody writes
/// anybody else's — the security rules see to that, which is what makes
/// a *derived* winner trustworthy without a server deciding one.
///
/// **Recomputed, never accumulated.** The figure is rebuilt from the
/// trips inside the challenge's stored window on every pass, so
/// deleting a trip lowers what the opponent sees rather than leaving an
/// inflated total standing. That is this feature's load-bearing rule and
/// the challenge board is the first place another person depends on it.
@lazySingleton
class ChallengeProgressPublisher {
  ChallengeProgressPublisher(this._social, this._settings, this._calculator);

  final SocialRepository _social;
  final UserSettingsRepository _settings;
  final CompetitionMetricCalculator _calculator;

  /// Resolved lazily for the reason `SyncManager` documents: a
  /// constructor-injected Firestore dependency captures the pre-Firebase
  /// no-op permanently and every write silently goes nowhere.
  SocialDirectory get _directory => getIt<SocialDirectory>();

  static bool _isPlaceholder(String uid) =>
      uid.isEmpty || uid == 'local' || uid == 'pending';

  Future<void> publishNow({DateTime? now}) async {
    try {
      final uid = (await _settings.read()).uid;
      if (_isPlaceholder(uid)) return;

      final at = now ?? DateTime.now();
      final challenges = await _social.getHeadToHeadChallenges(uid);

      for (final challenge in challenges) {
        if (!_shouldPublish(challenge, at)) continue;

        // The window stored at creation, never one re-derived from the
        // period — those disagree for any challenge that didn't start
        // on a period boundary, and a challenge never does: it starts
        // when it was opened.
        final window = CompetitionWindow(
          start: challenge.startAt,
          end: challenge.endAt,
        );
        final trips = await _social.getCompetitionTrips(
          uid: uid,
          window: window,
        );
        final value = _calculator.calculate(
          metric: challenge.metric,
          trips: trips,
          window: window,
        );

        await _directory.publishProgress(
          challengeId: challenge.id,
          uid: uid,
          value: value,
        );
      }
    } catch (e, st) {
      // Same contract as a trip upload: the values are local and
      // authoritative, so a failed publish costs the opponent
      // freshness, never this device correctness. The next pass
      // recomputes from scratch.
      if (kDebugMode) debugPrint('[ChallengeProgress] failed: $e\n$st');
    }
  }

  /// Whether there is any point writing this challenge's figure.
  ///
  /// Only an accepted one that is still inside its finalization
  /// boundary. Past that the rules refuse the write anyway — that
  /// refusal is what stops a loser rewriting a settled result — so
  /// attempting it would only report a permission error for a rule
  /// working exactly as intended. That mistake reached a real device's
  /// Crashlytics once already, from the friendship healing pass.
  static bool _shouldPublish(Challenge challenge, DateTime at) {
    if (challenge.isPersonal) return false;
    if (challenge.status != ChallengeStatus.active) return false;
    return at.isBefore(challenge.endAt.add(kChallengeFinalizationGrace));
  }
}
