import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// Publishes the user's all-time best top speed to Firestore after every
/// trip save. Idempotent — if the new trip is slower than the user's
/// existing best, the leaderboard entry stays untouched.
///
/// Writes to two paths so country-filtered leaderboards don't need a
/// composite index:
///   /leaderboard/global/entries/{uid}
///   /leaderboard/{countryCode}/entries/{uid}
///
/// Skip silently if Firebase isn't initialised — the local Drift trip
/// is already saved; the cloud sync is best-effort. Bootstrap wires
/// this service in only when Firestore is available.
class LeaderboardWriter {
  LeaderboardWriter(this._db, this._trips, this._settings);

  final FirebaseFirestore _db;
  final TripRepository _trips;
  final UserSettingsRepository _settings;

  /// Push the user's current all-time best to both global and country
  /// boards. Safe to call after every trip save — it short-circuits if
  /// the local best didn't improve.
  Future<void> publishCurrentBest() async {
    try {
      final settings = await _settings.read();
      final best = await _trips.getPersonalBest(uid: settings.uid);
      if (best == null || best.topSpeedKmh <= 0) return;

      final country = settings.country ?? 'unknown';
      final username = settings.username.isEmpty ? 'driver' : settings.username;
      final carName = _carName(settings.carMake, settings.carModel);

      final payload = <String, Object?>{
        'username': username,
        'carName': carName,
        'topSpeedKmh': best.topSpeedKmh,
        'countryCode': country,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final globalPath =
          'leaderboard/global/entries/${settings.uid}';
      final countryPath =
          'leaderboard/$country/entries/${settings.uid}';
      if (kDebugMode) {
        debugPrint(
          '[LeaderboardWriter] → $globalPath + $countryPath '
          '(${best.topSpeedKmh.toStringAsFixed(0)} km/h, @$username)',
        );
      }

      await (_db.batch()
            ..set(
              _db
                  .collection('leaderboard')
                  .doc('global')
                  .collection('entries')
                  .doc(settings.uid),
              payload,
              SetOptions(merge: true),
            )
            ..set(
              _db
                  .collection('leaderboard')
                  .doc(country)
                  .collection('entries')
                  .doc(settings.uid),
              payload,
              SetOptions(merge: true),
            ))
          .commit();
      if (kDebugMode) {
        debugPrint(
          '[LeaderboardWriter] ✓ $globalPath + $countryPath',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[LeaderboardWriter] ✗ publishCurrentBest failed: $e\n$st',
        );
      }
    }
  }

  String _carName(String make, String model) {
    final m = make.trim();
    final mod = model.trim();
    if (m.isEmpty && mod.isEmpty) return '';
    if (mod.isEmpty) return m;
    if (m.isEmpty) return mod;
    return '$m $mod';
  }
}
