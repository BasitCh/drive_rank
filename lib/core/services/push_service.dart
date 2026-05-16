import 'package:flutter/foundation.dart';

/// Push notification boundary.
///
/// Two registered implementations:
///  - [NoopPushService] (default) — every call is a no-op. App boots and
///    runs without a OneSignal app id configured.
///  - `OneSignalPushService` — wired up at bootstrap when
///    `ONESIGNAL_APP_ID` is present in `.env` (or `--dart-define`).
abstract class PushService {
  /// Asks the OS for the notification permission. On Android 12-, this
  /// returns true unconditionally; on Android 13+ and iOS it surfaces the
  /// platform dialog.
  Future<bool> requestPermission();

  /// Bind the user id so push targeting can address them later (welcome
  /// drip, "you haven't driven in 7 days", monthly report ready, …).
  Future<void> setExternalId(String uid);

  /// Add a tag — used for segmenting (country, vehicle type, isPro).
  Future<void> tag(String key, String value);

  /// Untag — used when the user changes their country or downgrades.
  Future<void> untag(String key);
}

class NoopPushService implements PushService {
  NoopPushService();

  @override
  Future<bool> requestPermission() async {
    if (kDebugMode) debugPrint('[push] requestPermission (no-op)');
    return true;
  }

  @override
  Future<void> setExternalId(String uid) async {}

  @override
  Future<void> tag(String key, String value) async {}

  @override
  Future<void> untag(String key) async {}
}
