import 'package:drive_rank/core/services/push_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Real [PushService] using OneSignal. Registered only when an
/// `ONESIGNAL_APP_ID` is provided at startup — see `bootstrap.dart`.
///
/// We use OneSignal v5's `User` API (the v5 SDK split the global namespace
/// into `Notifications`, `User`, `Login`, …) rather than the legacy global
/// helpers, which were removed in 5.x.
class OneSignalPushService implements PushService {
  OneSignalPushService(this._appId) {
    OneSignal.initialize(_appId);
  }

  final String _appId;

  @override
  Future<bool> requestPermission() async {
    return OneSignal.Notifications.requestPermission(true);
  }

  @override
  Future<void> setExternalId(String uid) async {
    await OneSignal.login(uid);
  }

  @override
  Future<void> tag(String key, String value) async {
    await OneSignal.User.addTagWithKey(key, value);
  }

  @override
  Future<void> untag(String key) async {
    await OneSignal.User.removeTag(key);
  }
}
