import 'dart:io';

import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Posts (and updates in place) the lock-screen "live trip" notification.
///
/// The notification stays pinned for the duration of a trip. Its title
/// is the current speed in big text, body is a one-liner with the
/// running distance and duration. We never play a sound — this is
/// ambient, glanceable info, not an alert.
///
/// Android 13+ requires a runtime POST_NOTIFICATIONS grant. We ask for
/// it lazily on first [show] so a user who never starts a trip never
/// gets prompted. iOS just shows a single transient notification at
/// trip start (a lock-screen widget is on the iOS roadmap, not the
/// scope of this build).
@lazySingleton
class LiveTripNotificationService {
  LiveTripNotificationService(this._locale)
      : _plugin = FlutterLocalNotificationsPlugin();

  final LocaleService _locale;
  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'live_trip';
  static const _channelName = 'Live trip';
  static const _channelDescription =
      'Pinned notification with your current speed, distance and time '
      'while a trip is recording.';
  static const _notificationId = 1001;

  bool _initialised = false;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      // Channel needs to exist before the first show() call — without
      // it, Android <O drops the notification silently.
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
      await androidImpl?.requestNotificationsPermission();
    }
    _initialised = true;
  }

  /// Update (or show, first time) the live notification. Cheap to call
  /// at the 1Hz hot path — Android collapses duplicate updates that
  /// arrive within ~250 ms of each other.
  Future<void> show(LiveTripStats stats, {bool paused = false}) async {
    await _ensureInitialised();
    final title = paused
        ? 'Trip paused'
        : '${_locale.formatSpeedValue(stats.currentSpeedKmh)} '
            '${_locale.speedUnitLabel}';
    final body = '${_locale.formatDistance(stats.distanceKm)} · '
        '${_locale.formatDuration(stats.durationSeconds)}';
    try {
      await _plugin.show(
        _notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.navigation,
            showWhen: false,
            onlyAlertOnce: true,
            silent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: false,
            presentBanner: false,
            presentList: false,
            interruptionLevel: InterruptionLevel.passive,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LiveTripNotification] show failed: $e');
      }
    }
  }

  /// Pull the notification down — called when the trip ends or is
  /// reset.
  Future<void> dismiss() async {
    try {
      await _plugin.cancel(_notificationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LiveTripNotification] dismiss failed: $e');
      }
    }
  }
}
