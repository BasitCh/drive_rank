import 'dart:async';

import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_progress.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Brings head-to-head challenges, and both sides' figures, into Drift.
///
/// Same contract as `FriendsSyncService`, for the same reason: reads are
/// served from Drift and the cloud is a sync target, so every screen
/// watches the local tables and renders offline. A challenge is the
/// second thing in this app created by *somebody else's* device.
///
/// **Reconciles; never appends.** Each pass makes the local tables match
/// what the cloud returned, and running it three times leaves what
/// running it once did.
///
/// **Every pass is serialised.** Two listeners drive this — the
/// challenge list and one per live challenge's figures — and in 4c a
/// pair of listeners over one table raced each other into a unique-index
/// violation. One queue, as `LocalSocialTripProcessor` has.
@lazySingleton
class ChallengeSyncService {
  ChallengeSyncService(this._social, this._settings);

  final SocialRepository _social;
  final UserSettingsRepository _settings;

  /// Resolved lazily for the reason `SyncManager` documents: a
  /// constructor-injected Firestore dependency captures the pre-Firebase
  /// no-op permanently and every write silently goes nowhere.
  SocialDirectory get _directory => getIt<SocialDirectory>();

  StreamSubscription<void>? _challengesSub;

  /// One figures listener per live challenge, keyed by challenge id.
  ///
  /// Only challenges that can still change get one: an accepted
  /// challenge whose figures are frozen will never emit again, and a
  /// pending or declined one has no figures to watch.
  final Map<String, StreamSubscription<void>> _progressSubs = {};

  Future<void> _queue = Future<void>.value();

  Future<void> _serialised(Future<void> Function() work) {
    final result = _queue.then((_) => work());
    _queue = result.catchError((Object e) {
      if (kDebugMode) debugPrint('[ChallengeSync] pass failed: $e');
    });
    return result;
  }

  static bool _isPlaceholder(String uid) =>
      uid.isEmpty || uid == 'local' || uid == 'pending';

  Future<void> start() async {
    final uid = (await _settings.read()).uid;
    if (_isPlaceholder(uid)) return;

    await stop();
    _challengesSub = _directory.watchChallenges(uid).listen(
      (challenges) => _serialised(() => _absorb(uid: uid, remote: challenges)),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[ChallengeSync] challenges stream: $e');
      },
    );
  }

  Future<void> stop() async {
    await _challengesSub?.cancel();
    _challengesSub = null;
    for (final sub in _progressSubs.values) {
      await sub.cancel();
    }
    _progressSubs.clear();
  }

  Future<void> syncNow() async {
    try {
      final uid = (await _settings.read()).uid;
      if (_isPlaceholder(uid)) return;
      final remote = await _directory.challengesFor(uid);
      await _serialised(() => _absorb(uid: uid, remote: remote));
    } catch (e, st) {
      // Same contract as a trip upload: a failed pass costs freshness,
      // and the next one recomputes from scratch.
      if (kDebugMode) debugPrint('[ChallengeSync] failed: $e\n$st');
    }
  }

  /// Writes the cloud's challenges into Drift and re-points the figures
  /// listeners at whichever of them are still live.
  Future<void> _absorb({
    required String uid,
    required List<Challenge> remote,
  }) async {
    for (final challenge in remote) {
      // A personal target cannot arrive from the cloud — nothing
      // publishes one — so anything without an opponent here is
      // malformed and is left alone rather than overwriting a local
      // target that happens to share an id.
      if (challenge.isPersonal) continue;
      await _social.upsertChallenge(challenge);
    }

    final now = DateTime.now();
    final live = {
      for (final challenge in remote)
        if (_isLive(challenge, now)) challenge.id: challenge,
    };

    // Drop listeners for anything that stopped being live — settled,
    // declined, or gone.
    for (final id in _progressSubs.keys.toList()) {
      if (live.containsKey(id)) continue;
      await _progressSubs.remove(id)?.cancel();
    }

    for (final challenge in live.values) {
      if (_progressSubs.containsKey(challenge.id)) continue;
      _progressSubs[challenge.id] = _directory
          .watchProgress(challenge.id)
          .listen(
            (figures) => _serialised(
              () => _absorbProgress(
                uid: uid,
                challenge: challenge,
                figures: figures,
              ),
            ),
            onError: (Object e) {
              if (kDebugMode) {
                debugPrint('[ChallengeSync] progress ${challenge.id}: $e');
              }
            },
          );
    }
  }

  /// Whether a challenge's figures can still change.
  ///
  /// Accepted — `active`, in `ChallengeStatus`' vocabulary — and not
  /// yet past the finalization boundary — the
  /// competition's end plus the grace, which is the same moment the
  /// rules stop accepting writes and `SettleChallenge` starts naming a
  /// winner.
  static bool _isLive(Challenge challenge, DateTime now) {
    if (challenge.status != ChallengeStatus.active) return false;
    return now.isBefore(challenge.endAt.add(kChallengeFinalizationGrace));
  }

  /// Stores the **opponent's** figure, and only theirs.
  ///
  /// The viewer's own row is deliberately skipped even though the cloud
  /// holds a copy of it. Their figure is recomputed from their own
  /// trips, and absorbing what they last published would let a stale
  /// snapshot of themselves overwrite a fresher local recompute — the
  /// same rule the friends board follows, where the viewer's own value
  /// never comes from their own mirror. Publishing is one-way: local
  /// out, never back in.
  ///
  /// A uid absent from [figures] published nothing, and no row is
  /// written for them: **absent must not become a stored zero**, or
  /// `SettleChallenge` would see a figure where there is none and call
  /// a win against somebody who never reported anything.
  Future<void> _absorbProgress({
    required String uid,
    required Challenge challenge,
    required Map<String, double> figures,
  }) async {
    for (final entry in figures.entries) {
      if (entry.key == uid) continue;
      await _social.upsertProgressValue(
        ChallengeProgress(
          challengeId: challenge.id,
          uid: entry.key,
          currentValue: entry.value,
          targetValue: challenge.targetValue,
          lastCalculatedAt: DateTime.now(),
        ),
      );
    }
  }
}
