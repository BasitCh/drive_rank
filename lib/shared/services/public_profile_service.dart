import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Public profile fields mirrored to Firestore at `/users/{uid}` — this is
/// what makes a signed-in account portable across devices ("everything is
/// there" per the sync feature this belongs to) and, later, what a
/// leaderboard/friend-search feature would read.
///
/// Intentionally a *separate* concern from `UserSettings` (the local
/// Drift row + private preferences). Both the post-onboarding push and
/// any settings edit that touches these fields call into here.
@immutable
class PublicProfilePayload {
  const PublicProfilePayload({
    required this.uid,
    required this.username,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.countryCode,
    this.carPhotoUrl,
    this.topSpeedKmh,
  });

  factory PublicProfilePayload.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return PublicProfilePayload(
      uid: uid,
      username: data['username'] as String? ?? '',
      carMake: data['carMake'] as String? ?? '',
      carModel: data['carModel'] as String? ?? '',
      carYear: (data['carYear'] as num?)?.toInt(),
      countryCode: data['countryCode'] as String? ?? '',
      carPhotoUrl: data['carPhotoUrl'] as String?,
      topSpeedKmh: (data['topSpeedKmh'] as num?)?.toDouble(),
    );
  }

  final String uid;
  final String username;
  final String carMake;
  final String carModel;
  final int? carYear;
  final String countryCode;

  /// Firebase Storage download URL for the car photo (this app's
  /// "profile picture" — see `CarSilhouette`), null if none uploaded.
  final String? carPhotoUrl;

  /// Lifetime best top speed — future leaderboard ranking field.
  final double? topSpeedKmh;

  /// Display string — "Toyota Corolla 2022" / "Honda Civic" / "" depending
  /// on what's filled in.
  String get carName {
    final parts = <String>[
      if (carMake.trim().isNotEmpty) carMake.trim(),
      if (carModel.trim().isNotEmpty) carModel.trim(),
      if (carYear != null) carYear.toString(),
    ];
    return parts.join(' ');
  }

  Map<String, dynamic> toFirestore() => {
    'username': username,
    'usernameLower': username.toLowerCase(),
    'carMake': carMake,
    'carModel': carModel,
    if (carYear != null) 'carYear': carYear,
    'carName': carName,
    if (carPhotoUrl != null) 'carPhotoUrl': carPhotoUrl,
    'countryCode': countryCode,
    if (topSpeedKmh != null) 'topSpeedKmh': topSpeedKmh,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

// ignore: one_member_abstracts
abstract class PublicProfileService {
  /// Upserts the user's public profile doc. Idempotent — calling twice
  /// with the same payload is fine. Network/auth failures are logged
  /// and swallowed; the local Drift settings already saved the same
  /// values, so the next online write attempt picks them up.
  Future<void> publish(PublicProfilePayload payload);
}

/// Default implementation registered when Firebase is not initialised.
/// Logs the would-be write so the dev console makes it obvious nothing's
/// hitting the network.
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

/// Production implementation — writes to `/users/{uid}`.
class FirestorePublicProfileService implements PublicProfileService {
  FirestorePublicProfileService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> publish(PublicProfilePayload payload) async {
    try {
      await _firestore
          .collection('users')
          .doc(payload.uid)
          .set(payload.toFirestore(), SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[PublicProfile] ✓ /users/${payload.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PublicProfile] ✗ /users/${payload.uid} failed: $e');
      }
      // Swallowed on purpose — the local Drift row already has the same
      // values, so this isn't a data-loss risk, just a delayed sync.
    }
  }
}
