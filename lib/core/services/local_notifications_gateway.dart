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

  final List<void Function(NotificationResponse)> _listeners = [];

  /// Registers a tap/action-button handler. Every registered listener
  /// runs on every response — each listener is responsible for
  /// ignoring responses it doesn't own (by checking `payload` or
  /// `actionId`), the same way `LiveTripNotificationService` already
  /// ignores action ids it doesn't recognise.
  void addResponseListener(void Function(NotificationResponse) listener) {
    _listeners.add(listener);
  }

  /// Idempotent AND concurrency-safe — bootstrap's deferred retention
  /// init and a user tapping Start right after cold launch can both
  /// call this within the same event loop turn. A plain `if
  /// (_initialised) return` check-then-await-then-set left a window
  /// where both callers would pass the guard before either finished,
  /// firing `plugin.initialize()` twice concurrently (the plugin
  /// channel doesn't tolerate that). Memoizing the in-flight Future
  /// makes every concurrent caller await the same single call.
  Future<void>? _initFuture;

  Future<void> ensureInitialised() {
    return _initFuture ??= _initialise();
  }

  Future<void> _initialise() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings(_statusBarIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _dispatch,
      );
    } catch (e) {
      // Let the next caller retry instead of permanently caching a
      // failed init.
      _initFuture = null;
      rethrow;
    }
  }

  void _dispatch(NotificationResponse response) {
    for (final listener in _listeners) {
      listener(response);
    }
  }
}
