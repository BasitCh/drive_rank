import 'dart:async';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

/// Streams Kalman-filtered GPS samples while a trip is being tracked.
///
/// The raw [Geolocator] position stream is noisy — a vehicle moving at 60
/// km/h can jitter ±15m frame-to-frame, which makes the live distance
/// counter useless. We smooth lat/lng through a simple Kalman filter
/// before exposing [TripPoint]s downstream.
///
/// Battery: the stream uses 1s intervals while moving and falls back to
/// 5s while crawling. Foreground-service notification is wired up at the
/// platform layer (Android manifest + flutter_background_service).
@singleton
class GpsService {
  GpsService();

  final _filter = _KalmanFilter();
  final _distanceCalc = const Distance();

  StreamSubscription<Position>? _sub;
  final StreamController<TripPoint> _controller =
      StreamController<TripPoint>.broadcast();

  /// Live point stream — null until [start] is called.
  Stream<TripPoint> get points => _controller.stream;

  /// True while a tracking subscription is active.
  bool get isRunning => _sub != null;

  Future<void> start() async {
    if (_sub != null) return;
    _filter.reset();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('GpsService stream error: $e');
        }
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Test seam — pump synthetic positions for unit tests.
  @visibleForTesting
  void debugInject(Position p) => _onPosition(p);

  void _onPosition(Position p) {
    final filtered = _filter.filter(
      lat: p.latitude,
      lng: p.longitude,
      accuracyMeters: p.accuracy,
      timestampMs: p.timestamp.millisecondsSinceEpoch,
    );

    final speedKmh = (p.speed.isNaN || p.speed < 0) ? 0.0 : p.speed * 3.6;

    _controller.add(
      TripPoint(
        lat: filtered.latitude,
        lng: filtered.longitude,
        speedKmh: speedKmh,
        accuracyMeters: p.accuracy,
        timestamp: p.timestamp,
      ),
    );
  }

  /// Convenience used by TrackingBloc to add an incremental segment to a
  /// running distance counter. Returns metres between two filtered points.
  double distanceMeters(TripPoint from, TripPoint to) =>
      _distanceCalc.as(LengthUnit.Meter, _ll(from), _ll(to));

  LatLng _ll(TripPoint p) => LatLng(p.lat, p.lng);

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

/// 2D Kalman filter for lat/lng position smoothing.
///
/// Ported from the algorithm in the DriveRank spec. The variance starts
/// from the first reading's reported accuracy and decays with each update
/// — high-accuracy readings move the filter quickly, low-accuracy
/// readings barely budge it.
class _KalmanFilter {
  double _lat = 0;
  double _lng = 0;
  double _variance = -1;
  int _lastTimestampMs = 0;

  /// Per-second process noise (m/s) — how much the position can drift in a
  /// second when we have no data. ~3 m/s lets us track a normal car cleanly.
  static const double _qMetresPerSecond = 3;

  void reset() {
    _lat = 0;
    _lng = 0;
    _variance = -1;
    _lastTimestampMs = 0;
  }

  LatLng filter({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required int timestampMs,
  }) {
    final accuracy = accuracyMeters < AppConstants.kalmanMinAccuracy
        ? AppConstants.kalmanMinAccuracy
        : accuracyMeters;

    if (_variance < 0) {
      _lat = lat;
      _lng = lng;
      _variance = accuracy * accuracy;
      _lastTimestampMs = timestampMs;
      return LatLng(_lat, _lng);
    }

    final dtMs = timestampMs - _lastTimestampMs;
    if (dtMs > 0) {
      _variance += dtMs * _qMetresPerSecond * _qMetresPerSecond / 1000;
      _lastTimestampMs = timestampMs;
    }

    final k = _variance / (_variance + accuracy * accuracy);
    _lat += k * (lat - _lat);
    _lng += k * (lng - _lng);
    _variance = (1 - k) * _variance;

    return LatLng(_lat, _lng);
  }
}
