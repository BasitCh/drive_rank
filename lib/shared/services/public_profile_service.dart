import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Public, searchable user profile fields. Mirrored to Firestore at
/// `/users/{uid}` so the friends-feature username-prefix search and any
/// future "view a friend's profile" surfaces can read them.
///
/// This is intentionally a *separate* concern from `UserSettings`
/// (which is the local Drift row + private preferences) and from
/// `UsernameRepository` (which is the uniqueness reservation). Both
/// onboarding-complete and settings-edit call into here when those
/// public fields change.
@immutable
class PublicProfilePayload {
  const PublicProfilePayload({
    required this.uid,
    required this.username,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.countryCode,
  });

  final String uid;
  final String username;
  final String carMake;
  final String carModel;
  final int? carYear;
  final String countryCode;

  /// Display string used on the leaderboard and stat card — "Toyota
  /// Corolla 2022" / "Honda Civic" / "Car" depending on what's filled
  /// in. Friend search reads it back so we precompute it here once.
  String get carName {
    final parts = <String>[
      if (carMake.trim().isNotEmpty) carMake.trim(),
      if (carModel.trim().isNotEmpty) carModel.trim(),
      if (carYear != null) carYear.toString(),
    ];
    return parts.join(' ');
  }
}

// ignore: one_member_abstracts
abstract class PublicProfileService {
  /// Upserts the user's public profile doc. Idempotent — calling twice
  /// with the same payload is fine. Network/auth failures are logged
  /// and swallowed; the local Drift settings already saved the same
  /// values, so the next online write attempt picks them up.
  Future<void> publish(PublicProfilePayload payload);
}

/// Default implementation registered in the DI container when Firebase
/// is not initialised. Logs the would-be write so the dev console
/// makes it obvious nothing's hitting the network.
@LazySingleton(as: PublicProfileService)
class NoopPublicProfileService implements PublicProfileService {
  NoopPublicProfileService();

  @override
  Future<void> publish(PublicProfilePayload payload) async {
    if (kDebugMode) {
      debugPrint(
        '[PublicProfile] (preview) skip /users/${payload.uid} '
        '— Firebase not initialised',
      );
    }
  }
}

/// Real implementation — writes one merge-set document per call to
/// `/users/{uid}`. Bootstrap swaps this in for the no-op above as
/// soon as Firebase init succeeds.
class FirestorePublicProfileService implements PublicProfileService {
  FirestorePublicProfileService(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> publish(PublicProfilePayload p) async {
    final docPath = 'users/${p.uid}';
    if (kDebugMode) {
      debugPrint(
        '[PublicProfile] writing $docPath '
        '(@${p.username}, ${p.carName.isEmpty ? "no car" : p.carName})',
      );
    }
    try {
      await _db.collection('users').doc(p.uid).set(
        <String, Object?>{
          'username': p.username,
          // Lowercased mirror that powers the friend-search prefix
          // range query — keep this in lockstep with `username`.
          'usernameLower': p.username.toLowerCase(),
          'carMake': p.carMake,
          'carModel': p.carModel,
          'carName': p.carName,
          'countryCode': p.countryCode,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (kDebugMode) {
        debugPrint('[PublicProfile] ✓ $docPath');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PublicProfile] ✗ $docPath failed: $e\n$st');
      }
    }
  }
}
