import 'dart:async';
import 'dart:io' show Platform;

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

  /// Tracked for the spike filter — a sample whose speed differs from this
  /// by more than [AppConstants.maxSpeedDeltaPerSampleKmh] is a GPS glitch
  /// and is discarded. Reset on every [start].
  double _previousSpeedKmh = 0;

  /// Number of consecutive spike-filter rejections. If we stay rejected for
  /// [_spikeFilterRecoveryAfter] samples in a row, the filter trusts the
  /// next candidate even if it would otherwise be flagged as a spike —
  /// otherwise a low first-fix permanently anchors the filter at e.g.
  /// 5 km/h while real driving is at 60+ km/h.
  int _stuckRejectionStreak = 0;
  static const int _spikeFilterRecoveryAfter = 3;

  /// Live point stream — null until [start] is called.
  Stream<TripPoint> get points => _controller.stream;

  /// True while a tracking subscription is active.
  bool get isRunning => _sub != null;

  Future<void> start() async {
    if (_sub != null) return;
    _filter.reset();
    _previousSpeedKmh = 0;
    _stuckRejectionStreak = 0;

    _sub = Geolocator.getPositionStream(
      locationSettings: _platformSettings(),
    ).listen(
      _onPosition,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('GpsService stream error: $e');
        }
      },
    );

    // Skip the cold-start wait by emitting a TripPoint built from the
    // device's last known position right away — the live stream will
    // overwrite within a second or two. Without this, the user stares
    // at "Waiting for GPS…" for 5-30s on a cold chip.
    // Best-effort: returns null on devices with no recent fix.
    unawaited(_emitCachedFix());
  }

  Future<void> _emitCachedFix() async {
    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached == null || _sub == null || _controller.isClosed) return;
      // Force speed to 0 — the cached position's speed may be from a
      // previous session (e.g. last Maps trip an hour ago). Surfacing
      // a stale "you're at 60 km/h" reading here would anchor maxSpeed
      // and avg before the live stream even starts.
      _controller.add(
        TripPoint(
          lat: cached.latitude,
          lng: cached.longitude,
          speedKmh: 0,
          accuracyMeters: cached.accuracy,
          timestamp: cached.timestamp,
        ),
      );
    } catch (_) {
      // Permission edge cases / no-fix devices — swallow; the live
      // stream is still wired up and will fire when it gets a fix.
    }
  }

  /// Build platform-specific location settings.
  ///
  /// **Android**: promote the location stream to a foreground service via
  /// [ForegroundNotificationConfig]. Without this, Android's battery
  /// manager throttles or kills the stream after ~10 min of sustained use,
  /// which is the "speed becomes zero after a while" bug users report.
  /// `intervalDuration: 1s` pins the sample rate so the live speedometer
  /// stays responsive instead of inheriting the OS's variable cadence
  /// (often 2–3s on bestForNavigation when not pinned).
  ///
  /// **iOS**: `automotiveNavigation` activity type tells CoreLocation we're
  /// in a car — biases the GPS/INS fusion for vehicle speeds and prevents
  /// the OS from auto-pausing updates when motion looks "vehicular".
  LocationSettings _platformSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          // Passive copy — the live-speed notification from
          // LiveTripNotificationService is what users actually look at.
          // This one just satisfies Android's "foreground service must
          // have a visible notification" rule.
          notificationTitle: 'DriveRank',
          notificationText: 'Background tracking active',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            // Must match the drawable used by LiveTripNotificationService
            // (`res/drawable/ic_stat_drive.xml`) — the launcher mipmap is
            // not a valid notification icon.
            name: 'ic_stat_drive',
            defType: 'drawable',
          ),
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
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

    final speedKmh = _denoiseSpeed(
      rawSpeedMetresPerSecond: p.speed,
      accuracyMeters: p.accuracy,
    );

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

  /// Filters out the two flavours of GPS noise that make the live speed
  /// counter feel broken:
  ///   1. Drift: when the device is stationary, GPS still reports
  ///      sub-3 km/h drifts. Clamp anything below
  ///      [AppConstants.minReliableSpeedKmh] to zero, and do the same
  ///      when reported accuracy is worse than
  ///      [AppConstants.maxReliableAccuracyMeters] (motion is
  ///      unresolvable at that error level).
  ///   2. Spikes: a fix that disagrees with the last one by more than
  ///      [AppConstants.maxSpeedDeltaPerSampleKmh] is a glitch — keep
  ///      the previous reading rather than emitting the spike.
  ///
  /// Internally everything is km/h. Never returns mph; the display
  /// layer converts via `LocaleService` only.
  double _denoiseSpeed({
    required double rawSpeedMetresPerSecond,
    required double accuracyMeters,
  }) {
    // Geolocator can report NaN or negative speeds on cold-start fixes.
    if (rawSpeedMetresPerSecond.isNaN || rawSpeedMetresPerSecond < 0) {
      _previousSpeedKmh = 0;
      _stuckRejectionStreak = 0;
      return 0;
    }
    final candidate = rawSpeedMetresPerSecond * 3.6;

    // Absolute physical cap — no consumer road vehicle exceeds this
    // legitimately. Applies before every other filter, including the
    // recovery path, so a single 363 km/h glitch (a real user report
    // on a bus after 10 min of poor-accuracy readings) can NEVER
    // become the trip's top speed. Delta-based filters can't catch
    // this case because previous speed was 0 the whole time.
    if (candidate > AppConstants.maxPlausibleRoadSpeedKmh) {
      _stuckRejectionStreak = 0;
      return _previousSpeedKmh;
    }

    // Drift filter — too slow or accuracy too poor → treat as stationary.
    if (candidate < AppConstants.minReliableSpeedKmh ||
        accuracyMeters > AppConstants.maxReliableAccuracyMeters) {
      _previousSpeedKmh = 0;
      _stuckRejectionStreak = 0;
      return 0;
    }

    // Spike filter with recovery — a single big jump is treated as a GPS
    // glitch (keep the previous reading), but if we'd otherwise reject
    // [_spikeFilterRecoveryAfter] candidates in a row, the next one is
    // accepted on the assumption that the previous reading was the
    // stale one (e.g. an anchored low first fix). This is what unsticks
    // a trip that was anchored at 5 km/h while the user accelerated.
    if (_previousSpeedKmh > 0 &&
        (candidate - _previousSpeedKmh).abs() >
            AppConstants.maxSpeedDeltaPerSampleKmh) {
      _stuckRejectionStreak += 1;
      if (_stuckRejectionStreak <= _spikeFilterRecoveryAfter) {
        return _previousSpeedKmh;
      }
      // Fall through — sustained "spike" is actually the new truth.
    }

    _stuckRejectionStreak = 0;
    _previousSpeedKmh = candidate;
    return candidate;
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
