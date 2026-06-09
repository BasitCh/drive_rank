import 'dart:async';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/sensor_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
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
  }

  final GpsService _gps;
  final SensorService _sensors;
  final PermissionService _permissions;
  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final RoadSegmentService _segments;

  StreamSubscription<TripPoint>? _pointSub;
  StreamSubscription<double>? _gforceSub;
  Timer? _ticker;
  DateTime? _startedAt;
  // Set when the user resumes from pause so the very first post-resume
  // GPS point doesn't add a teleport distance from the pre-pause
  // `lastPoint` (the user may have walked / parked / driven elsewhere
  // while paused). Consumed on the next `_onPoint`.
  bool _skipNextDistanceDelta = false;

  // "Currently inside an event" flags for the hard-brake / hard-corner
  // detectors. The counters only step on the transition from false→true,
  // so a single 5-sample-long hard brake increments hardBrakesCount once.
  // Reset on Start and Pause so the next driving leg counts fresh.
  bool _inHardBrake = false;
  bool _inHardCorner = false;

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
    _inHardBrake = false;
    _inHardCorner = false;
    emit(
      state.copyWith(
        phase: TrackingPhase.starting,
        stats: LiveTripStats.initial(),
        clearCompletedTripId: true,
        clearError: true,
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

  /// Triggered by the page when the app resumes from background — used
  /// after the user returns from Settings. We passively read the OS
  /// state (no prompt) and drop the gate if location is now usable.
  /// Never auto-starts a trip; the user must still tap Start.
  Future<void> _onPermissionRechecked(
    TrackingPermissionRechecked event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.phase != TrackingPhase.permissionDenied) return;
    final status = await _permissions.currentLocationStatus();
    if (_isGranted(status)) {
      emit(state.copyWith(
        phase: TrackingPhase.idle,
        permissionStatus: status,
      ));
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
    _inHardCorner = false;
    emit(state.copyWith(phase: TrackingPhase.paused));
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
      _pointSub = _gps.points.listen(
        (p) => add(TrackingPointReceived(p)),
      );
      _gforceSub = _sensors.gforce.listen(
        (g) => add(TrackingGforceReceived(g)),
      );
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => add(const TrackingTicked()),
      );
      emit(state.copyWith(phase: TrackingPhase.active));
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
      final detected = await _segments.detectFromTrip(state.stats.points);
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
      final paywallDue = !after.isPro &&
          after.freeTripsUsed >= AppConstants.freeTripLimit;

      _startedAt = null;
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

  Future<void> _onReset(
    TrackingReset event,
    Emitter<TrackingState> emit,
  ) async {
    await _teardown();
    _startedAt = null;
    emit(TrackingState.initial());
  }

  // ---------- internal stream-driven transitions ----------

  void _onPoint(
    TrackingPointReceived event,
    Emitter<TrackingState> emit,
  ) {
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
      emit(
        state.copyWith(
          stats: prev.copyWith(
            currentSpeedKmh: 0,
            hardBrakesCount: hardBrakes,
          ),
        ),
      );
      return;
    }

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

    final newMaxSpeed =
        p.speedKmh > prev.maxSpeedKmh ? p.speedKmh : prev.maxSpeedKmh;

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
  }

  void _onGforce(
    TrackingGforceReceived event,
    Emitter<TrackingState> emit,
  ) {
    if (state.phase != TrackingPhase.active) return;
    final g = event.gforce;
    final prev = state.stats;

    // Hard-corner detection — same transition pattern as hard brakes:
    // counter only steps when we cross from below threshold to above,
    // so a single 1.5s 0.6g sweeping turn = +1, not many.
    var hardCorners = prev.hardCornersCount;
    if (g >= AppConstants.hardCornerG) {
      if (!_inHardCorner) {
        hardCorners += 1;
        _inHardCorner = true;
      }
    } else {
      _inHardCorner = false;
    }

    final newMax = g > prev.maxGforce ? g : prev.maxGforce;
    if (newMax == prev.maxGforce && hardCorners == prev.hardCornersCount) {
      return; // nothing changed; avoid a redundant emit per tick
    }
    emit(
      state.copyWith(
        stats: prev.copyWith(
          maxGforce: newMax,
          hardCornersCount: hardCorners,
        ),
      ),
    );
  }

  void _onTick(TrackingTicked event, Emitter<TrackingState> emit) {
    if (state.phase != TrackingPhase.active) return;
    if (_startedAt == null) return;
    final seconds = DateTime.now().difference(_startedAt!).inSeconds;
    if (seconds == state.stats.durationSeconds) return;
    emit(
      state.copyWith(stats: state.stats.copyWith(durationSeconds: seconds)),
    );
  }

  // ---------- helpers ----------

  bool _isGranted(LocationPermissionStatus status) =>
      status == LocationPermissionStatus.granted ||
      status == LocationPermissionStatus.grantedAlways;

  Future<void> _spinUp() async {
    _startedAt = DateTime.now();
    await _gps.start();
    await _sensors.start();
    _pointSub = _gps.points.listen(
      (p) => add(TrackingPointReceived(p)),
    );
    _gforceSub = _sensors.gforce.listen(
      (g) => add(TrackingGforceReceived(g)),
    );
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
    await _teardown();
    return super.close();
  }
}
