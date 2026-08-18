import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TripRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Real GeocodingService is fine here — no platform channel is
    // registered in a unit test, so `placeName` hits its own
    // try/catch and resolves to null, exactly like an offline device.
    repo = TripRepository(db, GeocodingService());
  });

  tearDown(() async => db.close());

  LiveTripStats statsOf({
    double topSpeed = 100,
    double avgSpeed = 60,
    double distanceKm = 12.5,
    int durationSeconds = 750,
    double maxG = 0.8,
    List<TripPoint>? points,
  }) {
    return LiveTripStats(
      currentSpeedKmh: 0,
      maxSpeedKmh: topSpeed,
      avgSpeedKmh: avgSpeed,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      maxGforce: maxG,
      hardCornersCount: 0,
      hardBrakesCount: 0,
      lastPoint: points?.lastOrNull,
      points: points ?? <TripPoint>[],
    );
  }

  test('saves a trip with waypoints in one transaction', () async {
    final started = DateTime(2026, 5, 15, 14, 30);
    final ended = started.add(const Duration(minutes: 12, seconds: 30));
    final points = [
      TripPoint(
        lat: 31.5,
        lng: 74.3,
        speedKmh: 40,
        accuracyMeters: 5,
        timestamp: started,
      ),
      TripPoint(
        lat: 31.51,
        lng: 74.31,
        speedKmh: 80,
        accuracyMeters: 5,
        timestamp: started.add(const Duration(minutes: 5)),
      ),
    ];

    final id = await repo.saveTrip(
      uid: 'local',
      stats: statsOf(points: points),
      startedAt: started,
      endedAt: ended,
      mapTheme: 'gta',
      country: 'PK',
    );

    final row = await repo.getById(id);
    expect(row, isNotNull);
    expect(row!.topSpeedKmh, 100);
    expect(row.mapTheme, 'gta');
    expect(row.country, 'PK');

    final wps = await repo.getWaypoints(id);
    expect(wps.length, 2);
    expect(wps.first.lat, 31.5);
  });

  test('night-drive flag is true for trips starting at 22:00', () async {
    final id = await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 15, 22),
      endedAt: DateTime(2026, 5, 15, 22, 10),
      mapTheme: 'regular',
    );
    final row = await repo.getById(id);
    expect(row!.isNightDrive, isTrue);
  });

  test('night-drive flag is false for trips starting at noon', () async {
    final id = await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 15, 12),
      endedAt: DateTime(2026, 5, 15, 12, 10),
      mapTheme: 'regular',
    );
    final row = await repo.getById(id);
    expect(row!.isNightDrive, isFalse);
  });

  test('watchAll emits trips in start-desc order', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(topSpeed: 80),
      startedAt: DateTime(2026, 5, 10),
      endedAt: DateTime(2026, 5, 10, 1),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(topSpeed: 120),
      startedAt: DateTime(2026, 5, 15),
      endedAt: DateTime(2026, 5, 15, 1),
      mapTheme: 'regular',
    );
    final list = await repo.watchAll(uid: 'local').first;
    expect(list.first.topSpeedKmh, 120);
    expect(list.last.topSpeedKmh, 80);
  });

  test('deleteTrip cascades to waypoints', () async {
    final id = await repo.saveTrip(
      uid: 'local',
      stats: statsOf(
        points: [
          TripPoint(
            lat: 0,
            lng: 0,
            speedKmh: 10,
            accuracyMeters: 5,
            timestamp: DateTime(2026, 5, 15),
          ),
        ],
      ),
      startedAt: DateTime(2026, 5, 15),
      endedAt: DateTime(2026, 5, 15, 0, 5),
      mapTheme: 'regular',
    );
    expect((await repo.getWaypoints(id)).length, 1);
    await repo.deleteTrip(id);
    expect(await repo.getById(id), isNull);
    expect((await repo.getWaypoints(id)).length, 0);
  });

  test('getTripsInMonth filters by start date', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 4, 30, 23, 59),
      endedAt: DateTime(2026, 5),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 1),
      endedAt: DateTime(2026, 5, 1, 0, 30),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 31, 23, 59),
      endedAt: DateTime(2026, 6),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 6, 1),
      endedAt: DateTime(2026, 6, 1, 1),
      mapTheme: 'regular',
    );
    final may = await repo.getTripsInMonth(uid: 'local', year: 2026, month: 5);
    expect(may.length, 2);
  });

  test('getLongestTrip returns the trip with the greatest distance', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(distanceKm: 12),
      startedAt: DateTime(2026, 5, 10),
      endedAt: DateTime(2026, 5, 10, 1),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(distanceKm: 51.3),
      startedAt: DateTime(2026, 5, 12),
      endedAt: DateTime(2026, 5, 12, 1),
      mapTheme: 'regular',
    );
    final longest = await repo.getLongestTrip(uid: 'local');
    expect(longest!.distanceKm, 51.3);
  });

  test('getLongestTrip returns null when the user has no trips', () async {
    expect(await repo.getLongestTrip(uid: 'local'), isNull);
  });

  test('getLatestTrip returns the most recently started trip', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(topSpeed: 90),
      startedAt: DateTime(2026, 5, 1),
      endedAt: DateTime(2026, 5, 1, 1),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(topSpeed: 110),
      startedAt: DateTime(2026, 5, 20),
      endedAt: DateTime(2026, 5, 20, 1),
      mapTheme: 'regular',
    );
    final latest = await repo.getLatestTrip(uid: 'local');
    expect(latest!.topSpeedKmh, 110);
  });

  test('getTripsSince only returns trips on/after the given date', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 1),
      endedAt: DateTime(2026, 5, 1, 1),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: statsOf(),
      startedAt: DateTime(2026, 5, 10),
      endedAt: DateTime(2026, 5, 10, 1),
      mapTheme: 'regular',
    );
    final since = await repo.getTripsSince(
      uid: 'local',
      since: DateTime(2026, 5, 5),
    );
    expect(since.length, 1);
    expect(since.single.startedAt, DateTime(2026, 5, 10));
  });
}
