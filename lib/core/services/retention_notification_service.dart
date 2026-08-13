import 'dart:async';
import 'dart:io' show Platform;

import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/core/services/local_notifications_gateway.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/retention_notification_copy.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Behaviour-triggered re-engagement notifications — the "come back and
/// drive again" loop, built entirely on local (on-device) scheduling.
///
/// There is no server-side infrastructure in this project (no Cloud
/// Functions, no `.firebaserc`) — every campaign here runs through
/// `flutter_local_notifications`' `zonedSchedule`, which is real OS-level
/// alarm scheduling (survives app kill/reboot on Android via
/// AlarmManager, `UNCalendarNotificationTrigger` on iOS), not an
/// in-memory `Timer`. `AndroidScheduleMode.inexactAllowWhileIdle` is
/// used throughout deliberately: these reminders don't need
/// to-the-second precision, and exact scheduling on Android 12+ requires
/// the user to separately grant `SCHEDULE_EXACT_ALARM` — not worth the
/// extra permission friction for "come back sometime around now."
///
/// Every send is gated on [PermissionService.currentNotificationStatus]
/// so a user who has notifications off (or never granted them) never
/// has anything scheduled for them, and on "has this user completed a
/// trip before" so someone who never used the core tracking feature
/// never gets the inactivity nudge.
///
/// One real limitation worth stating plainly: the weekly recap's
/// content is baked in at *schedule* time, not fetched fresh when the
/// notification actually fires (there's no way to run Dart code at
/// delivery time while the app is fully closed, on-device only). It's
/// kept fresh by recomputing and rescheduling on every trip completion
/// and every app open — so it reflects "trips as of the last time you
/// touched the app," which is accurate in the common case but can lag
/// if the user drives again in the few days before the recap fires.
@lazySingleton
class RetentionNotificationService {
  RetentionNotificationService(
    this._gateway,
    this._locale,
    this._permissions,
    this._telemetry,
    this._trips,
  );

  final LocalNotificationsGateway _gateway;
  final LocaleService _locale;
  final PermissionService _permissions;
  final TelemetryService _telemetry;
  final TripRepository _trips;

  static const _channelId = 'retention';
  static const _channelName = 'Reminders';
  static const _channelDescription =
      'Occasional reminders to drive again, weekly recaps, and '
      'personal-record celebrations.';

  // Fixed, deterministic ids — one per campaign. Every scheduled
  // campaign is cancelled before being rescheduled with the same id,
  // so there is structurally never more than one pending notification
  // per campaign — that's the whole de-duplication/anti-spam
  // mechanism, no "last sent at" bookkeeping needed.
  static const _idFirstTripFollowUp = 3001;
  static const _idInactivityNudge = 3002;
  static const _idWeeklyRecap = 3003;
  static const _idPersonalRecord = 3004;

  static const _payloadPrefix = 'retention:';
  static const _campaignFirstTripFollowUp = 'first_trip_followup';
  static const _campaignInactivityNudge = 'inactive_nudge';
  static const _campaignWeeklyRecap = 'weekly_recap';
  static const _campaignPersonalRecord = 'personal_record';

  bool _listenerRegistered = false;
  bool _timezoneConfigured = false;

  // ---- lifecycle -------------------------------------------------------

  /// Call once at bootstrap, after DI/DB are ready. Tracks a cold-start
  /// launched by tapping a notification, and — for a user who already
  /// has trip history (this feature shipping to an existing install) —
  /// backfills the inactivity-nudge anchor and refreshes the weekly
  /// recap. Deliberately does NOT backfill the first-trip follow-up: a
  /// long-past anchor there would either fire as a jarring "surprise"
  /// notification or get silently skipped by the past-time guard in
  /// [_zonedScheduleOnce] — either way it's a one-time onboarding nudge,
  /// not something to resurrect for a long-time user.
  Future<void> onAppStarted({required String uid}) async {
    await _ensureReady();
    await _trackColdStartTap();
    if (!await _permissions.currentNotificationStatus()) return;
    final count = await _trips.countAll(uid: uid);
    if (count == 0) return;
    final latest = await _trips.getLatestTrip(uid: uid);
    if (latest != null) {
      await _rescheduleInactivityNudge(anchor: latest.startedAt);
    }
    await _scheduleWeeklyRecap(uid: uid);
  }

