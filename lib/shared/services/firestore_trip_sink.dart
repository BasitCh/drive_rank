import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:flutter/foundation.dart';

/// Production [RemoteTripSink] — writes trips to Firestore under
/// `users/{uid}/trips/{remoteId}`.
///
/// `remoteId` (a UUID, generated at save time — see `TripRepository`) is
/// used as the doc id rather than the local Drift autoincrement `trip.id`,
/// so two devices restoring/pushing under the same account can't collide
/// on the same path.
///
/// Waypoints are written as a compact array field on the trip doc when
/// they comfortably fit Firestore's 1 MiB document limit — the common
/// case, and just 1 write regardless of point count. For a rare
/// long/dense trip whose serialized waypoints exceed [_inlineByteLimit],
/// they're split into fixed-size chunks under a `waypointChunks`
/// subcollection instead, with `waypointChunkCount` on the parent doc
/// recording how many to read back (see `CloudSyncService.restoreTripsFromCloud`).
class FirestoreTripSink implements RemoteTripSink {
  FirestoreTripSink(this._firestore, this._trips);

  final FirebaseFirestore _firestore;
  final TripRepository _trips;

  /// Comfortable headroom under Firestore's 1 MiB/doc limit once the
  /// trip-summary fields are added alongside the waypoints array.
  static const int _inlineByteLimit = 700 * 1024;

  /// Waypoints per chunk when the inline path doesn't fit. Conservative:
  /// even at ~80 bytes/point (generous for the compact map shape below),
  /// 5000 points is well under the inline limit per chunk.
  static const int _chunkSize = 5000;

  @override
  Future<void> uploadTrip(TripRow trip) async {
    final remoteId = trip.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      // Shouldn't happen — TripRepository.saveTrip always sets one, and
      // SyncManager backfills legacy rows before calling this. Fail loud
      // (via rethrow below) rather than write to a path we can't dedupe.
      throw StateError('Trip ${trip.id} has no remoteId — cannot sync.');
    }
    final tripPath = 'users/${trip.uid}/trips/$remoteId';
    if (kDebugMode) {
      debugPrint(
        '[FirestoreTripSink] → $tripPath '
        '(${trip.topSpeedKmh.toStringAsFixed(0)} km/h top, '
        '${trip.distanceKm.toStringAsFixed(2)} km)',
      );
    }
    final tripRef = _firestore
        .collection('users')
        .doc(trip.uid)
        .collection('trips')
        .doc(remoteId);

    try {
      final waypoints = await _trips.getWaypoints(trip.id);
      final encoded = waypoints.map(_encodeWaypoint).toList();
      final inlineBytes = utf8.encode(jsonEncode(encoded)).length;
      final fitsInline = inlineBytes <= _inlineByteLimit;

      final payload = _tripPayload(trip);
      if (fitsInline) {
        payload['waypoints'] = encoded;
        payload['waypointChunkCount'] = 0;
        await tripRef.set(payload);
      } else {
        payload['waypointChunkCount'] = (encoded.length / _chunkSize).ceil();
        await tripRef.set(payload);
        for (var i = 0; i < encoded.length; i += _chunkSize) {
          final end = (i + _chunkSize).clamp(0, encoded.length);
          final chunkIndex = i ~/ _chunkSize;
          await tripRef
              .collection('waypointChunks')
              .doc(chunkIndex.toString())
              .set({'points': encoded.sublist(i, end)});
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[FirestoreTripSink] ✓ $tripPath (+${waypoints.length} waypoints, '
          '${fitsInline ? "inline" : "chunked"})',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirestoreTripSink] ✗ $tripPath failed: $e\n$st');
      }
      // Rethrow so SyncManager keeps the local `isSynced` flag false and
      // retries on the next connectivity-restore tick.
      rethrow;
    }
  }

  @override
  Future<void> deleteTrip({
    required String uid,
    required String remoteId,
  }) async {
    final tripPath = 'users/$uid/trips/$remoteId';
    final tripRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(remoteId);

    try {
      // Firestore does not cascade: deleting the parent leaves the
      // waypoint chunks as orphaned documents that still bill storage and
      // still come back if a doc is ever recreated at this path. Chunks
      // go first, so an interrupted delete leaves the trip doc — which is
      // what the tombstone retries on — rather than an unreachable tail
      // of waypoints nothing points at any more.
      final chunks = await tripRef.collection('waypointChunks').get();
      for (final chunk in chunks.docs) {
        await chunk.reference.delete();
      }
      await tripRef.delete();

      if (kDebugMode) {
        debugPrint(
          '[FirestoreTripSink] ✗ deleted $tripPath '
          '(+${chunks.docs.length} waypoint chunk(s))',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirestoreTripSink] delete $tripPath failed: $e\n$st');
      }
      // Rethrow so the tombstone survives and the next online tick tries
      // again. A doc that was already gone is not an error here —
      // Firestore's delete is idempotent and succeeds on a missing doc.
      rethrow;
    }
  }

  Map<String, dynamic> _tripPayload(TripRow trip) => {
    'topSpeedKmh': trip.topSpeedKmh,
    'avgSpeedKmh': trip.avgSpeedKmh,
    'distanceKm': trip.distanceKm,
    'durationSeconds': trip.durationSeconds,
    'stoppedSeconds': trip.stoppedSeconds,
    'stopCount': trip.stopCount,
    'elevationGainMeters': trip.elevationGainMeters,
    'maxElevationMeters': trip.maxElevationMeters,
    'maxGforce': trip.maxGforce,
    'hardCornersCount': trip.hardCornersCount,
    'hardBrakesCount': trip.hardBrakesCount,
    'leftTurnCount': trip.leftTurnCount,
    'rightTurnCount': trip.rightTurnCount,
    'laneChangeCount': trip.laneChangeCount,
    'maxAccelerationMps2': trip.maxAccelerationMps2,
    'maxDecelerationMps2': trip.maxDecelerationMps2,
    'topCorneringSpeedKmh': trip.topCorneringSpeedKmh,
    'zeroToHundredSeconds': trip.zeroToHundredSeconds,
    'fuelCostLocal': trip.fuelCostLocal,
    'localCurrencyCode': trip.localCurrencyCode,
    'weatherCondition': trip.weatherCondition,
    'weatherTempC': trip.weatherTempC,
    'isNightDrive': trip.isNightDrive,
    'mapTheme': trip.mapTheme,
    'country': trip.country,
    'locationName': trip.locationName,
    'roadSegmentIds': trip.roadSegmentIds.split(',')
      ..removeWhere((s) => s.isEmpty),
    'startedAt': Timestamp.fromDate(trip.startedAt),
    'endedAt': trip.endedAt == null ? null : Timestamp.fromDate(trip.endedAt!),
  };

  static Map<String, dynamic> _encodeWaypoint(TripPoint p) => {
    'lat': p.lat,
    'lng': p.lng,
    'spd': p.speedKmh,
    'acc': p.accuracyMeters,
    'alt': p.altitudeMeters,
    'hdg': p.heading,
    't': p.timestamp.millisecondsSinceEpoch,
  };
}
