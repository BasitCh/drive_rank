import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Outcome of a Play Store update check, returned to the splash so it
/// can route the user appropriately.
enum AppUpdateOutcome {
  /// No update available, Play Services unreachable, or non-Android
  /// platform — let the splash continue to onboarding/home normally.
  notRequired,

  /// Update flow completed successfully. Play Store relaunches the app
  /// automatically, so the splash never actually sees this — included
  /// for completeness.
  updated,

  /// Update available, but the user declined the immediate-update
  /// system prompt OR the in-app update flow itself errored. The
  /// splash must show a blocking gate (no path to the rest of the app
  /// without updating).
  blocked,
}

/// Thin wrapper around Play Core's in-app update API.
///
/// For DriveRank's v1 we treat **every** available update as required.
/// When `info.updateAvailability == updateAvailable` we kick off
/// [InAppUpdate.performImmediateUpdate] — Play Store shows a full-screen
/// blocker the user can't dismiss without losing access to the app.
/// The flexible (background-download) path is gone on purpose: in this
/// product, a stale client risks losing trips, so we prefer the
/// short-term annoyance of a forced update over an outdated install.
///
/// iOS / non-Android falls through silently — there's no equivalent
/// programmatic API on Apple's platform. We'll surface a "please update
/// in the App Store" dialog from a Remote Config check when the iOS
/// build lands.
class AppUpdateService {
  const AppUpdateService();

  /// Run the check → immediate-update flow.
  ///
  /// Returns:
  /// - [AppUpdateOutcome.notRequired] when there's nothing to install
  ///   or the platform doesn't support in-app updates.
  /// - [AppUpdateOutcome.blocked] when an update is available but the
  ///   user declined or Play Services errored — the caller must hold
  ///   the user on a "Update required" gate.
  /// - [AppUpdateOutcome.updated] for completeness; in practice the
  ///   app process gets restarted by Play before this returns.
  Future<AppUpdateOutcome> promptIfAvailable() async {
    if (!Platform.isAndroid) return AppUpdateOutcome.notRequired;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return AppUpdateOutcome.notRequired;
      }
      if (!info.immediateUpdateAllowed) {
        // Older Play Services builds can refuse the immediate flow even
        // when an update exists. Treat that as blocked so the gate can
        // surface a Play Store deep link.
        return AppUpdateOutcome.blocked;
      }
      final result = await InAppUpdate.performImmediateUpdate();
      switch (result) {
        case AppUpdateResult.success:
          return AppUpdateOutcome.updated;
        case AppUpdateResult.userDeniedUpdate:
        case AppUpdateResult.inAppUpdateFailed:
          return AppUpdateOutcome.blocked;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] update check failed: $e\n$st');
      }
      // Network blip or Play Services hiccup — let the user through
      // rather than trap them on a gate when we don't actually know
      // if an update was required. The next launch retries the check.
      return AppUpdateOutcome.notRequired;
    }
  }

  /// Re-run the immediate update flow from the gate page after the user
  /// taps "Try again". Same semantics as [promptIfAvailable] but
  /// skips the initial "is an update available" check (the gate is
  /// only ever shown when we already know it is).
  Future<AppUpdateOutcome> retryImmediate() => promptIfAvailable();
}
