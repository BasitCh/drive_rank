import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Thin wrapper around Play Core's in-app update API.
///
/// Behaviour by platform:
/// - **Android**: checks for a newer version on the Play Store, and if
///   one is available kicks off a *flexible* update (downloads in the
///   background, then surfaces a snackbar offering to install). Falls
///   back silently on devices without Play Services.
/// - **iOS / other**: no-op. Apple's store handles updates natively
///   and there's no equivalent programmatic API.
///
/// Every call is best-effort — any failure is swallowed in release
/// mode (and logged in debug). The app never crashes because we
/// couldn't reach Play Services.
class AppUpdateService {
  const AppUpdateService();

  /// Run the full check → download → install flow. Safe to call from
  /// any widget's initState (after the first frame) — the Play UI is
  /// presented modally by the platform and doesn't depend on our
  /// widget tree.
  Future<void> promptIfAvailable() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      // Prefer flexible (background download + install prompt) so the
      // user isn't blocked. If Play says the update only allows
      // immediate, fall through to that — but only when the version
      // gap is large enough that Play marked it required.
      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] update check failed: $e\n$st');
      }
    }
  }
}
