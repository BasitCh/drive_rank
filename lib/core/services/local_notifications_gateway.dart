import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// The single owner of the app's `FlutterLocalNotificationsPlugin`
/// instance and its one `.initialize()` call.
///
/// flutter_local_notifications' plugin channel is effectively a native
/// singleton — if two independent Dart-side services each construct
/// their own `FlutterLocalNotificationsPlugin()` and call `.initialize()`
/// with their own `onDidReceiveNotificationResponse` callback, the
/// second call silently replaces the first's callback (last one wins,
/// there's no error). Before this gateway existed,
/// `LiveTripNotificationService` was the only caller; adding the
/// retention-notification feature as a second independent initialiser
/// would have made the live-trip "End Trip" notification action stop
/// working whenever the retention service happened to initialise
/// after it (undeterministic — depends on which trip/schedule fires
/// first). Every feature that shows or schedules a local notification
/// must go through this gateway instead of constructing its own
/// `FlutterLocalNotificationsPlugin()`.
@lazySingleton
class LocalNotificationsGateway {
  LocalNotificationsGateway() : plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin plugin;

  /// Status-bar icon — a white-on-transparent vector at
  /// `android/app/src/main/res/drawable/ic_stat_drive.xml`. One icon,
  /// shared by every notification this app shows (live-trip and
  /// retention alike) — never reference `ic_launcher`, that's a mipmap
  /// and the notification framework needs a drawable.
  static const _statusBarIcon = 'ic_stat_drive';

  bool _initialised = false;
  final List<void Function(NotificationResponse)> _listeners = [];

  /// Registers a tap/action-button handler. Every registered listener
  /// runs on every response — each listener is responsible for
  /// ignoring responses it doesn't own (by checking `payload` or
  /// `actionId`), the same way `LiveTripNotificationService` already
  /// ignores action ids it doesn't recognise.
  void addResponseListener(void Function(NotificationResponse) listener) {
    _listeners.add(listener);
  }

  /// Idempotent — safe to call from every feature that needs the
  /// plugin ready; only the first call actually initialises it.
  Future<void> ensureInitialised() async {
    if (_initialised) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings(_statusBarIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _dispatch,
    );
    _initialised = true;
  }

  void _dispatch(NotificationResponse response) {
    for (final listener in _listeners) {
      listener(response);
    }
  }
}
