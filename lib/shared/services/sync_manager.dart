import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Drains the local trips table's `is_synced = false` rows up to the
/// remote sink, marking them synced on success.
///
/// Triggered three ways:
///  - At bootstrap (covers "trip saved offline, app re-opened online")
///  - Every time connectivity transitions to online ([NetworkInfo.onConnected])
///  - On demand via [syncNow] (e.g. after the user uploads from settings)
///
/// Failures are silent + retryable — the row stays `is_synced = false`
/// and we try again on the next online tick. The whole loop is mutex'd by
/// `_running` so two concurrent triggers don't double-upload the same row.
@singleton
class SyncManager {
  SyncManager(this._db, this._network, this._sink, this._telemetry);

  final AppDatabase _db;
  final NetworkInfo _network;
  final RemoteTripSink _sink;
  final TelemetryService _telemetry;

  StreamSubscription<void>? _onlineSub;
  bool _running = false;
  bool _started = false;

  /// Begin listening for connectivity transitions and kick off an initial
  /// drain. Idempotent — calling twice is a no-op.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _onlineSub = _network.onConnected.listen((_) => unawaited(syncNow()));
    if (await _network.isConnected) {
      unawaited(syncNow());
    }
  }

  Future<void> stop() async {
    _started = false;
    await _onlineSub?.cancel();
    _onlineSub = null;
  }

  /// One-shot drain. Returns the number of trips successfully synced.
  Future<int> syncNow() async {
    if (_running) return 0;
    _running = true;
    var uploaded = 0;
    try {
      final pending = await (_db.select(_db.trips)
            ..where((t) => t.isSynced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();
      if (pending.isEmpty) return 0;

      for (final trip in pending) {
        try {
          await _sink.uploadTrip(trip);
          await (_db.update(_db.trips)
                ..where((t) => t.id.equals(trip.id)))
              .write(const TripsCompanion(isSynced: Value(true)));
          uploaded += 1;
        } catch (e, st) {
          // Swallow per-trip failures so one bad trip doesn't block the
          // rest. The next tick will pick it up again.
          if (kDebugMode) {
            debugPrint('SyncManager: upload failed for trip ${trip.id}: $e');
          }
          await _telemetry.recordError(e, st);
          // Continue on to the next trip.
        }
      }
    } finally {
      _running = false;
    }
    return uploaded;
  }

  /// Resets every trip back to `is_synced = false`. Used by sign-in/sign-out
  /// flows so the new account fully syncs from a clean slate.
  Future<void> markAllUnsynced() async {
    await _db.update(_db.trips).write(
      const TripsCompanion(isSynced: Value(false)),
    );
  }
}
