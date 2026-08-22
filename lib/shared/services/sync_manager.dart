import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

enum SyncPhase { idle, syncing, error }

/// Observable sync state — see `SyncManager.statusStream`. Scoped to
/// whichever account is currently signed in; `resetForAccountChange()`
/// clears it so one account's status never bleeds into another's.
@immutable
class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  static const initial = SyncStatus(phase: SyncPhase.idle);

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// Drains the local trips table's `is_synced = false` rows (scoped to the
/// *currently signed-in* uid — see the account-switching note below) up to
/// the remote sink, marking them synced on success.
///
/// Triggered:
///  - At bootstrap (covers "trip saved offline, app re-opened online")
///  - Every time connectivity transitions to online ([NetworkInfo.onConnected])
///  - Right after a trip finishes saving (`TrackingBloc`, fire-and-forget)
///  - On demand via [syncNow] (e.g. sign-in, or a "tap to retry" row)
///
/// Failures are silent + retryable — the row stays `is_synced = false`
/// and we try again on the next online tick. The whole loop is mutex'd by
/// `_running` so two concurrent triggers don't double-upload the same row.
///
/// The drain query filters by the current auth uid, not just
/// `is_synced = false` globally. Without that, a different account's
/// left-behind local trips (see `UserSettingsRepository.reassignUidOnly` —
/// a previous account's data is never deleted or migrated on an account
/// switch, only unmatched by the active uid filter) could be discovered by
/// a later sync pass and pushed under the *new* account's identity.
/// Firestore rules reject that specific write (the trip's `uid` field
/// won't match the authenticated uid in the doc path), so it's not a data
/// leak either way — but scoping the query correctly avoids endlessly
/// retried, doomed writes cluttering logs for data that was never this
/// account's to sync.
@singleton
class SyncManager {
  SyncManager(this._db, this._network, this._telemetry);

  final AppDatabase _db;
  final NetworkInfo _network;
  final TelemetryService _telemetry;

  /// Both resolved lazily via `getIt` rather than taken as constructor
  /// dependencies, on purpose: `SyncManager` is `@singleton` (eagerly
  /// constructed during `configureDependencies()`, long before
  /// `_maybeInitFirebase()` swaps in the real `FirestoreTripSink` /
  /// `FirebaseAuthService` for their no-op/anonymous defaults) — a hard
  /// constructor reference would have permanently captured the
  /// pre-Firebase default. Confirmed the hard way: an early version of
  /// this class took `AuthService` as a constructor param, and every
  /// synced trip landed at `users/local/trips/...` instead of the real
  /// Firebase uid, because it never saw the post-bootstrap swap. Same
  /// fix already applied to `PublicProfileService`.
  RemoteTripSink get _sink => getIt<RemoteTripSink>();
  AuthService get _auth => getIt<AuthService>();

  StreamSubscription<void>? _onlineSub;
  bool _running = false;
  bool _started = false;

  SyncStatus _status = SyncStatus.initial;
  final _statusController = StreamController<SyncStatus>.broadcast();

  SyncStatus get current => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void _emit(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Clears sync status back to a fresh idle state — call at the start of
  /// a sign-in sequence and right after sign-out, so one account's status
  /// never appears while a different account is (or is about to be)
  /// active.
  void resetForAccountChange() {
    _emit(SyncStatus.initial);
  }

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
    final uid = _auth.currentUser.uid;
    var uploaded = 0;
    try {
      final pending = await (_db.select(_db.trips)
            ..where((t) => t.isSynced.equals(false) & t.uid.equals(uid))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();
      if (pending.isEmpty) {
        _emit(_status.copyWith(phase: SyncPhase.idle, pendingCount: 0));
        return 0;
      }

      _emit(
        SyncStatus(phase: SyncPhase.syncing, pendingCount: pending.length),
      );

      for (var i = 0; i < pending.length; i++) {
        var trip = pending[i];
        try {
          // Legacy rows saved before the remote-id column existed don't
          // have one yet — backfill lazily, once, persisted immediately
          // so it's stable thereafter (new trips always get one at save
          // time — see TripRepository.saveTrip).
          if (trip.remoteId == null || trip.remoteId!.isEmpty) {
            final newRemoteId = const Uuid().v4();
            await (_db.update(_db.trips)..where((t) => t.id.equals(trip.id)))
                .write(TripsCompanion(remoteId: Value(newRemoteId)));
            trip = trip.copyWith(remoteId: Value(newRemoteId));
          }
          await _sink.uploadTrip(trip);
          await (_db.update(_db.trips)..where((t) => t.id.equals(trip.id)))
              .write(const TripsCompanion(isSynced: Value(true)));
          uploaded += 1;
          _emit(
            _status.copyWith(pendingCount: pending.length - (i + 1)),
          );
        } catch (e, st) {
          // Swallow per-trip failures so one bad trip doesn't block the
          // rest. The next tick will pick it up again.
          if (kDebugMode) {
            debugPrint('SyncManager: upload failed for trip ${trip.id}: $e');
          }
          await _telemetry.recordError(e, st);
          _emit(_status.copyWith(phase: SyncPhase.error, lastError: '$e'));
        }
      }

      if (_status.phase != SyncPhase.error) {
        _emit(
          SyncStatus(
            phase: SyncPhase.idle,
            pendingCount: 0,
            lastSyncedAt: DateTime.now(),
          ),
        );
      }
    } finally {
      _running = false;
    }
    return uploaded;
  }

  /// Resets every trip owned by the current uid back to `is_synced = false`.
  /// Used at sign-in so the newly-linked account fully (re)syncs from a
  /// clean slate.
  Future<void> markAllUnsynced() async {
    final uid = _auth.currentUser.uid;
    await (_db.update(_db.trips)..where((t) => t.uid.equals(uid))).write(
      const TripsCompanion(isSynced: Value(false)),
    );
  }
}
