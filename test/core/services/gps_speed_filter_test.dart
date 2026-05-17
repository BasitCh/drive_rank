import 'package:drive_rank/core/services/gps_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Drives the GpsService.debugInject() seam to verify the Issue-7 noise
/// filter without booting platform channels.
///
/// Three things we care about:
///   1. Stationary drift (<3 km/h or accuracy >20m) is clamped to 0.
///   2. A speed delta bigger than 50 km/h between consecutive valid
///      samples is rejected and the previous reading is kept.
///   3. Normal driving samples pass straight through.
void main() {
  late GpsService gps;
  late List<TripPoint> received;

  setUp(() async {
    gps = GpsService();
    received = <TripPoint>[];
    // start() needs platform GPS — we skip it and directly drive
    // debugInject(), which exercises the same _onPosition path.
    gps.points.listen(received.add);
  });

  tearDown(() async {
    await gps.dispose();
  });

  Position make({
    required double speedMps,
    required double accuracy,
    DateTime? at,
  }) {
    return Position(
      latitude: 33.6844,
      longitude: 73.0479,
      timestamp: at ?? DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speedMps,
      speedAccuracy: 0,
    );
  }

  test('stationary drift below 3 km/h is clamped to zero', () async {
    // 2 km/h ≈ 0.555 m/s.
    gps.debugInject(make(speedMps: 0.555, accuracy: 5));
    await Future<void>.delayed(Duration.zero);
    expect(received.single.speedKmh, 0);
  });

  test('low accuracy (>20m) is clamped to zero regardless of speed',
      () async {
    // 60 km/h raw but the fix is junk.
    gps.debugInject(make(speedMps: 16.67, accuracy: 35));
    await Future<void>.delayed(Duration.zero);
    expect(received.single.speedKmh, 0);
  });

  test('normal driving sample passes through unchanged', () async {
    gps.debugInject(make(speedMps: 16.67, accuracy: 5)); // 60 km/h
    await Future<void>.delayed(Duration.zero);
    expect(received.single.speedKmh, closeTo(60, 0.5));
  });

  test('spike >50 km/h above previous sample is rejected', () async {
    gps.debugInject(make(speedMps: 16.67, accuracy: 5)); // 60 km/h
    await Future<void>.delayed(Duration.zero);
    final stableTime = DateTime.now();
    gps.debugInject(make(speedMps: 50, accuracy: 5, at: stableTime)); // 180 km/h
    await Future<void>.delayed(Duration.zero);
    expect(received.length, 2);
    // Second emission should hold the previous speed, not the spike.
    expect(received.last.speedKmh, closeTo(60, 0.5));
  });

  test('big *deceleration* spike is also rejected', () async {
    gps.debugInject(make(speedMps: 27.8, accuracy: 5)); // 100 km/h
    await Future<void>.delayed(Duration.zero);
    gps.debugInject(make(speedMps: 8, accuracy: 5)); // 28.8 km/h — diff>50
    await Future<void>.delayed(Duration.zero);
    expect(received.last.speedKmh, closeTo(100, 0.5));
  });

  test('NaN speed is treated as zero (not propagated)', () async {
    gps.debugInject(make(speedMps: double.nan, accuracy: 5));
    await Future<void>.delayed(Duration.zero);
    expect(received.single.speedKmh, 0);
  });
}
