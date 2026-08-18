import 'package:drift/native.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/trip_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TripRepository repo;
  late TripStatsService stats;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TripRepository(db, GeocodingService());
    stats = TripStatsService(repo);
  });

  tearDown(() async => db.close());

  LiveTripStats build({
    double topSpeed = 100,
    double distanceKm = 10,
    int durationSeconds = 600,
    double maxG = 0.5,
  }) => LiveTripStats(
    currentSpeedKmh: 0,
    maxSpeedKmh: topSpeed,
    avgSpeedKmh: 50,
    distanceKm: distanceKm,
    durationSeconds: durationSeconds,
    maxGforce: maxG,
    hardCornersCount: 0,
    hardBrakesCount: 0,
    lastPoint: null,
    points: const <TripPoint>[],
  );

  test('monthlyReport returns empty when there are no trips', () async {
    final report = await stats.monthlyReport(
      uid: 'local',
      year: 2026,
      month: 5,
    );
    expect(report.isEmpty, isTrue);
    expect(report.tripCount, 0);
  });

  test('monthlyReport aggregates distance, top speed and best g', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: build(topSpeed: 100, distanceKm: 10, maxG: 0.6),
      startedAt: DateTime(2026, 5, 5, 9),
      endedAt: DateTime(2026, 5, 5, 9, 30),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: build(topSpeed: 140, distanceKm: 25, maxG: 0.9),
      startedAt: DateTime(2026, 5, 12, 18),
      endedAt: DateTime(2026, 5, 12, 19),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: build(topSpeed: 70, distanceKm: 8, maxG: 0.3),
      startedAt: DateTime(2026, 5, 12, 21),
      endedAt: DateTime(2026, 5, 12, 22),
      mapTheme: 'regular',
    );

    final report = await stats.monthlyReport(
      uid: 'local',
      year: 2026,
      month: 5,
    );
    expect(report.tripCount, 3);
    expect(report.totalDistanceKm, 43);
    expect(report.topSpeedKmh, 140);
    expect(report.bestGforce, 0.9);
    // Two trips happened on 2026-05-12, which is a Tuesday (weekday=2).
    expect(report.mostActiveWeekday, 2);
  });

  test('lifetime sums across all trips', () async {
    await repo.saveTrip(
      uid: 'local',
      stats: build(topSpeed: 80, distanceKm: 5),
      startedAt: DateTime(2026, 4, 10),
      endedAt: DateTime(2026, 4, 10, 0, 30),
      mapTheme: 'regular',
    );
    await repo.saveTrip(
      uid: 'local',
      stats: build(topSpeed: 150, distanceKm: 30),
      startedAt: DateTime(2026, 5, 1),
      endedAt: DateTime(2026, 5, 1, 1),
      mapTheme: 'regular',
    );

    final lifetime = await stats.lifetime(uid: 'local');
    expect(lifetime.tripCount, 2);
    expect(lifetime.totalDistanceKm, 35);
    expect(lifetime.topSpeedKmh, 150);
  });
}