  /// Call right after `TripRepository.saveTrip` succeeds. Handles the
  /// two scheduled/recurring campaigns' bookkeeping. The personal-record
  /// celebration is a separate call ([celebratePersonalRecord]) — it's
  /// conditional on the caller's own record-detection (comparing this
  /// trip against the prior best), which this service has no way to
  /// determine on its own without duplicating that comparison.
  Future<void> onTripCompleted({
    required String uid,
    required int tripCountIncludingThis,
    required DateTime tripEndedAt,
  }) async {
    await _ensureReady();
    if (!await _permissions.currentNotificationStatus()) return;
    if (tripCountIncludingThis <= 1) {
      await _scheduleFirstTripFollowUp(anchor: tripEndedAt);
    } else {
      // A 2nd+ trip landed on its own — the follow-up nudge already
      // did its job (or was never needed). Don't let a stale one fire.
      await _gateway.plugin.cancel(_idFirstTripFollowUp);
    }
    await _rescheduleInactivityNudge(anchor: tripEndedAt);
    await _scheduleWeeklyRecap(uid: uid);
  }

  /// Immediate (not scheduled) celebration for a just-beaten personal
  /// best. [kind] selects the copy; [valueKmh] is the new record value
  /// in canonical metric units (km/h for speed, km for distance) —
  /// formatted here via [LocaleService] so the caller never has to
  /// think about mph/km display.
  Future<void> celebratePersonalRecord({
    required RecordCelebrationKind kind,
    required double valueKmh,
  }) async {
    await _ensureReady();
    if (!await _permissions.currentNotificationStatus()) return;
    final valueText = kind == RecordCelebrationKind.speed
        ? _locale.formatSpeed(valueKmh)
        : _locale.formatDistance(valueKmh);
    final body = RetentionNotificationCopy.personalRecordBody(
      kind: kind,
      valueLabel: valueText,
    );
    try {
      await _gateway.plugin.show(
        _idPersonalRecord,
        '🔥 New personal record!',
        body,
        _details(),
        payload: '$_payloadPrefix$_campaignPersonalRecord',
      );
      unawaited(
        _telemetry.track(
          TelemetryEvents.notificationSent,
          properties: <String, Object?>{'campaign': _campaignPersonalRecord},
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RetentionNotification] celebrate failed: $e');
      }
    }
  }

  // ---- scheduling helpers ------------------------------------------

  Future<void> _scheduleFirstTripFollowUp({required DateTime anchor}) {
    return _zonedScheduleOnce(
      id: _idFirstTripFollowUp,
      when: anchor.add(const Duration(hours: 60)), // ~2.5 days
      title: '🏁 Ready for your next drive?',
      body: 'Your next trip could set a new personal record.',
      campaign: _campaignFirstTripFollowUp,
    );
  }

  Future<void> _rescheduleInactivityNudge({required DateTime anchor}) {
    return _zonedScheduleOnce(
      id: _idInactivityNudge,
      when: anchor.add(const Duration(days: 7)),
      title: 'Your DriveRank is getting quiet 👀',
      body: 'Time to record another drive.',
      campaign: _campaignInactivityNudge,
    );
  }

  Future<void> _scheduleWeeklyRecap({required String uid}) async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final trips = await _trips.getTripsSince(uid: uid, since: since);
    // Nothing to recap — don't schedule a "0 trips this week" nag; the
    // inactivity nudge already covers the silence-for-a-week case.
    if (trips.isEmpty) return;

