import 'dart:async';
import 'dart:io';

import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Posts (and updates in place) the lock-screen "live trip" notification.
///
/// Anatomy of the notification:
///   - Title: big speed in the user's unit ("72 km/h").
///   - Body: distance + duration ("5.2 km · 1h 22m").
///   - Action button: "End Trip". Tapping once swaps the button copy
///     to "Tap End to confirm (3 s)"; tapping again within that window
///     emits an [endTripRequested] event on the broadcast stream so
///     `TrackingBloc` can fire `TrackingStopRequested`. Missing the
///     three-second window reverts to the normal button.
///
/// The notification is silent / ongoing / public visibility — it sits on
/// the lock screen for the duration of a trip without ever alerting.
///
/// Android 13+ requires a runtime POST_NOTIFICATIONS grant; we request
/// it lazily on first [show]. iOS gets a single notification at trip
/// start (no live update — there's no equivalent lock-screen widget on
/// Apple's platform yet).
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

  /// Status-bar icon. Lives at
  /// `android/app/src/main/res/drawable/ic_stat_drive.xml` — a white-on-
  /// transparent vector so Android can tint it to the system theme.
  /// Never reference `ic_launcher` here: that's a mipmap, and the
  /// notification framework needs a drawable.
  static const _statusBarIcon = 'ic_stat_drive';

  static const _endRequestActionId = 'end_trip_request';
  static const _endConfirmActionId = 'end_trip_confirm';
  static const _confirmWindow = Duration(seconds: 3);

  /// Broadcast stream the bloc subscribes to. Emits each time the user
  /// completes the tap-twice End Trip flow on the notification.
  Stream<void> get endTripRequested => _endRequestController.stream;
  final StreamController<void> _endRequestController =
      StreamController<void>.broadcast();

  // The most recent stats we rendered — used to re-render with the
  // confirmation-state copy without forcing the bloc to push another
  // saveSummary.
  LiveTripStats? _lastStats;
  bool _lastPaused = false;
  Timer? _confirmResetTimer;
  bool _awaitingConfirmTap = false;
  bool _initialised = false;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings(_statusBarIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );

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

  Future<void> _onResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId != _endRequestActionId &&
        actionId != _endConfirmActionId) {
      return;
    }
    if (_awaitingConfirmTap) {
      // Second tap landed inside the 3-second window — actually end.
      _awaitingConfirmTap = false;
      _confirmResetTimer?.cancel();
      _confirmResetTimer = null;
      if (!_endRequestController.isClosed) {
        _endRequestController.add(null);
      }
      return;
    }
    // First tap — swap the action label and start a revert timer.
    _awaitingConfirmTap = true;
    if (_lastStats != null) {
      await _render(_lastStats!, paused: _lastPaused, confirming: true);
    }
    _confirmResetTimer?.cancel();
    _confirmResetTimer = Timer(_confirmWindow, () async {
      _awaitingConfirmTap = false;
      if (_lastStats != null) {
        await _render(_lastStats!, paused: _lastPaused, confirming: false);
      }
    });
  }

  /// Update (or show, first time) the live notification. Cheap to call
  /// at the 1Hz hot path — Android collapses duplicate updates that
  /// arrive within ~250 ms of each other.
  Future<void> show(LiveTripStats stats, {bool paused = false}) async {
    await _ensureInitialised();
    _lastStats = stats;
    _lastPaused = paused;
    if (_awaitingConfirmTap) {
      // We're mid tap-twice — don't clobber the confirmation copy on
      // every 1Hz tick. The user gets back to live stats when the
      // 3-second timer resets.
      return;
    }
    await _render(stats, paused: paused, confirming: false);
  }

  Future<void> _render(
    LiveTripStats stats, {
    required bool paused,
    required bool confirming,
  }) async {
    final title = paused
        ? 'Trip paused'
        : '${_locale.formatSpeedValue(stats.currentSpeedKmh)} '
            '${_locale.speedUnitLabel}';
    final body = '${_locale.formatDistance(stats.distanceKm)} · '
        '${_locale.formatDuration(stats.durationSeconds)}';
    final action = AndroidNotificationAction(
      confirming ? _endConfirmActionId : _endRequestActionId,
      confirming ? 'Tap End to confirm (3s)' : 'End Trip',
      showsUserInterface: false,
      cancelNotification: false,
    );
    try {
      await _plugin.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: _statusBarIcon,
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
            actions: <AndroidNotificationAction>[action],
          ),
          iOS: const DarwinNotificationDetails(
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
    _confirmResetTimer?.cancel();
    _confirmResetTimer = null;
    _awaitingConfirmTap = false;
    _lastStats = null;
    try {
      await _plugin.cancel(_notificationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LiveTripNotification] dismiss failed: $e');
      }
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    _confirmResetTimer?.cancel();
    await _endRequestController.close();
  }
}
