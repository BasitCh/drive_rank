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
  });

  final double lat;
  final double lng;
  final double speedKmh;
  final double accuracyMeters;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripPoint &&
          other.lat == lat &&
          other.lng == lng &&
          other.speedKmh == speedKmh &&
          other.accuracyMeters == accuracyMeters &&
          other.timestamp == timestamp);

  @override
  int get hashCode =>
      Object.hash(lat, lng, speedKmh, accuracyMeters, timestamp);
}