    final distanceKm = trips.fold<double>(0, (sum, t) => sum + t.distanceKm);
    final recordCount = await _recordsInWindow(uid: uid, windowTrips: trips);
    final body = RetentionNotificationCopy.weeklyRecapBody(
      tripCount: trips.length,
      distanceLabel: _locale.formatDistance(distanceKm, fractionDigits: 0),
      recordCount: recordCount,
    );

    await _zonedScheduleOnce(
      id: _idWeeklyRecap,
      when: _nextSunday6pm(),
      title: '📊 Your week in DriveRank',
      body: body,
      campaign: _campaignWeeklyRecap,
      exact: false,
    );
  }

  /// Counts how many of [windowTrips] currently hold an all-time record
  /// (top speed or longest distance). A simplification, not a full
  /// historical ledger — it answers "is the trip that holds the record
  /// *right now* inside this window," not "how many distinct PRs were
  /// set and later superseded within the same week" (an edge case rare
  /// enough not to justify a dedicated records-history table).
  Future<int> _recordsInWindow({
    required String uid,
    required List<TripRow> windowTrips,
  }) async {
    final bestSpeedId = (await _trips.getPersonalBest(uid: uid))?.id;
    final bestDistanceId = (await _trips.getLongestTrip(uid: uid))?.id;
    var count = 0;
    if (bestSpeedId != null && windowTrips.any((t) => t.id == bestSpeedId)) {
      count++;
    }
    if (bestDistanceId != null &&
        bestDistanceId != bestSpeedId &&
        windowTrips.any((t) => t.id == bestDistanceId)) {
      count++;
    }
    return count;
  }

  tz.TZDateTime _nextSunday6pm() {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    while (target.weekday != DateTime.sunday || !target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  Future<void> _zonedScheduleOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String campaign,
    bool exact = false,
  }) async {
    try {
      // Cancel-then-reschedule with the same fixed id is the
      // de-duplication mechanism (see the class doc comment) — this
      // also means calling this repeatedly (every trip, every app
      // open) is always safe, never stacks a second pending alarm.
      await _gateway.plugin.cancel(id);
      if (when.isBefore(DateTime.now())) return;
      await _gateway.plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$_payloadPrefix$campaign',
      );
      unawaited(
        _telemetry.track(
          TelemetryEvents.notificationSent,
          properties: <String, Object?>{'campaign': campaign},
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RetentionNotification] schedule "$campaign" failed: $e');
      }
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: 'ic_stat_drive',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // ---- init / tap tracking ------------------------------------------

  Future<void> _ensureReady() async {
    await _gateway.ensureInitialised();
    if (!_listenerRegistered) {
      _gateway.addResponseListener(_onResponse);
      _listenerRegistered = true;
    }
    if (Platform.isAndroid) {
      final androidImpl = _gateway.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.defaultImportance,
        ),
      );
    }
    await _configureTimezone();
  }

  Future<void> _configureTimezone() async {
    if (_timezoneConfigured) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      // Falls back to whatever `tz.local` already defaults to (UTC) —
      // the weekly recap fires at 6pm UTC instead of 6pm local for
      // this one session rather than the feature breaking outright.
      if (kDebugMode) {
        debugPrint('[RetentionNotification] timezone lookup failed: $e');
      }
    }
    _timezoneConfigured = true;
  }

  void _onResponse(NotificationResponse response) =>
      _handlePayload(response.payload);

  Future<void> _trackColdStartTap() async {
    final details = await _gateway.plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    _handlePayload(details?.notificationResponse?.payload);
  }

  void _handlePayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return;
    final campaign = payload.substring(_payloadPrefix.length);
    unawaited(
      _telemetry.track(
        TelemetryEvents.notificationOpened,
        properties: <String, Object?>{'campaign': campaign},
      ),
    );
    if (campaign == _campaignWeeklyRecap) {
      unawaited(_telemetry.track(TelemetryEvents.weeklyRecapViewed));
    }
  }
}
