import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/core/services/device_identity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Persists the free-trip counter to Firestore, keyed by hashed device
/// ID. This is what stops the "uninstall and reinstall to refresh free
/// trips" workaround: on a clean install we still see the same
/// `device_trials/{hashedId}` doc and read its counter.
///
/// Behaviour:
/// - `pullRemoteUsed()` reads the cloud value (best-effort).
/// - `incrementRemote()` bumps the cloud counter by 1.
/// - Every method silently no-ops on failure (offline, missing ID,
///   Firestore rules deny, etc.). Callers can keep using the Drift
///   counter; we'll re-sync on the next successful round-trip.
///
/// Note: this service does *not* drive paywall logic on its own. The
/// existing logic still reads `UserSettings.freeTripsUsed` from Drift.
/// The repository now syncs Drift ↔ Firestore on read + increment so
/// that the cloud value wins after a reinstall.
@lazySingleton
class FreeTripCounterService {
  FreeTripCounterService(this._identity);
  @visibleForTesting
  FreeTripCounterService.withFirestore(this._identity, this._firestoreOverride);

  final DeviceIdentityService _identity;
  FirebaseFirestore? _firestoreOverride;

  // Lazy — resolved on first Firestore call so the constructor never
  // touches Firebase. That keeps DI registration free of init-order
  // constraints (the service can be instantiated before Firebase is
  // ready; the first Firestore call simply fails and the try/catch
  // returns null/false).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static const String _collection = 'device_trials';
  static const String _field = 'freeTripsUsed';

  /// Reads the remote counter for this device. Returns `null` if the
  /// device ID can't be resolved or Firestore is unreachable.
  Future<int?> pullRemoteUsed() async {
    final hash = await _identity.deviceIdHash();
    if (hash == null) return null;
    try {
      final doc = await _firestore.collection(_collection).doc(hash).get();
      if (!doc.exists) return 0;
      final value = doc.data()?[_field];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[FreeTripCounter] pull failed: $e');
      return null;
    }
  }

  /// Writes `newValue` to the remote counter for this device. Used
  /// after a successful local increment so the cloud doc stays in
  /// sync. Returns `true` if the write succeeded.
  Future<bool> setRemote(int newValue) async {
    final hash = await _identity.deviceIdHash();
    if (hash == null) return false;
    try {
      await _firestore.collection(_collection).doc(hash).set({
        _field: newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[FreeTripCounter] set failed: $e');
      return false;
    }
  }

  /// Deletes this device's `device_trials/{hash}` doc — part of
  /// account deletion's data-teardown obligation. Trade-off: since the
  /// counter is keyed by device, not account, this also resets the
  /// anti-abuse free-trial counter for this physical device. Accepted
  /// as the correct default — "delete my account" means delete what
  /// we hold about this install, and the same reset is already
  /// achievable today by uninstalling on iOS (fresh
  /// `identifierForVendor`).
  Future<void> deleteRemote() async {
    final hash = await _identity.deviceIdHash();
    if (hash == null) return;
    try {
      await _firestore.collection(_collection).doc(hash).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[FreeTripCounter] delete failed: $e');
    }
  }
}
