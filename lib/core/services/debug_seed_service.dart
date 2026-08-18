import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsCompanion;
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Debug-only test-data generator. Inserts a handful of realistic mock
/// trips (varied months, speeds, altitude profiles, and stops) through
/// the exact same `TripRepository.saveTrip` path a real drive uses —
/// so elevation gain/max, reverse-geocoded location, and every other
/// save-time computation are exercised for real, not faked separately.
///
/// Also flips the local account to Pro so the free-trial paywall
/// doesn't block browsing the seeded history.
///
/// Safety: every entry point checks `kDebugMode` and no-ops otherwise.
/// The only call site is a `kDebugMode`-gated button in Settings — this
/// class is never reachable from a release build regardless.
@lazySingleton
class DebugSeedService {
  DebugSeedService(this._trips, this._settings);

  final TripRepository _trips;
  final UserSettingsRepository _settings;

  static const double _metresPerDegLat = 111320;

  /// Seeds ~7 mock trips across the last 6 months and sets the local
  /// account to Pro. Returns the number of trips inserted (0 outside
  /// debug mode).
  Future<int> seedMockTrips() async {
    if (!kDebugMode) return 0;
    final settings = await _settings.read();
    await _settings.patch(const UserSettingsCompanion(isPro: Value(true)));

    final now = DateTime.now();
    var inserted = 0;
    for (final blueprint in _blueprints(now)) {
      final stats = _buildStats(blueprint);
      await _trips.saveTrip(
        uid: settings.uid,
        stats: stats,
        startedAt: blueprint.startedAt,
        endedAt: blueprint.startedAt.add(
          Duration(seconds: stats.durationSeconds),
        ),
        mapTheme: settings.selectedMapTheme,
        country: settings.country,
      );
      inserted++;
    }
    return inserted;
  }

