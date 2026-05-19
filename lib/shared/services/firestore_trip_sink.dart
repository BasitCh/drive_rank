import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:flutter/foundation.dart';

/// Production [RemoteTripSink] — writes trips and their waypoints to
/// Firestore under `users/{uid}/trips/{tripId}` with the waypoints in a
/// subcollection so the trip doc stays small.
///
/// Idempotent on retry: the `tripId` is the local Drift id (`set` not
/// `add`), so a retried upload after a partial network failure overwrites
/// the same doc rather than creating a duplicate.
class FirestoreTripSink implements RemoteTripSink {
  FirestoreTripSink(this._firestore, this._trips);

  final FirebaseFirestore _firestore;
  final TripRepository _trips;

  @override
  Future<void> uploadTrip(TripRow trip) async {
    final tripPath = 'users/${trip.uid}/trips/${trip.id}';
    if (kDebugMode) {
      debugPrint(
        '[FirestoreTripSink] → $tripPath '
        '(${trip.topSpeedKmh.toStringAsFixed(0)} km/h top, '
        '${trip.distanceKm.toStringAsFixed(2)} km)',
      );
    }
    final userRef = _firestore.collection('users').doc(trip.uid);
    final tripRef = userRef.collection('trips').doc(trip.id.toString());

    try {
      final waypoints = await _trips.getWaypoints(trip.id);

      await tripRef.set({
        'topSpeedKmh': trip.topSpeedKmh,
        'avgSpeedKmh': trip.avgSpeedKmh,
        'distanceKm': trip.distanceKm,
        'durationSeconds': trip.durationSeconds,
        'stoppedSeconds': trip.stoppedSeconds,
        'maxGforce': trip.maxGforce,
        'hardCornersCount': trip.hardCornersCount,
        'hardBrakesCount': trip.hardBrakesCount,
        'fuelCostLocal': trip.fuelCostLocal,
        'localCurrencyCode': trip.localCurrencyCode,
        'weatherCondition': trip.weatherCondition,
        'weatherTempC': trip.weatherTempC,
        'isNightDrive': trip.isNightDrive,
        'mapTheme': trip.mapTheme,
        'country': trip.country,
        'roadSegmentIds': trip.roadSegmentIds.split(',')
          ..removeWhere((s) => s.isEmpty),
        'startedAt': Timestamp.fromDate(trip.startedAt),
        'endedAt': trip.endedAt == null
            ? null
            : Timestamp.fromDate(trip.endedAt!),
      });

      // Waypoints in batches of 400 (Firestore's per-batch limit is 500;
      // we leave 100 spare for future schema additions).
      if (waypoints.isNotEmpty) {
        for (var i = 0; i < waypoints.length; i += 400) {
          final batch = _firestore.batch();
          final end = (i + 400).clamp(0, waypoints.length);
          final slice = waypoints.sublist(i, end);
          for (var j = 0; j < slice.length; j++) {
            final p = slice[j];
            final ref = tripRef
                .collection('waypoints')
                .doc((i + j).toString());
            batch.set(ref, {
              'lat': p.lat,
              'lng': p.lng,
              'speedKmh': p.speedKmh,
              'accuracyMeters': p.accuracyMeters,
              'timestamp': Timestamp.fromDate(p.timestamp),
            });
          }
          await batch.commit();
        }
      }
      if (kDebugMode) {
        debugPrint(
          '[FirestoreTripSink] ✓ $tripPath (+${waypoints.length} waypoints)',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirestoreTripSink] ✗ $tripPath failed: $e\n$st');
      }
      // Rethrow so SyncManager keeps the local `isSynced` flag false
      // and retries on the next connectivity-restore tick.
      rethrow;
    }
  }
}
