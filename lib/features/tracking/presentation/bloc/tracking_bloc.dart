import 'dart:async';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/core/database/tables/live_trips_table.dart';
import 'package:drive_rank/core/services/active_trip_store.dart';
import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/core/services/live_trip_notification_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/retention_notification_copy.dart';
import 'package:drive_rank/core/services/retention_notification_service.dart';
import 'package:drive_rank/core/services/sensor_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/record_goal_evaluator.dart';
import 'package:drive_rank/shared/services/road_segment_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Coordinates the live tracking page.
///
/// **GPS never auto-starts.** The default state is `TrackingPhase.idle`
/// and stays there until the user explicitly emits
/// `TrackingStartRequested`. The home page renders an idle UI with a
/// Start Trip button — there's no "live tracking" surface until a trip
/// is actually recording.
///
/// State machine (see `TrackingPhase`):
///   idle → starting → active → stopping → idle
/// with `permissionDenied` and `error` as terminal branches that loop
/// back to idle once the user resolves them.
///
/// Trip persistence is atomic — every stop runs through one Drift
/// transaction (trip row + waypoints). If any step of the stop sequence
/// fails the bloc emits `error` and the UI lets the user retry.
@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc(
    this._gps,
    this._sensors,
    this._permissions,
    this._trips,
    this._settings,
    this._segments,
    this._activeTrip,
    this._notification,
    this._telemetry,
    this._retention,
  ) : super(TrackingState.initial()) {
    on<TrackingStartRequested>(_onStartRequested);
    on<TrackingStopRequested>(_onStopRequested);
    on<TrackingPauseRequested>(_onPauseRequested);
    on<TrackingResumeRequested>(_onResumeRequested);
    on<TrackingPermissionRequested>(_onPermissionRequested);
    on<TrackingPermissionRechecked>(_onPermissionRechecked);
    on<TrackingPointReceived>(_onPoint);
    on<TrackingGforceReceived>(_onGforce);
    on<TrackingTicked>(_onTick);
    on<TrackingReset>(_onReset);
    on<TrackingRestoreFromCrash>(_onRestoreFromCrash);
    on<TrackingDisclosureResolved>(_onDisclosureResolved);
    // Bridge the lock-screen notification → bloc. When the user
    // completes the tap-twice End Trip confirmation on the live
    // notification, the service emits on this stream and we dispatch
    // the same TrackingStopRequested event the in-app End button uses.
    // Subscription is cancelled in close().
    _notificationEndSub = _notification.endTripRequested.listen((_) {
      if (state.phase == TrackingPhase.active ||
          state.phase == TrackingPhase.paused) {
        add(const TrackingStopRequested());
      }
    });
    // Probe the persistent store right away — if a previous session
    // was interrupted (process killed, phone rebooted, force-stop),
    // bring the stats back so the user can resume instead of starting
    // a fresh trip.
    add(const TrackingRestoreFromCrash());
  }

  final GpsService _gps;
  final SensorService _sensors;
  final PermissionService _permissions;
  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final RoadSegmentService _segments;
  final ActiveTripStore _activeTrip;
  final LiveTripNotificationService _notification;
  final TelemetryService _telemetry;
  final RetentionNotificationService _retention;

  StreamSubscription<TripPoint>? _pointSub;
  StreamSubscription<double>? _gforceSub;
  StreamSubscription<void>? _notificationEndSub;
  Timer? _ticker;
  DateTime? _startedAt;
  // Set when the user resumes from pause so the very first post-resume
  // GPS point doesn't add a teleport distance from the pre-pause
  // `lastPoint` (the user may have walked / parked / driven elsewhere
  // while paused). Consumed on the next `_onPoint`.
  bool _skipNextDistanceDelta = false;

  // "Currently inside an event" flag for the hard-brake detector. The
  // counter only steps on the transition from false→true, so a single
  // 5-sample-long hard brake increments hardBrakesCount once. Reset on
  // Start and Pause so the next driving leg counts fresh.
  bool _inHardBrake = false;

  // Hard-corner state. Two guards prevent the counter from ballooning
  // on a noisy sensor stream that jitters around `hardCornerG` — before
  // v1.1.6, a 5-minute trip could tally 10 000+ "corners" because every
  // false→true transition was counted at the raw 100 Hz sensor rate.
  //   - `_cornerSustainedSamples`: how many consecutive samples so far
  //     have been over the threshold. Only when it hits
  //     `AppConstants.hardCornerSustainedSamples` does the event count.
  //   - `_lastCornerAt`: wall-clock of the last counted event.
  //     Subsequent events within `hardCornerCooldown` are ignored — a
  //     single cornering motion never fires faster than once every
  //     ~2 s in real life.
  int _cornerSustainedSamples = 0;
  DateTime? _lastCornerAt;

  // Stopped-time / stop-count tracking (see AppConstants.stopMinDurationSeconds).
  // `_stopRunStartedAt` is when the current contiguous zero-speed run
  // began; `_stopRunCommittedSeconds` is how much of that run has
  // already been folded into `stats.stoppedSeconds` (0 until the run
  // crosses the 30s threshold, then grows every subsequent zero-speed
  // sample so a long stop doesn't have to end before it's counted).
  DateTime? _stopRunStartedAt;
  int _stopRunCommittedSeconds = 0;
  bool _stopRunCounted = false;

  // ---------- crash-recovery ----------

  /// Fired once at bloc construction. If the [ActiveTripStore] has a
  /// row from a previous session, restore the bloc into the `paused`
  /// phase so the user can tap Resume — the trip never silently
  /// disappears just because the OS killed us. If the most recent
  /// snapshot is stale (last update > 30s ago) we also flip the
  /// status to `interrupted` so the recovery banner can explain
  /// what happened.
  Future<void> _onRestoreFromCrash(
    TrackingRestoreFromCrash event,
    Emitter<TrackingState> emit,
  ) async {
    // Only meaningful on the very first frame after launch.
    if (state.phase != TrackingPhase.idle) return;
    final snap = await _activeTrip.load();
    if (snap == null) return;

    // Heuristic: if the live row hasn't been touched for more than
    // ~30 seconds we infer the OS killed the process mid-trip (the
    // hot path writes every second). Flip status → interrupted so the
    // UI can tell the user *why* the trip is paused.
    final stale =
        DateTime.now().difference(snap.updatedAt) > const Duration(seconds: 30);
    final shouldMarkInterrupted =
        stale &&
        snap.status != TripStatusEnum.interrupted &&
        snap.status != TripStatusEnum.failed;
    if (shouldMarkInterrupted) {
      unawaited(_activeTrip.setStatus(TripStatusEnum.interrupted));
    }

    _startedAt = snap.startedAt;
    _inHardBrake = false;
    _cornerSustainedSamples = 0;
    _lastCornerAt = null;
    _stopRunStartedAt = null;
    _stopRunCommittedSeconds = 0;
    _stopRunCounted = false;
    // After a process kill the GPS stream is dead — we must not pretend
    // we're still streaming. Restore as `paused` so the surface shows
    // accumulated stats + a Resume button. The first post-resume point
    // skips its distance delta (handled in _onPoint) so the gap from
    // the pre-crash lastPoint to the new fix doesn't get counted.
    _skipNextDistanceDelta = true;
    emit(
      state.copyWith(
        phase: TrackingPhase.paused,
        stats: snap.stats,
        recoveryStatus: shouldMarkInterrupted
            ? TripRecoveryStatus.interruptedByOs
            : (snap.wasPaused
                  ? TripRecoveryStatus.userPaused
                  : TripRecoveryStatus.fresh),
      ),
    );
  }

  /// Persist the most-recent summary roll-up AND refresh the live
  /// notification. Called after every meaningful state change while a
  /// trip is live (point, tick, g-force, pause / resume). Cheap —
  /// single UPDATE on the one-row live_trips table; flutter_local_-
  /// notifications collapses duplicate updates within ~250 ms.
  void _persistSummary({bool wasPaused = false}) {
    if (_startedAt == null) return;
    unawaited(_activeTrip.saveSummary(state.stats, wasPaused: wasPaused));
    unawaited(_notification.show(state.stats, paused: wasPaused));
  }

  /// Append a new waypoint AND refresh the summary AND refresh the live
  /// notification. Used by `_onPoint` when a moving sample lands.
  void _persistWaypointAndSummary(TripPoint p) {
    if (_startedAt == null) return;
    unawaited(_activeTrip.appendWaypoint(p));
    unawaited(_activeTrip.saveSummary(state.stats));
    unawaited(_notification.show(state.stats));
  }

  // ---------- user-initiated transitions ----------

  Future<void> _onStartRequested(
    TrackingStartRequested event,
    Emitter<TrackingState> emit,
  ) async {
    // Block re-entry: starting an already-active trip is a no-op.
    if (state.phase == TrackingPhase.starting ||
        state.phase == TrackingPhase.active ||
        state.phase == TrackingPhase.stopping) {
      return;
    }

    // Google Play User Data policy: the in-app Prominent Disclosure
    // must precede the system permission dialog and any background
    // location use. If the user skipped the onboarding step (or this
    // is the very first Start), surface the disclosure modal — the UI
    // re-dispatches TrackingDisclosureResolved which routes back into
    // this handler with the flag set.
    final settingsRow = await _settings.read();
    if (!settingsRow.bgLocationDisclosureAcked) {
      emit(state.copyWith(phase: TrackingPhase.needsLocationDisclosure));
      return;
    }

    _inHardBrake = false;
    _cornerSustainedSamples = 0;
    _lastCornerAt = null;
    _stopRunStartedAt = null;
    _stopRunCommittedSeconds = 0;
    _stopRunCounted = false;
    // A fresh trip means any leftover crash-recovery snapshot from a
    // prior session is stale — wipe it before we begin streaming.
    unawaited(_activeTrip.clear());
    emit(
      state.copyWith(
        phase: TrackingPhase.starting,
        stats: LiveTripStats.initial(),
        clearCompletedTripId: true,
        clearError: true,
        clearDiscardedShortTrip: true,
        shouldShowPaywall: false,
      ),
    );

    final status = await _permissions.currentLocationStatus();
    if (!_isGranted(status)) {
      emit(
        state.copyWith(
          phase: TrackingPhase.permissionDenied,
          permissionStatus: status,
        ),
      );
      return;
    }
    // Notification permission is best-effort. We request before _spinUp
    // so the system dialog surfaces from the home page (visible Activity
    // context) instead of mid-frame after the tracking page navigates.
    // Trip still starts if the user denies — the live notification just
    // won't render. The plugin's own request path was unreliable on
    // Android 13+ because it fired from a non-UI thread context.
    unawaited(_permissions.requestNotifications());
    try {
      await _notification.ensureInitialised();
      await _spinUp();
      // _spinUp set _startedAt; create the live row so subsequent
      // saveSummary calls have something to update. settingsRow was
      // already read above for the disclosure gate — reuse it instead
      // of a second round-trip.
      final settings = settingsRow;
      await _activeTrip.startTrip(uid: settings.uid, startedAt: _startedAt!);
      emit(
        state.copyWith(
          phase: TrackingPhase.active,
          recoveryStatus: TripRecoveryStatus.fresh,
        ),
      );
      _persistSummary();
      unawaited(
        _telemetry.track(
          TelemetryEvents.tripStarted,
          properties: <String, Object?>{
            'vehicle_type': settings.vehicleType,
            'is_pro': settings.isPro,
          },
        ),
      );
    } catch (e) {
      await _teardown();
      emit(
        state.copyWith(
          phase: TrackingPhase.error,
          errorMessage: 'Could not start tracking: $e',
        ),
      );
    }
  }

  /// Triggered by the page when the app resumes from background — used
  /// after the user returns from Settings. We passively read the OS
  /// state (no prompt) and drop the gate if location is now usable.
  /// Never auto-starts a trip; the user must still tap Start.
  /// Handles the outcome of the in-trip Prominent Disclosure modal.
  ///
  /// Either path persists the acked flag (Google's policy is satisfied
  /// by "we showed the disclosure", not by the user accepting). Continue
  /// re-dispatches TrackingStartRequested so the trip start sequence
  /// runs through the normal handler with the flag now true. Not now
  /// bounces back to idle without touching GPS — the user can still
  /// tap Start again later and we'll skip straight past the disclosure.
  Future<void> _onDisclosureResolved(
    TrackingDisclosureResolved event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.needsLocationDisclosure) return;
    await _settings.markBgLocationDisclosureAcked();
    if (event.proceed) {
      emit(state.copyWith(phase: TrackingPhase.idle));
      add(const TrackingStartRequested());
      return;
    }
    emit(state.copyWith(phase: TrackingPhase.idle));
  }

  Future<void> _onPermissionRechecked(
    TrackingPermissionRechecked event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.permissionDenied) return;
    final status = await _permissions.currentLocationStatus();
    if (_isGranted(status)) {
      emit(state.copyWith(phase: TrackingPhase.idle, permissionStatus: status));
      return;
    }
    // Still bad — surface the new status so the gate's button label
    // (servicesDisabled → Open Settings, etc.) reflects reality.
    emit(state.copyWith(permissionStatus: status));
  }

  Future<void> _onPauseRequested(
    TrackingPauseRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.active) return;
    // Tear down GPS + sensors so the device sleeps; the trip itself is
    // still in-progress — only End ever persists the row to Drift.
    await _teardown();
    // Reset in-event flags so the post-resume leg counts its own
    // brakes / corners cleanly, even if we paused mid-event.
    _inHardBrake = false;
    _cornerSustainedSamples = 0;
    _lastCornerAt = null;
    _stopRunStartedAt = null;
    _stopRunCommittedSeconds = 0;
    _stopRunCounted = false;
    emit(
      state.copyWith(
        phase: TrackingPhase.paused,
        recoveryStatus: TripRecoveryStatus.userPaused,
      ),
    );
    _persistSummary(wasPaused: true);
  }

  Future<void> _onResumeRequested(
    TrackingResumeRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.paused) return;
    try {
      // Shift _startedAt back by the already-accrued duration so the
      // tick formula (`now - _startedAt`) picks up exactly where it
      // left off — the paused interval is excluded automatically.
      _startedAt = DateTime.now().subtract(
        Duration(seconds: state.stats.durationSeconds),
      );
      _skipNextDistanceDelta = true;
      await _gps.start();
      await _sensors.start();
      _pointSub = _gps.points.listen((p) => add(TrackingPointReceived(p)));
      _gforceSub = _sensors.gforce.listen(
        (g) => add(TrackingGforceReceived(g)),
      );
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => add(const TrackingTicked()),
      );
      // If we were paused because the OS interrupted the previous
      // session, flip the Drift status from `interrupted` → `recovered`
      // so support tooling can tell a clean resume from a crash-recovery.
      if (state.recoveryStatus == TripRecoveryStatus.interruptedByOs) {
        unawaited(_activeTrip.setStatus(TripStatusEnum.recovered));
      }
      emit(
        state.copyWith(
          phase: TrackingPhase.active,
          recoveryStatus: TripRecoveryStatus.fresh,
        ),
      );
      _persistSummary();
    } catch (e) {
      await _teardown();
      emit(
        state.copyWith(
          phase: TrackingPhase.error,
          errorMessage: 'Could not resume tracking: $e',
        ),
      );
    }
  }

  Future<void> _onPermissionRequested(
    TrackingPermissionRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final status = await _permissions.requestLocation();
    if (!_isGranted(status)) {
      emit(
        state.copyWith(
          phase: TrackingPhase.permissionDenied,
          permissionStatus: status,
        ),
      );
      return;
    }
    // Permission just granted — continue the original Start request.
    try {
      await _spinUp();
      emit(state.copyWith(phase: TrackingPhase.active));
    } catch (e) {
      await _teardown();
      emit(
        state.copyWith(
          phase: TrackingPhase.error,
          errorMessage: 'Could not start tracking: $e',
        ),
      );
    }
  }

  Future<void> _onStopRequested(
    TrackingStopRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.active &&
        state.phase != TrackingPhase.starting &&
        state.phase != TrackingPhase.paused) {
      return;
    }
    emit(state.copyWith(phase: TrackingPhase.stopping));

    try {
      await _teardown();
    } catch (e) {
      emit(
        state.copyWith(
          phase: TrackingPhase.error,
          errorMessage: 'Could not stop tracking cleanly: $e',
        ),
      );
      return;
    }

    // Every Start → End cycle is recorded as a trip, even if the user
    // tapped End within a second of Start. Tiny trips show up in the
    // history with whatever stats they accrued (often 0 distance + a
    // duration of a few seconds). The only thing we still guard
    // against is _startedAt being null — that means we never entered
    // the active phase at all (e.g. Start → permission denied).
    if (_startedAt == null) {
      emit(
        state.copyWith(
          phase: TrackingPhase.idle,
          stats: LiveTripStats.initial(),
          clearCompletedTripId: true,
        ),
      );
      return;
    }

    try {
      final settings = await _settings.read();

      // Trips shorter than the user's configured minimum are discarded,
      // not saved — a mis-tap Start→End shouldn't clutter history.
      if (state.stats.distanceKm * 1000 < settings.minTripLengthMeters) {
        final discardedDistanceKm = state.stats.distanceKm;
        _startedAt = null;
        unawaited(_activeTrip.clear());
        unawaited(_notification.dismiss());
        emit(
          state.copyWith(
            phase: TrackingPhase.idle,
            stats: LiveTripStats.initial(),
            clearCompletedTripId: true,
            discardedTripDistanceKm: discardedDistanceKm,
          ),
        );
        return;
      }

      final detected = await _segments.detectFromTrip(state.stats.points);

      // Snapshot the pre-trip bests before saving — needed to tell
      // whether THIS trip is the one that just set a new record. Once
      // `saveTrip` below lands, `getPersonalBest`/`getLongestTrip` would
      // include this trip and the comparison would always be a tie.
      final priorBestSpeed = await _trips.getPersonalBest(uid: settings.uid);
      final priorLongest = await _trips.getLongestTrip(uid: settings.uid);

      final tripId = await _trips.saveTrip(
        uid: settings.uid,
        stats: state.stats,
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
        mapTheme: settings.selectedMapTheme,
        country: settings.country,
        roadSegmentIds: [for (final s in detected) s.id],
      );
      await _settings.incrementFreeTripsUsed();

      // MVP scope: no cloud leaderboard sync. Personal Bests are
      // recomputed locally from the trips table on demand.

      final after = await _settings.read();
      final paywallDue =
          !after.isPro && after.freeTripsUsed >= AppConstants.freeTripLimit;

      _startedAt = null;
      // Trip durably saved to Drift — wipe the crash-recovery snapshot
      // so a later cold start doesn't try to "restore" a finished trip,
      // and pull down the live notification.
      unawaited(_activeTrip.clear());
      unawaited(_notification.dismiss());
      unawaited(
        _telemetry.track(
          TelemetryEvents.tripEnded,
          properties: <String, Object?>{
            'distance_km': state.stats.distanceKm,
            'duration_seconds': state.stats.durationSeconds,
            'top_speed_kmh': state.stats.maxSpeedKmh,
            'hard_brakes': state.stats.hardBrakesCount,
            'hard_corners': state.stats.hardCornersCount,
            'was_recovered':
                state.recoveryStatus == TripRecoveryStatus.interruptedByOs,
          },
        ),
      );
      // Retention-funnel milestones — fire once each, the moment the
      // user's lifetime trip count crosses the threshold. This is what
      // actually measures install → 2nd-trip drop-off; `tripEnded`
      // alone can't distinguish a returning user from a first-timer.
      // Also drives the retention scheduler's first-trip-followup /
      // inactivity-nudge / weekly-recap bookkeeping — same count query,
      // reused rather than run twice.
      unawaited(
        _trips.countAll(uid: settings.uid).then((count) async {
          if (count == 1) {
            await _telemetry.track(TelemetryEvents.firstTripCompleted);
          } else if (count == 2) {
            await _telemetry.track(TelemetryEvents.secondTripCompleted);
          }
          await _retention.onTripCompleted(
            uid: settings.uid,
            tripCountIncludingThis: count,
            tripEndedAt: DateTime.now(),
          );
        }),
      );
      unawaited(
        _handleRecordsAndGoals(
          settings: settings,
          isFirstTrip: priorBestSpeed == null,
          priorBestSpeedKmh: priorBestSpeed?.topSpeedKmh ?? 0,
          priorLongestKm: priorLongest?.distanceKm ?? 0,
          // Captured here, not read from `state` inside the helper —
          // the `emit()` a few lines below resets `state.stats` to
          // `LiveTripStats.initial()`, and this call is `unawaited`
          // (fire-and-forget), so the helper could easily end up
          // reading the reset value instead of this trip's actual
          // stats depending on how its internal awaits interleave.
          tripSpeedKmh: state.stats.maxSpeedKmh,
          tripDistanceKm: state.stats.distanceKm,
        ),
      );
      emit(
        state.copyWith(
          phase: TrackingPhase.idle,
          completedTripId: tripId,
          shouldShowPaywall: paywallDue,
          stats: LiveTripStats.initial(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: TrackingPhase.error,
          errorMessage: 'Could not save trip: $e',
        ),
      );
    }
  }

  /// Compares the just-saved trip against the pre-trip bests/goals to
  /// fire personal-record + goal telemetry, trigger the record
  /// celebration notification, and persist the next goal.
  ///
  /// [isFirstTrip] guards against a false "personal record" on a
  /// user's very first trip ever — `priorBestSpeedKmh`/`priorLongestKm`
  /// are 0 with nothing to actually beat, so without this guard every
  /// first trip would fire a record celebration for beating "0 km/h".
  Future<void> _handleRecordsAndGoals({
    required UserSettingsRow settings,
    required bool isFirstTrip,
    required double priorBestSpeedKmh,
    required double priorLongestKm,
    required double tripSpeedKmh,
    required double tripDistanceKm,
  }) async {
    final result = RecordGoalEvaluator.evaluate(
      isFirstTrip: isFirstTrip,
      priorBestSpeedKmh: priorBestSpeedKmh,
      priorLongestKm: priorLongestKm,
      activeSpeedGoalKmh: settings.speedGoalKmh,
      activeDistanceGoalKm: settings.distanceGoalKm,
      tripSpeedKmh: tripSpeedKmh,
      tripDistanceKm: tripDistanceKm,
    );

    if (result.newSpeedRecord) {
      await _telemetry.track(
        TelemetryEvents.personalRecordAchieved,
        properties: <String, Object?>{
          'kind': 'speed',
          'value_kmh': tripSpeedKmh,
        },
      );
    }
    if (result.newDistanceRecord) {
      await _telemetry.track(
        TelemetryEvents.personalRecordAchieved,
        properties: <String, Object?>{
          'kind': 'distance',
          'value_km': tripDistanceKm,
        },
      );
    }
    // At most one celebration per trip, even if both broke on the same
    // drive — speed is the flashier metric and takes priority so the
    // user isn't double-notified for one trip.
    if (result.newSpeedRecord) {
      await _retention.celebratePersonalRecord(
        kind: RecordCelebrationKind.speed,
        valueKmh: tripSpeedKmh,
      );
    } else if (result.newDistanceRecord) {
      await _retention.celebratePersonalRecord(
        kind: RecordCelebrationKind.distance,
        valueKmh: tripDistanceKm,
      );
    }

    if (result.speedGoalAchieved) {
      await _telemetry.track(
        TelemetryEvents.goalAchieved,
        properties: <String, Object?>{'kind': 'speed'},
      );
    }
    if (result.distanceGoalAchieved) {
      await _telemetry.track(
        TelemetryEvents.goalAchieved,
        properties: <String, Object?>{'kind': 'distance'},
      );
    }

    final nextSpeedGoal = result.nextSpeedGoalKmh;
    final nextDistanceGoal = result.nextDistanceGoalKm;
    if (nextSpeedGoal != null || nextDistanceGoal != null) {
      await _settings.setGoals(
        speedGoalKmh: nextSpeedGoal,
        distanceGoalKm: nextDistanceGoal,
      );
      await _telemetry.track(
        TelemetryEvents.goalCreated,
        properties: <String, Object?>{
          if (nextSpeedGoal != null) 'speed_goal_kmh': nextSpeedGoal,
          if (nextDistanceGoal != null) 'distance_goal_km': nextDistanceGoal,
        },
      );
    }
  }

  Future<void> _onReset(
    TrackingReset event,
    Emitter<TrackingState> emit,
  ) async {
    await _teardown();
    _startedAt = null;
    unawaited(_activeTrip.clear());
    unawaited(_notification.dismiss());
    emit(TrackingState.initial());
  }

  // ---------- internal stream-driven transitions ----------

  void _onPoint(TrackingPointReceived event, Emitter<TrackingState> emit) {
    if (state.phase != TrackingPhase.active) return;
    final p = event.point;
    final prev = state.stats;

    // Hard-brake detection — a drop ≥ hardBrakeDropKmh between two
    // consecutive moving samples counts. Counter only steps on the
    // transition (false→true), so one sustained brake = +1, not +N.
    var hardBrakes = prev.hardBrakesCount;
    final brakeDrop = prev.currentSpeedKmh - p.speedKmh;
    if (prev.currentSpeedKmh > 0 &&
        brakeDrop >= AppConstants.hardBrakeDropKmh) {
      if (!_inHardBrake) {
        hardBrakes += 1;
        _inHardBrake = true;
      }
    } else {
      _inHardBrake = false;
    }

    // Stationary case — keep the speedometer at 0 and the new brake
    // count, but DON'T touch the polyline / distance / lastPoint. GPS
    // drift around a parked car shouldn't pile up as fake travel.
    if (p.speedKmh == 0) {
      var stoppedSeconds = prev.stoppedSeconds;
      var stopCount = prev.stopCount;
      if (_stopRunStartedAt == null) {
        // First zero-speed sample of a new run — nothing committed yet.
        _stopRunStartedAt = p.timestamp;
        _stopRunCommittedSeconds = 0;
        _stopRunCounted = false;
      } else {
        final elapsed = p.timestamp
            .difference(_stopRunStartedAt!)
            .inSeconds;
        if (elapsed >= AppConstants.stopMinDurationSeconds) {
          if (!_stopRunCounted) {
            stopCount += 1;
            _stopRunCounted = true;
          }
          stoppedSeconds += elapsed - _stopRunCommittedSeconds;
          _stopRunCommittedSeconds = elapsed;
        }
      }
      emit(
        state.copyWith(
          stats: prev.copyWith(
            currentSpeedKmh: 0,
            hardBrakesCount: hardBrakes,
            stoppedSeconds: stoppedSeconds,
            stopCount: stopCount,
          ),
        ),
      );
      _persistSummary();
      return;
    }
    // Moving again — end whatever stop run was in progress.
    _stopRunStartedAt = null;
    _stopRunCommittedSeconds = 0;
    _stopRunCounted = false;

    final wasFirstFix = prev.lastPoint == null;
    // After a resume, drop the very first distance delta — the user
    // may have travelled / parked / moved while paused, so the gap
    // from the pre-pause `lastPoint` to this point would be a
    // teleport. Subsequent points compute normally.
    final isFirstFixAfterResume = _skipNextDistanceDelta;
    if (isFirstFixAfterResume) {
      _skipNextDistanceDelta = false;
    }

    final newDistance = (wasFirstFix || isFirstFixAfterResume)
        ? prev.distanceKm
        : prev.distanceKm + _gps.distanceMeters(prev.lastPoint!, p) / 1000.0;

    // maxSpeedKmh only steps when we have *sustained* motion — i.e. both
    // this sample and the previous one report > 0 km/h. A single noisy
    // sample slipping past the denoiser can't anchor the saved
    // `topSpeedKmh` any more.
    final isSustainedMotion = prev.currentSpeedKmh > 0 && p.speedKmh > 0;
    final newMaxSpeed = (isSustainedMotion && p.speedKmh > prev.maxSpeedKmh)
        ? p.speedKmh
        : prev.maxSpeedKmh;

    final durationSeconds = _startedAt == null
        ? prev.durationSeconds
        : DateTime.now().difference(_startedAt!).inSeconds;
    final avg = durationSeconds == 0
        ? 0.0
        : (newDistance / (durationSeconds / 3600));

    emit(
      state.copyWith(
        stats: prev.copyWith(
          currentSpeedKmh: p.speedKmh,
          maxSpeedKmh: newMaxSpeed,
          avgSpeedKmh: avg,
          distanceKm: newDistance,
          durationSeconds: durationSeconds,
          lastPoint: p,
          points: [...prev.points, p],
          hardBrakesCount: hardBrakes,
        ),
      ),
    );
    _persistWaypointAndSummary(p);
  }

  void _onGforce(TrackingGforceReceived event, Emitter<TrackingState> emit) {
    if (state.phase != TrackingPhase.active) return;
    final g = event.gforce;
    final prev = state.stats;

    // Hard-corner detection with sustained-sample gating + cooldown.
    //
    // Before v1.1.6 this counted every false→true threshold crossing,
    // which — combined with a 100 Hz noisy sensor stream jittering
    // around `hardCornerG` — produced 10 000+ "corners" on a 5-minute
    // trip. Now the counter only steps when the g-force stays above
    // the threshold for `hardCornerSustainedSamples` consecutive
    // samples (~300 ms at the throttled 10 Hz stream) AND the last
    // counted event is at least `hardCornerCooldown` in the past.
    // A single 1.5 s sweeping turn = +1. A wobbly phone in a cup
    // holder = 0.
    var hardCorners = prev.hardCornersCount;
    final movingFastEnoughToCorner =
        prev.currentSpeedKmh >= AppConstants.hardCornerMinSpeedKmh;
    if (movingFastEnoughToCorner && g >= AppConstants.hardCornerG) {
      _cornerSustainedSamples += 1;
      final now = DateTime.now();
      final offCooldown =
          _lastCornerAt == null ||
          now.difference(_lastCornerAt!) >= AppConstants.hardCornerCooldown;
      if (_cornerSustainedSamples >= AppConstants.hardCornerSustainedSamples &&
          offCooldown) {
        hardCorners += 1;
        _lastCornerAt = now;
        // Force the next event to build up sustained-sample credit
        // from scratch — otherwise we'd tally another tick every
        // frame the load stayed above threshold after cooldown.
        _cornerSustainedSamples = 0;
      }
    } else {
      _cornerSustainedSamples = 0;
    }

    // Safety belt: samples that slipped through `SensorService`'s
    // noise ceiling shouldn't be recorded as the trip's peak either.
    // Anything past 3 g under normal driving is a bump / phone drop.
    final clampedG = g > AppConstants.gForceNoiseCeiling ? prev.maxGforce : g;
    final newMax = clampedG > prev.maxGforce ? clampedG : prev.maxGforce;
    if (newMax == prev.maxGforce && hardCorners == prev.hardCornersCount) {
      return; // nothing changed; avoid a redundant emit per tick
    }
    emit(
      state.copyWith(
        stats: prev.copyWith(maxGforce: newMax, hardCornersCount: hardCorners),
      ),
    );
    _persistSummary();
  }

  void _onTick(TrackingTicked event, Emitter<TrackingState> emit) {
    if (state.phase != TrackingPhase.active) return;
    if (_startedAt == null) return;
    final seconds = DateTime.now().difference(_startedAt!).inSeconds;
    if (seconds == state.stats.durationSeconds) return;
    emit(state.copyWith(stats: state.stats.copyWith(durationSeconds: seconds)));
    _persistSummary();
  }

  // ---------- helpers ----------

  bool _isGranted(LocationPermissionStatus status) =>
      status == LocationPermissionStatus.granted ||
      status == LocationPermissionStatus.grantedAlways;

  Future<void> _spinUp() async {
    _startedAt = DateTime.now();
    await _gps.start();
    await _sensors.start();
    _pointSub = _gps.points.listen((p) => add(TrackingPointReceived(p)));
    _gforceSub = _sensors.gforce.listen((g) => add(TrackingGforceReceived(g)));
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const TrackingTicked()),
    );
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _pointSub?.cancel();
    _pointSub = null;
    await _gforceSub?.cancel();
    _gforceSub = null;
    await _gps.stop();
    await _sensors.stop();
  }

  @override
  Future<void> close() async {
    await _notificationEndSub?.cancel();
    _notificationEndSub = null;
    await _teardown();
    return super.close();
  }
}
