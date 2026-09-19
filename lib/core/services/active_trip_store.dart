import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/database/tables/live_trips_table.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Frozen snapshot of an in-progress trip — what we hand back from
/// [ActiveTripStore.load]. Carries both bloc-private state
/// (`startedAt`, `status`) and the public stats so a fresh process can
/// resume without losing distance / duration / polyline.
@immutable
class ActiveTripSnapshot {
  const ActiveTripSnapshot({
    required this.id,
    required this.uid,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    required this.wasPaused,
    required this.interruptionCount,
    required this.stats,
  });

  final int id;
  final String uid;
  final TripStatusEnum status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final bool wasPaused;
  final int interruptionCount;
  final LiveTripStats stats;
}

/// Persists the in-progress trip across process kills via Drift.
///
/// Two tables: [LiveTrips] (single row, rolled-up summary) and
/// [LiveWaypoints] (append-only). The bloc calls [startTrip] once on
/// Start, [appendWaypoint] for every GPS point that lands on the
/// polyline, and [saveSummary] for every meaningful state change
/// (point, tick, g-force, pause/resume). All writes coalesce inside
/// Drift's transaction queue.
///
/// The previous implementation was a JSON file in app-docs — fine for
/// a prototype, but every save rewrote the entire polyline; a 3-hour
/// trip wrote a ~1.5 MB file every second. Drift gives us atomic
/// transactions and incremental appends — the right architecture for
/// what's effectively the user's trust signal.
@LazySingleton()
class ActiveTripStore {
  ActiveTripStore(this._db);

  final AppDatabase _db;

  /// Idempotent — if a live row already exists this is a no-op. Used
  /// by the bloc on `_onStartRequested` (after a `clear()`) and during
  /// crash recovery.
  Future<void> startTrip({
    required String uid,
    required DateTime startedAt,
  }) async {
    try {
      final existing = await (_db.select(
        _db.liveTrips,
      )..limit(1)).getSingleOrNull();
      if (existing != null) return;
      await _db
          .into(_db.liveTrips)
          .insert(
            LiveTripsCompanion.insert(
              uid: uid,
              startedAt: startedAt,
              updatedAt: DateTime.now(),
              status: const Value('active'),
            ),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] startTrip failed: $e');
    }
  }

  /// Upsert the rolled-up summary. Cheap — single UPDATE on a one-row
  /// table.
  Future<void> saveSummary(
    LiveTripStats stats, {
    bool wasPaused = false,
  }) async {
    try {
      final row = await (_db.select(_db.liveTrips)..limit(1)).getSingleOrNull();
      if (row == null) {
        return; // no active trip — bloc should have called startTrip first
      }
      await (_db.update(
        _db.liveTrips,
      )..where((t) => t.id.equals(row.id))).write(
        LiveTripsCompanion(
          distanceKm: Value(stats.distanceKm),
          topSpeedKmh: Value(stats.maxSpeedKmh),
          avgSpeedKmh: Value(stats.avgSpeedKmh),
          durationSeconds: Value(stats.durationSeconds),
          maxGforce: Value(stats.maxGforce),
          hardCornersCount: Value(stats.hardCornersCount),
          hardBrakesCount: Value(stats.hardBrakesCount),
          wasPaused: Value(wasPaused),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] saveSummary failed: $e');
    }
  }

  /// Append a single waypoint. Called on every GPS point that the bloc
  /// adds to the polyline.
  Future<void> appendWaypoint(TripPoint point) async {
    try {
      final row = await (_db.select(_db.liveTrips)..limit(1)).getSingleOrNull();
      if (row == null) return;
      await _db
          .into(_db.liveWaypoints)
          .insert(
            LiveWaypointsCompanion.insert(
              tripLocalId: row.id,
              lat: point.lat,
              lng: point.lng,
              speedKmh: point.speedKmh,
              accuracyMeters: point.accuracyMeters,
              timestamp: point.timestamp,
              // Carried through recovery so "mock GPS, then force-kill
              // the app" can't launder a spoofed trip past the social
              // eligibility check — that check runs on the in-memory
              // points, which are rebuilt from these rows after a crash.
              isMocked: Value(point.isMocked),
            ),
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveTripStore] appendWaypoint failed: $e');
      }
    }
  }

  /// Flip the status — used by the bloc's recovery flow to mark
  /// `interrupted` on cold start when last-updated is stale, and
  /// `recovered` when the user taps Resume.
  Future<void> setStatus(TripStatusEnum status) async {
    try {
      final row = await (_db.select(_db.liveTrips)..limit(1)).getSingleOrNull();
      if (row == null) return;
      await (_db.update(
        _db.liveTrips,
      )..where((t) => t.id.equals(row.id))).write(
        LiveTripsCompanion(
          status: Value(status.name),
          updatedAt: Value(DateTime.now()),
          interruptionCount: status == TripStatusEnum.interrupted
              ? Value(row.interruptionCount + 1)
              : const Value.absent(),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] setStatus failed: $e');
    }
  }

  /// Reads the in-progress trip back as a snapshot. Returns null if no
  /// trip is active (the normal idle-state case).
  Future<ActiveTripSnapshot?> load() async {
    try {
      final row = await (_db.select(_db.liveTrips)..limit(1)).getSingleOrNull();
      if (row == null) return null;
      final waypointRows =
          await (_db.select(_db.liveWaypoints)
                ..where((t) => t.tripLocalId.equals(row.id))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      final points = [
        for (final w in waypointRows)
          TripPoint(
            lat: w.lat,
            lng: w.lng,
            speedKmh: w.speedKmh,
            accuracyMeters: w.accuracyMeters,
            timestamp: w.timestamp,
            isMocked: w.isMocked,
          ),
      ];
      final stats = LiveTripStats(
        currentSpeedKmh: 0,
        maxSpeedKmh: row.topSpeedKmh,
        avgSpeedKmh: row.avgSpeedKmh,
        distanceKm: row.distanceKm,
        durationSeconds: row.durationSeconds,
        maxGforce: row.maxGforce,
        hardCornersCount: row.hardCornersCount,
        hardBrakesCount: row.hardBrakesCount,
        lastPoint: points.isEmpty ? null : points.last,
        points: points,
      );
      return ActiveTripSnapshot(
        id: row.id,
        uid: row.uid,
        status: _statusFromString(row.status),
        startedAt: row.startedAt,
        updatedAt: row.updatedAt,
        wasPaused: row.wasPaused,
        interruptionCount: row.interruptionCount,
        stats: stats,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] load failed: $e');
      return null;
    }
  }

  /// Deletes the live row and all of its waypoints in one transaction.
  /// Called after the trip is durably saved to `Trips` / `Waypoints`
  /// and after an explicit reset.
  Future<void> clear() async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.liveWaypoints).go();
        await _db.delete(_db.liveTrips).go();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] clear failed: $e');
    }
  }

  TripStatusEnum _statusFromString(String raw) {
    return TripStatusEnum.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TripStatusEnum.active,
    );
  }
}
