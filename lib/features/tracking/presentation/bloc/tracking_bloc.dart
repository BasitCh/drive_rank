import 'dart:async';

import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/sensor_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Coordinates the live-tracking screen.
///
/// Responsibilities:
///  - Resolve location permission before the GPS stream is started.
///  - Subscribe to GPS + sensor streams and aggregate them into
///    `LiveTripStats` (top speed, distance via Haversine, duration, max g).
///  - Tick a per-second timer for duration display so the UI updates even
///    when the vehicle is stationary.
///  - Tear down streams on stop and emit `TrackingPhase.finished`.
///
/// Trip persistence to Drift happens in Session 3 (Trip Summary feature).
/// For now we keep the trip purely in memory — when the user ends the trip
/// they're navigated to the trip summary page which receives the stats.
@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc(this._gps, this._sensors, this._permissions)
    : super(TrackingState.initial()) {
    on<TrackingStarted>(_onStarted);
    on<TrackingStopRequested>(_onStop);
    on<TrackingPointReceived>(_onPoint);
    on<TrackingGforceReceived>(_onGforce);
    on<TrackingTicked>(_onTick);
    on<TrackingPermissionRequested>(_onPermissionRequested);
  }

  final GpsService _gps;
  final SensorService _sensors;
  final PermissionService _permissions;

  StreamSubscription<TripPoint>? _pointSub;
  StreamSubscription<double>? _gforceSub;
  Timer? _ticker;
  DateTime? _startedAt;

  Future<void> _onStarted(
    TrackingStarted event,
    Emitter<TrackingState> emit,
  ) async {
    final status = await _permissions.currentLocationStatus();
    if (status == LocationPermissionStatus.servicesDisabled) {
      emit(
        state.copyWith(
          phase: TrackingPhase.servicesDisabled,
          permissionStatus: status,
        ),
      );
      return;
    }
    if (status != LocationPermissionStatus.granted &&
        status != LocationPermissionStatus.grantedAlways) {
      emit(
        state.copyWith(
          phase: TrackingPhase.permissionRequired,
          permissionStatus: status,
        ),
      );
      return;
    }
    await _spinUp(emit);
  }

  Future<void> _onPermissionRequested(
    TrackingPermissionRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final status = await _permissions.requestLocation();
    if (status == LocationPermissionStatus.granted ||
        status == LocationPermissionStatus.grantedAlways) {
      await _spinUp(emit);
      return;
    }
    emit(
      state.copyWith(
        phase: status == LocationPermissionStatus.servicesDisabled
            ? TrackingPhase.servicesDisabled
            : TrackingPhase.permissionRequired,
        permissionStatus: status,
      ),
    );
  }

  Future<void> _spinUp(Emitter<TrackingState> emit) async {
    emit(
      state.copyWith(
        phase: TrackingPhase.waitingForFix,
        stats: LiveTripStats.initial(),
      ),
    );
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

  Future<void> _onStop(
    TrackingStopRequested event,
    Emitter<TrackingState> emit,
  ) async {
    await _teardown();
    emit(state.copyWith(phase: TrackingPhase.finished));
  }

  void _onPoint(
    TrackingPointReceived event,
    Emitter<TrackingState> emit,
  ) {
    final p = event.point;
    final prev = state.stats;
    final wasFirstFix = prev.lastPoint == null;

    final newDistance = wasFirstFix
        ? prev.distanceKm
        : prev.distanceKm + _gps.distanceMeters(prev.lastPoint!, p) / 1000.0;

    final newMaxSpeed = p.speedKmh > prev.maxSpeedKmh
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
        phase: TrackingPhase.recording,
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
    if (event.gforce <= state.stats.maxGforce) return;
    emit(state.copyWith(stats: state.stats.copyWith(maxGforce: event.gforce)));
  }

  void _onTick(TrackingTicked event, Emitter<TrackingState> emit) {
    if (_startedAt == null) return;
    final seconds = DateTime.now().difference(_startedAt!).inSeconds;
    if (seconds == state.stats.durationSeconds) return;
    emit(
      state.copyWith(stats: state.stats.copyWith(durationSeconds: seconds)),
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
