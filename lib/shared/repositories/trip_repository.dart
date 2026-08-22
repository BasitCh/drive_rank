import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/geocoding_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_insights/domain/usecases/zero_to_hundred.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Persistence layer for trips.
///
/// One save() per ended trip is enough for v1 — waypoints are written
/// alongside the parent row in a single transaction so a partially-saved
/// trip is impossible. Reads are reactive (Drift streams) so any UI that
/// watches trips updates the moment a new one lands.
///
/// All speeds/distances are written and read in **metric** (km, km/h).
/// The display layer converts via `LocaleService`.
@lazySingleton
class TripRepository {
  TripRepository(this._db, this._geocoding);

  final AppDatabase _db;
  final GeocodingService _geocoding;

  /// Persists a completed trip — the in-progress `LiveTripStats` snapshot
  /// from `TrackingBloc` — and returns the new trip's id.
  Future<int> saveTrip({
    required String uid,
    required LiveTripStats stats,
    required DateTime startedAt,
    required DateTime endedAt,
    required String mapTheme,
    String? country,
    double? fuelCostLocal,
    String? localCurrencyCode,
    String? weatherCondition,
    double? weatherTempC,
    List<String> roadSegmentIds = const <String>[],
  }) async {
    final isNight = _isNightDrive(startedAt);
    final (elevationGain, maxElevation) = _elevationStats(stats.points);
    // Best-effort, run before the transaction — reverse geocoding is a
    // platform call (can take seconds / fail offline) and has no
    // business holding a Drift transaction open.
    final locationName = stats.points.isEmpty
        ? null
        : await _geocoding.placeName(
            stats.points.first.lat,
            stats.points.first.lng,
          );
    return _db.transaction(() async {
      final tripId = await _db
          .into(_db.trips)
          .insert(
            TripsCompanion.insert(
              uid: uid,
              topSpeedKmh: stats.maxSpeedKmh,
              avgSpeedKmh: stats.avgSpeedKmh,
              distanceKm: stats.distanceKm,
              durationSeconds: stats.durationSeconds,
              stoppedSeconds: Value(stats.stoppedSeconds),
              stopCount: Value(stats.stopCount),
              elevationGainMeters: Value(elevationGain),
              maxElevationMeters: Value(maxElevation),
              maxGforce: Value(stats.maxGforce),
              hardCornersCount: Value(stats.hardCornersCount),
              hardBrakesCount: Value(stats.hardBrakesCount),
              leftTurnCount: Value(stats.leftTurnCount),
              rightTurnCount: Value(stats.rightTurnCount),
              laneChangeCount: Value(stats.laneChangeCount),
              maxAccelerationMps2: Value(stats.maxAccelerationMps2),
              maxDecelerationMps2: Value(stats.maxDecelerationMps2),
              topCorneringSpeedKmh: Value(stats.topCorneringSpeedKmh),
              zeroToHundredSeconds: Value(
                zeroToHundredSecondsFrom(stats.points),
              ),
              remoteId: Value(const Uuid().v4()),
              fuelCostLocal: Value(fuelCostLocal),
              localCurrencyCode: Value(localCurrencyCode),
              weatherCondition: Value(weatherCondition),
              weatherTempC: Value(weatherTempC),
              isNightDrive: Value(isNight),
              mapTheme: Value(mapTheme),
              country: Value(country),
              locationName: Value(locationName),
              roadSegmentIds: Value(roadSegmentIds.join(',')),
              startedAt: startedAt,
              endedAt: Value(endedAt),
            ),
          );
      if (stats.points.isNotEmpty) {
        await _db.batch((b) {
          b.insertAll(
            _db.waypoints,
            stats.points
                .map(
                  (p) => WaypointsCompanion.insert(
                    tripId: tripId,
                    lat: p.lat,
                    lng: p.lng,
                    speedKmh: p.speedKmh,
                    accuracyMeters: p.accuracyMeters,
                    altitudeMeters: Value(p.altitudeMeters),
                    heading: Value(p.heading),
                    timestamp: p.timestamp,
                  ),
                )
                .toList(),
          );
        });
      }
      return tripId;
    });
  }

