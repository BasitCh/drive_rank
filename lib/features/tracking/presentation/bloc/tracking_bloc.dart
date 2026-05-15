import 'dart:async';

import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/sensor_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
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
///  - Tear down streams on stop, persist the trip (with all waypoints) in
///    a single Drift transaction, emit `TrackingPhase.finished` with the
///    new tripId — the page listens for that id and navigates to the
///    trip summary.
@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc(
    this._gps,
    this._sensors,
    this._permissions,
    this._trips,
    this._settings,
  ) : super(TrackingState.initial()) {
    on<TrackingStarted>(_onStarted);
    on<TrackingStopRequested>(_onStop);
    on<TrackingPointReceived>(_onPoint);
    on<TrackingGforceReceived>(_onGforce);
    on<TrackingTicked>(_onTick);
    on<TrackingPermissionRequested>(_onPermissionRequested);
    on<TrackingReset>(_onReset);
  }

  Future<void> _onReset(
    TrackingReset event,
    Emitter<TrackingState> emit,
  ) async {
    await _teardown();
    _startedAt = null;
    emit(TrackingState.initial());
    add(const TrackingStarted());
  }

  final GpsService _gps;
  final SensorService _sensors;
  final PermissionService _permissions;
  final TripRepository _trips;
  final UserSettingsRepository _settings;

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

    // Skip persisting a trip with zero distance (user tapped end before
    // moving) — keeps history clean of "0 km · 5s" stubs.
    if (state.stats.distanceKm <= 0 || _startedAt == null) {
      emit(state.copyWith(phase: TrackingPhase.finished));
      return;
    }

    final settings = await _settings.read();
    final tripId = await _trips.saveTrip(
      uid: settings.uid,
      stats: state.stats,
      startedAt: _startedAt!,
      endedAt: DateTime.now(),
      mapTheme: settings.selectedMapTheme,
      country: settings.country,
    );
    await _settings.incrementFreeTripsUsed();

    emit(
      state.copyWith(
        phase: TrackingPhase.finished,
        completedTripId: tripId,
      ),
    );
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
