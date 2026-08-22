import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/services/car_photo_service.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Everything about cloud sync that isn't "push an unsynced trip" (that's
/// `SyncManager`/`FirestoreTripSink`) — pulling trip history and the
/// profile down on a new device, profile-photo upload/download, and cloud
/// data teardown for account deletion.
///
/// Lazily resolves `FirebaseFirestore.instance`/`FirebaseStorage.instance`
/// (same pattern as `FreeTripCounterService`) so constructing this never
/// touches Firebase before it's ready.
@lazySingleton
class CloudSyncService {
  CloudSyncService(this._trips, this._carPhoto);

  final TripRepository _trips;
  final CarPhotoService _carPhoto;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  static const int _tripRestoreLimit = 2000;

  // ---- Trips ----

  /// Pulls this account's trip history down into local Drift. Never
  /// overwrites or deletes an existing local trip — trips are
  /// immutable/append-only, so "present locally (by `remoteId`), add
  /// anything missing" is the entire merge policy. Returns the number of
  /// trip docs processed (restoreTrip itself is idempotent and skips any
  /// already present — good enough for "N trips restored" UI copy).
  Future<int> restoreTripsFromCloud({required String uid}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('trips')
          .orderBy('startedAt', descending: true)
          .limit(_tripRestoreLimit)
          .get();

      var restored = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final waypoints = await _decodeWaypoints(doc.reference, data);
        final trip = _decodeTripCompanion(uid, doc.id, data);
        await _trips.restoreTrip(
          remoteId: doc.id,
          trip: trip,
          waypoints: waypoints,
        );
        restored += 1;
      }
      if (kDebugMode) {
        debugPrint(
          '[CloudSyncService] restored $restored trip doc(s) for $uid',
        );
      }
      return restored;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudSyncService] restoreTripsFromCloud failed: $e');
      }
      return 0;
    }
  }

  Future<List<TripPoint>> _decodeWaypoints(
    DocumentReference<Map<String, dynamic>> tripRef,
    Map<String, dynamic> data,
  ) async {
    final chunkCount = (data['waypointChunkCount'] as num?)?.toInt() ?? 0;
    if (chunkCount == 0) {
      final raw = (data['waypoints'] as List?) ?? const [];
      return raw
          .map((e) => _decodeWaypoint(e as Map<String, dynamic>))
          .toList();
    }
    final points = <TripPoint>[];
    for (var i = 0; i < chunkCount; i++) {
      final chunkDoc = await tripRef
          .collection('waypointChunks')
          .doc(i.toString())
          .get();
      final raw = (chunkDoc.data()?['points'] as List?) ?? const [];
      points.addAll(
        raw.map((e) => _decodeWaypoint(e as Map<String, dynamic>)),
      );
    }
    return points;
  }

  static TripPoint _decodeWaypoint(Map<String, dynamic> m) => TripPoint(
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    speedKmh: (m['spd'] as num).toDouble(),
    accuracyMeters: (m['acc'] as num).toDouble(),
    altitudeMeters: (m['alt'] as num?)?.toDouble(),
    heading: (m['hdg'] as num?)?.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
  );

  TripsCompanion _decodeTripCompanion(
    String uid,
    String remoteId,
    Map<String, dynamic> d,
  ) {
    DateTime? ts(String key) => (d[key] as Timestamp?)?.toDate();
    return TripsCompanion.insert(
      uid: uid,
      remoteId: Value(remoteId),
      isSynced: const Value(true),
      topSpeedKmh: (d['topSpeedKmh'] as num?)?.toDouble() ?? 0,
      avgSpeedKmh: (d['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
      distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
      stoppedSeconds: Value((d['stoppedSeconds'] as num?)?.toInt() ?? 0),
      stopCount: Value((d['stopCount'] as num?)?.toInt() ?? 0),
      elevationGainMeters: Value(
        (d['elevationGainMeters'] as num?)?.toDouble(),
      ),
      maxElevationMeters: Value((d['maxElevationMeters'] as num?)?.toDouble()),
      maxGforce: Value((d['maxGforce'] as num?)?.toDouble() ?? 0),
      hardCornersCount: Value((d['hardCornersCount'] as num?)?.toInt() ?? 0),
      hardBrakesCount: Value((d['hardBrakesCount'] as num?)?.toInt() ?? 0),
      leftTurnCount: Value((d['leftTurnCount'] as num?)?.toInt() ?? 0),
      rightTurnCount: Value((d['rightTurnCount'] as num?)?.toInt() ?? 0),
      laneChangeCount: Value((d['laneChangeCount'] as num?)?.toInt() ?? 0),
      maxAccelerationMps2: Value(
        (d['maxAccelerationMps2'] as num?)?.toDouble() ?? 0,
      ),
      maxDecelerationMps2: Value(
        (d['maxDecelerationMps2'] as num?)?.toDouble() ?? 0,
      ),
      topCorneringSpeedKmh: Value(
        (d['topCorneringSpeedKmh'] as num?)?.toDouble() ?? 0,
      ),
      zeroToHundredSeconds: Value(
        (d['zeroToHundredSeconds'] as num?)?.toDouble(),
      ),
      fuelCostLocal: Value((d['fuelCostLocal'] as num?)?.toDouble()),
      localCurrencyCode: Value(d['localCurrencyCode'] as String?),
      weatherCondition: Value(d['weatherCondition'] as String?),
      weatherTempC: Value((d['weatherTempC'] as num?)?.toDouble()),
      isNightDrive: Value(d['isNightDrive'] as bool? ?? false),
      mapTheme: Value(d['mapTheme'] as String? ?? 'regular'),
      country: Value(d['country'] as String?),
      locationName: Value(d['locationName'] as String?),
      roadSegmentIds: Value((d['roadSegmentIds'] as List?)?.join(',') ?? ''),
      startedAt: ts('startedAt') ?? DateTime.now(),
      endedAt: Value(ts('endedAt')),
    );
  }

  // ---- Profile ----

  /// Null if this account has never synced a profile before (first-time
  /// account — the sign-in sequence pushes local instead of pulling).
  Future<PublicProfilePayload?> fetchRemoteProfile({
    required String uid,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return PublicProfilePayload.fromFirestore(uid, doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudSyncService] fetchRemoteProfile failed: $e');
      }
      return null;
    }
  }

  /// Downloads the profile photo at [url] into this app's local
  /// `car_photos/` documents directory (via `CarPhotoService`, the same
  /// place a locally-picked photo lives) and returns the local path, or
  /// null on any failure — the caller just leaves the local photo as-is
  /// then.
  Future<String?> downloadProfilePhoto(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(
        tempDir.path,
        'restored_car_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final file = File(tempPath);
      await ref.writeToFile(file);
      return _carPhoto.persist(tempPath);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudSyncService] downloadProfilePhoto failed: $e');
      }
      return null;
    }
  }

  /// Uploads the local car photo (this app's "profile picture" — see
  /// `CarSilhouette`) to `profile_photos/{uid}.jpg` and returns the
  /// download URL, or null if there's no local photo or the upload
  /// fails (the caller just omits `carPhotoUrl` from the profile push
  /// then — never a hard failure for the rest of the sync sequence).
  Future<String?> uploadProfilePhotoIfNeeded(
    String uid,
    String? localPath,
  ) async {
    if (localPath == null || localPath.isEmpty) return null;
    final file = File(localPath);
    if (!file.existsSync()) return null;
    try {
      final ref = _storage.ref('profile_photos/$uid.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudSyncService] uploadProfilePhoto failed: $e');
      }
      return null;
    }
  }

  // ---- Account deletion ----

  /// Best-effort cloud teardown for "Delete my account" — never throws,
  /// never blocks the local wipe that Play/Apple policy actually gates
  /// on. Firestore has no client-side "delete collection" primitive, so
  /// subcollections are enumerated and batch-deleted explicitly.
  Future<void> deleteRemoteData(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final trips = await userRef.collection('trips').get();
      for (final tripDoc in trips.docs) {
        final chunks = await tripDoc.reference
            .collection('waypointChunks')
            .get();
        final batch = _firestore.batch();
        for (final chunk in chunks.docs) {
          batch.delete(chunk.reference);
        }
        batch.delete(tripDoc.reference);
        await batch.commit();
      }
      await userRef.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudSyncService] deleteRemoteData (firestore) failed: $e');
      }
    }
    try {
      await _storage.ref('profile_photos/$uid.jpg').delete();
    } catch (e) {
      // Expected/harmless when there was never a photo — object-not-found.
      if (kDebugMode) {
        debugPrint('[CloudSyncService] deleteRemoteData (storage) skipped: $e');
      }
    }
  }
}