  /// Undoes [seedMockTrips]'s paywall bypass — does not touch trips
  /// (delete those individually from History, same as any real trip).
  Future<void> resetToFreeTier() async {
    if (!kDebugMode) return;
    await _settings.patch(
      const UserSettingsCompanion(
        isPro: Value(false),
        freeTripsUsed: Value(0),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Blueprints — one per mock trip. Each leg is (speedKmh, seconds);
  // speedKmh == 0 is a stop (no waypoints emitted, matching how
  // TrackingBloc never persists stationary samples).
  // ---------------------------------------------------------------------

  List<_TripBlueprint> _blueprints(DateTime now) {
    DateTime monthsAgo(int n, int day, int hour) {
      final d = DateTime(now.year, now.month - n, day, hour);
      return d;
    }

    return [
      _TripBlueprint(
        label: 'Highway cruise',
        startedAt: monthsAgo(0, 3, 18),
        startLat: 29.4000,
        startLng: 71.6800,
        headingDeg: 40,
        altitudeStart: 110,
        altitudeEnd: 118,
        legs: const [
          _Leg(0, 20),
          _Leg(35, 60),
          _Leg(80, 240),
          _Leg(110, 180),
          _Leg(60, 90),
          _Leg(0, 45),
          _Leg(70, 200),
          _Leg(20, 40),
        ],
        maxGforce: 0.6,
        hardCorners: 3,
        hardBrakes: 2,
      ),
      _TripBlueprint(
        label: 'City errands',
        startedAt: monthsAgo(0, 12, 10),
        startLat: 29.3950,
        startLng: 71.6750,
        headingDeg: 150,
        altitudeStart: 112,
        altitudeEnd: 112,
        legs: const [
          _Leg(25, 40),
          _Leg(0, 35),
          _Leg(30, 60),
          _Leg(0, 50),
          _Leg(40, 80),
          _Leg(15, 30),
        ],
        maxGforce: 0.3,
        hardCorners: 1,
        hardBrakes: 3,
      ),
      _TripBlueprint(
        label: 'Mountain pass',
        startedAt: monthsAgo(1, 8, 9),
        startLat: 34.1500,
        startLng: 73.2200,
        headingDeg: 300,
        altitudeStart: 900,
        altitudeEnd: 1450,
        legs: const [
          _Leg(0, 30),
          _Leg(30, 120),
          _Leg(45, 300),
          _Leg(0, 60),
          _Leg(55, 240),
          _Leg(35, 150),
          _Leg(0, 40),
          _Leg(25, 90),
        ],
        maxGforce: 0.75,
        hardCorners: 8,
        hardBrakes: 5,
      ),
      _TripBlueprint(
        label: 'Coastal drive',
        startedAt: monthsAgo(2, 20, 16),
        startLat: 24.8500,
        startLng: 67.0300,
        headingDeg: 210,
        altitudeStart: 8,
        altitudeEnd: 5,
        legs: const [
          _Leg(0, 15),
          _Leg(60, 180),
          _Leg(130, 300),
          _Leg(90, 200),
          _Leg(0, 90),
          _Leg(100, 260),
          _Leg(40, 60),
        ],
        maxGforce: 0.55,
        hardCorners: 4,
        hardBrakes: 2,
      ),
      _TripBlueprint(
        label: 'Cross town',
        startedAt: monthsAgo(3, 5, 14),
        startLat: 31.5200,
        startLng: 74.3500,
        headingDeg: 95,
        altitudeStart: 214,
        altitudeEnd: 220,
        legs: const [
          _Leg(20, 50),
          _Leg(45, 150),
          _Leg(0, 45),
          _Leg(35, 100),
          _Leg(55, 130),
        ],
        maxGforce: 0.4,
        hardCorners: 2,
        hardBrakes: 2,
      ),
      _TripBlueprint(
        label: 'Weekend backroads',
        startedAt: monthsAgo(4, 14, 11),
        startLat: 33.7300,
        startLng: 73.0900,
        headingDeg: 260,
        altitudeStart: 500,
        altitudeEnd: 640,
        legs: const [
          _Leg(0, 25),
          _Leg(40, 140),
          _Leg(65, 220),
          _Leg(0, 50),
          _Leg(50, 160),
          _Leg(30, 70),
        ],
        maxGforce: 0.5,
        hardCorners: 5,
        hardBrakes: 3,
      ),
      _TripBlueprint(
        label: 'First drive on record',
        startedAt: monthsAgo(5, 2, 8),
        startLat: 29.3900,
        startLng: 71.6900,
        headingDeg: 10,
        altitudeStart: 108,
        altitudeEnd: 110,
        legs: const [
          _Leg(0, 20),
          _Leg(30, 100),
          _Leg(50, 180),
          _Leg(25, 60),
        ],
        maxGforce: 0.35,
        hardCorners: 1,
        hardBrakes: 1,
      ),
      // Edge case, deliberately tiny and altitude-free — verifies the
      // Elevation chart / route replay hide gracefully instead of
      // rendering broken for a short trip.
      _TripBlueprint(
        label: 'Quick move (edge case)',
        startedAt: monthsAgo(0, 16, 9),
        startLat: 29.4050,
        startLng: 71.6850,
        headingDeg: 180,
        altitudeStart: null,
        altitudeEnd: null,
        legs: const [_Leg(20, 15), _Leg(10, 10)],
        maxGforce: 0.15,
        hardCorners: 0,
        hardBrakes: 0,
      ),
    ];
  }

  LiveTripStats _buildStats(_TripBlueprint bp) {
    final rand = math.Random(bp.label.hashCode);
    final points = <TripPoint>[];

    var lat = bp.startLat;
    var lng = bp.startLng;
    var heading = bp.headingDeg;
    var elapsedSeconds = 0;
    var distanceKm = 0.0;
    var maxSpeedKmh = 0.0;
    var stoppedSeconds = 0;
    var stopCount = 0;
    var t = bp.startedAt;

    final totalDistanceSeconds = bp.legs.fold<int>(0, (s, l) => s + l.seconds);
    var progressedSeconds = 0;

    for (final leg in bp.legs) {
      if (leg.speedKmh == 0) {
        elapsedSeconds += leg.seconds;
        t = t.add(Duration(seconds: leg.seconds));
        stoppedSeconds += leg.seconds;
        if (leg.seconds >= 30) stopCount++;
        progressedSeconds += leg.seconds;
        continue;
      }
      final metresPerSecond = leg.speedKmh / 3.6;
      for (var s = 0; s < leg.seconds; s++) {
        heading += rand.nextDouble() * 6 - 3; // gentle wander
        final metresThisSample = metresPerSecond;
        final rad = heading * math.pi / 180;
        final dLat = (metresThisSample * math.cos(rad)) / _metresPerDegLat;
        final dLng =
            (metresThisSample * math.sin(rad)) /
            (_metresPerDegLat * math.cos(lat * math.pi / 180));
        lat += dLat;
        lng += dLng;
        elapsedSeconds += 1;
        t = t.add(const Duration(seconds: 1));
        distanceKm += metresThisSample / 1000.0;
        final speedJittered = leg.speedKmh + (rand.nextDouble() * 4 - 2);
        if (speedJittered > maxSpeedKmh) maxSpeedKmh = speedJittered;

        double? altitude;
        if (bp.altitudeStart != null && bp.altitudeEnd != null) {
          progressedSeconds += 1;
          final frac = totalDistanceSeconds == 0
              ? 0.0
              : progressedSeconds / totalDistanceSeconds;
          final base =
              bp.altitudeStart! + (bp.altitudeEnd! - bp.altitudeStart!) * frac;
          altitude = base + math.sin(progressedSeconds / 40) * 3;
        }

        points.add(
          TripPoint(
            lat: lat,
            lng: lng,
            speedKmh: speedJittered.clamp(1, 300),
            accuracyMeters: 6 + rand.nextDouble() * 4,
            altitudeMeters: altitude,
            timestamp: t,
          ),
        );
      }
    }

    final avgSpeedKmh = elapsedSeconds == 0
        ? 0.0
        : distanceKm / (elapsedSeconds / 3600);

    return LiveTripStats(
      currentSpeedKmh: 0,
      maxSpeedKmh: maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh,
      distanceKm: distanceKm,
      durationSeconds: elapsedSeconds,
      maxGforce: bp.maxGforce,
      hardCornersCount: bp.hardCorners,
      hardBrakesCount: bp.hardBrakes,
      lastPoint: points.isEmpty ? null : points.last,
      points: points,
      stoppedSeconds: stoppedSeconds,
      stopCount: stopCount,
    );
  }
}

class _TripBlueprint {
  const _TripBlueprint({
    required this.label,
    required this.startedAt,
    required this.startLat,
    required this.startLng,
    required this.headingDeg,
    required this.altitudeStart,
    required this.altitudeEnd,
    required this.legs,
    required this.maxGforce,
    required this.hardCorners,
    required this.hardBrakes,
  });

  final String label;
  final DateTime startedAt;
  final double startLat;
  final double startLng;
  final double headingDeg;
  final double? altitudeStart;
  final double? altitudeEnd;
  final List<_Leg> legs;
  final double maxGforce;
  final int hardCorners;
  final int hardBrakes;
}

class _Leg {
  const _Leg(this.speedKmh, this.seconds);
  final double speedKmh;
  final int seconds;
}
