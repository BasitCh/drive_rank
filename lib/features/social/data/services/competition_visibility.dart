import 'dart:async';

import 'package:drive_rank/features/social/data/services/competition_value_publisher.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Whether this user appears in the competition, and the two answers
/// that change it.
///
/// Appearing means other DriveRank users can see their username, car,
/// country and competition totals, and can find them by name or code.
/// Nothing public is written until the user has joined: an upgrade used
/// to publish every existing user the moment it launched, without
/// telling them.
@lazySingleton
class CompetitionVisibility {
  CompetitionVisibility(this._settings, this._publisher);

  final UserSettingsRepository _settings;
  final CompetitionValuePublisher _publisher;

  /// Records the yes, then claims the username and publishes. Both are
  /// best-effort and retried on every launch, so a failure here costs
  /// freshness, never the answer.
  Future<void> join() async {
    await _settings.setCompetitionOptIn(optIn: true);
    await _settings.claimUsername();
    await _publisher.publishNow();
  }

  /// Records the no and removes any public profile already published.
  ///
  /// The removal is not awaited: offline, a Firestore delete waits for
  /// the network, and the answer must not. [enforceOnLaunch] repeats it,
  /// so an interrupted removal cannot leave someone public who said no.
  Future<void> leave() async {
    await _settings.setCompetitionOptIn(optIn: false);
    unawaited(_withdraw());
  }

  /// Run at app start: a user who said no has no public profile,
  /// whatever happened to the last attempt to remove it.
  Future<void> enforceOnLaunch() async {
    if ((await _settings.read()).competitionOptIn == false) await _withdraw();
  }

  Future<void> _withdraw() async {
    try {
      await _publisher.withdraw();
    } catch (e) {
      if (kDebugMode) debugPrint('[CompetitionVisibility] withdraw failed: $e');
    }
  }
}