  /// Inserts a trip restored from the cloud (see
  /// `CloudSyncService.restoreTripsFromCloud`) — a sibling to [saveTrip],
  /// not an overload: restore has different provenance (the trip already
  /// carries a `remoteId` and should start `isSynced = true` since it
  /// came *from* the cloud, and there's no local geocoding/elevation
  /// recomputation to do — the payload already has everything).
  ///
  /// Idempotent by `remoteId` — a trip already present locally (matched
  /// by `remoteId`, not the local autoincrement id, which won't agree
  /// across devices) is skipped rather than duplicated, so restore is
  /// safe to call more than once.
  Future<void> restoreTrip({
    required String remoteId,
    required TripsCompanion trip,
    required List<TripPoint> waypoints,
  }) async {
    final existing = await (_db.select(_db.trips)
          ..where((t) => t.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.transaction(() async {
      final tripId = await _db.into(_db.trips).insert(trip);
      if (waypoints.isNotEmpty) {
        await _db.batch((b) {
          b.insertAll(
            _db.waypoints,
            waypoints
                .map(
                  (p) => WaypointsCompanion.insert(
                    tripId: tripId,
                    lat: p.lat,
                    lng: p.lng,
                    speedKmh: p.speedKmh,
                    accuracyMeters: p.accuracyMeters,
                    altitudeMeters: Value(p.altitudeMeters),
                    heading: Value(p.heading),
                    timestamp: p.timestamp,
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }

  /// Elevation gain is the sum of positive altitude deltas between
  /// consecutive waypoints; max elevation is the highest single
  /// sample. Both null when the trip has no reliable altitude data —
  /// see `GpsService._reliableAltitude`.
  (double?, double?) _elevationStats(List<TripPoint> points) {
    final altitudes = [
      for (final p in points)
        if (p.altitudeMeters != null) p.altitudeMeters!,
    ];
    if (altitudes.isEmpty) return (null, null);
    var gain = 0.0;
    for (var i = 1; i < altitudes.length; i++) {
      final delta = altitudes[i] - altitudes[i - 1];
      if (delta > 0) gain += delta;
    }
    final maxElevation = altitudes.reduce((a, b) => a > b ? a : b);
    return (gain, maxElevation);
  }

  /// Lifetime count of this user's saved trips. Used right after
  /// `saveTrip` to detect the 1st/2nd-trip retention milestones — the
  /// paywall's `freeTripsUsed` counter isn't a substitute here since
  /// it's freemium-gate state, not a lifetime trip count (it can reset
  /// independently of how many trips the user has actually driven).
  Future<int> countAll({required String uid}) async {
    final countExp = _db.trips.id.count();
    final query = _db.selectOnly(_db.trips)
      ..addColumns([countExp])
      ..where(_db.trips.uid.equals(uid));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Stream<List<TripRow>> watchAll({required String uid}) {
    return (_db.select(_db.trips)
          ..where((t) => t.uid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Stream<TripRow?> watchById(int id) {
    return (_db.select(_db.trips)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<TripRow?> getById(int id) {
    return (_db.select(_db.trips)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<TripPoint>> getWaypoints(int tripId) async {
    final rows =
        await (_db.select(_db.waypoints)
              ..where((w) => w.tripId.equals(tripId))
              ..orderBy([(w) => OrderingTerm.asc(w.timestamp)]))
            .get();
    return rows
        .map(
          (r) => TripPoint(
            lat: r.lat,
            lng: r.lng,
            speedKmh: r.speedKmh,
            accuracyMeters: r.accuracyMeters,
            altitudeMeters: r.altitudeMeters,
            heading: r.heading,
            timestamp: r.timestamp,
          ),
        )
        .toList();
  }

  Future<int> deleteTrip(int id) {
    return (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes every trip owned by [uid] — waypoints cascade via the FK.
  /// Used by account deletion; not exposed anywhere else.
  Future<int> deleteAllForUid(String uid) {
    return (_db.delete(_db.trips)..where((t) => t.uid.equals(uid))).go();
  }

  /// All trips in a given calendar month (inclusive of start, exclusive of
  /// the next month's start). Used by the monthly report.
  Future<List<TripRow>> getTripsInMonth({
    required String uid,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (_db.select(_db.trips)
          ..where(
            (t) =>
                t.uid.equals(uid) &
                t.startedAt.isBiggerOrEqualValue(start) &
                t.startedAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Returns the user's personal-best top-speed trip, or null if none.
  Future<TripRow?> getPersonalBest({required String uid}) {
    return (_db.select(_db.trips)
          ..where((t) => t.uid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.topSpeedKmh)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// The user's most recently started trip, or null if none. The anchor
  /// the retention scheduler reschedules the "haven't driven in 7 days"
  /// nudge from.
  Future<TripRow?> getLatestTrip({required String uid}) {
    return (_db.select(_db.trips)
          ..where((t) => t.uid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Returns the user's single longest trip by distance, or null if none.
  /// The distance-goal baseline — mirrors [getPersonalBest]'s shape.
  Future<TripRow?> getLongestTrip({required String uid}) {
    return (_db.select(_db.trips)
          ..where((t) => t.uid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.distanceKm)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Trips started at or after [since], most recent first. Used by the
  /// weekly-recap notification to aggregate "this week's" stats — a
  /// rolling window anchored to whenever the recap fires, not a
  /// calendar week, so it works the same regardless of which day the
  /// recap is scheduled for.
  Future<List<TripRow>> getTripsSince({
    required String uid,
    required DateTime since,
  }) {
    return (_db.select(_db.trips)
          ..where(
            (t) => t.uid.equals(uid) & t.startedAt.isBiggerOrEqualValue(since),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Trip starts at 9 PM – 5 AM local time → night drive. Used for the
  /// "Night Drives" history filter and the moon emoji on the stat card.
  static bool _isNightDrive(DateTime startedAt) {
    final h = startedAt.hour;
    return h >= 21 || h < 5;
  }
}
