import 'dart:async';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/sensor_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/leaderboard_writer.dart';
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
    on<TrackingPermissionRequested>(_onPermissionRequested);
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
        state.phase != TrackingPhase.starting) {
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

    // Skip persisting a no-distance trip — keeps history clean.
    if (state.stats.distanceKm <= 0 || _startedAt == null) {
      emit(
        state.copyWith(
          phase: TrackingPhase.idle,
          stats: LiveTripStats.initial(),
          clearCompletedTripId: true,
        ),
      );
      _startedAt = null;
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

      // Push the user's all-time best to the global + country boards.
      // Only registered when Firebase is live — silently skipped in the
      // preview build so trip recording stays local-only.
      if (getIt.isRegistered<LeaderboardWriter>()) {
        unawaited(getIt<LeaderboardWriter>().publishCurrentBest());
      }

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
    final wasFirstFix = prev.lastPoint == null;

    final newDistance = wasFirstFix
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
        ),
      ),
    );
  }

  void _onGforce(
    TrackingGforceReceived event,
    Emitter<TrackingState> emit,
  ) {
    if (state.phase != TrackingPhase.active) return;
    if (event.gforce <= state.stats.maxGforce) return;
    emit(state.copyWith(stats: state.stats.copyWith(maxGforce: event.gforce)));
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
