import 'package:flutter/foundation.dart';

/// A single Kalman-filtered GPS sample emitted by `GpsService` during a
/// live trip. All values are metric (km/h, metres). The raw geolocator
/// reading is never exposed — points are smoothed first.
@immutable
class TripPoint {
  const TripPoint({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.accuracyMeters,
    required this.timestamp,
    this.altitudeMeters,
    this.heading,
  });

  final double lat;
  final double lng;
  final double speedKmh;
  final double accuracyMeters;
  final DateTime timestamp;

  /// Altitude above sea level, or null when the fix's reported altitude
  /// accuracy was too poor to trust (see
  /// `AppConstants.maxReliableAltitudeAccuracyMeters`).
  final double? altitudeMeters;

  /// Compass bearing in degrees (0-360), or null when the fix didn't
  /// report one or the vehicle was too slow for heading to be
  /// meaningful (see `AppConstants.turnMinSpeedKmh`).
  final double? heading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripPoint &&
          other.lat == lat &&
          other.lng == lng &&
          other.speedKmh == speedKmh &&
          other.accuracyMeters == accuracyMeters &&
          other.timestamp == timestamp &&
          other.altitudeMeters == altitudeMeters &&
          other.heading == heading);

  @override
  int get hashCode => Object.hash(
    lat,
    lng,
    speedKmh,
    accuracyMeters,
    timestamp,
    altitudeMeters,
    heading,
  );
}
