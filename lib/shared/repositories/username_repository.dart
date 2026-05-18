import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Outcome of a username availability check.
enum UsernameAvailability {
  /// Free to claim — no document exists at /usernames/{lowercased}.
  available,

  /// Already owned by someone else.
  taken,

  /// Length / character set violations — never hits the network.
  invalidFormat,

  /// Less than 3 characters — never hits the network.
  tooShort,

  /// Network or backend error.
  error,
}

/// Outcome of the atomic reservation transaction at end of onboarding.
enum UsernameReservationResult {
  reserved,

  /// Someone else grabbed it between the check and the submit. UI
  /// surfaces an inline error and prompts the user to choose another.
  raced,

  invalidFormat,
  tooShort,
  error,
}

/// Username lookups + atomic reservation.
///
/// Two implementations: a preview that never hits the network (always
/// returns `available`) for development without Firestore, and a
/// Firestore-backed one for production. Bootstrap swaps in the real
/// one when Firebase init succeeds.
abstract class UsernameRepository {
  Future<UsernameAvailability> check(String raw);

  /// Atomically claim the username for [uid]. The transaction re-reads
  /// the doc inside the txn so a parallel reserve can't double-allocate.
  Future<UsernameReservationResult> reserve({
    required String raw,
    required String uid,
  });

  /// Username currently owned by [uid], if any — used by Settings to
  /// avoid "taken" against the user's own name on re-edit.
  Future<String?> currentFor(String uid);
}

/// Validation rules — public so the UI can render them as helper text.
class UsernameRules {
  const UsernameRules._();

  static const int minLength = 3;
  static const int maxLength = 24;

  /// Letters, digits, and underscore only. Lowercased for storage and
  /// uniqueness — `Hassan_Drives` and `hassan_drives` collide.
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9_]+$');

  static UsernameAvailability validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < minLength) return UsernameAvailability.tooShort;
    if (trimmed.length > maxLength) return UsernameAvailability.invalidFormat;
    if (!_allowed.hasMatch(trimmed)) {
      return UsernameAvailability.invalidFormat;
    }
    return UsernameAvailability.available;
  }

  /// Normalise to the storage form (lowercase).
  static String normalise(String raw) => raw.trim().toLowerCase();
}

@LazySingleton(as: UsernameRepository)
class PreviewUsernameRepository implements UsernameRepository {
  PreviewUsernameRepository();

  final _reserved = <String, String>{};

  @override
  Future<UsernameAvailability> check(String raw) async {
    final invalid = UsernameRules.validate(raw);
    if (invalid != UsernameAvailability.available) return invalid;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final key = UsernameRules.normalise(raw);
    return _reserved.containsKey(key)
        ? UsernameAvailability.taken
        : UsernameAvailability.available;
  }

  @override
  Future<UsernameReservationResult> reserve({
    required String raw,
    required String uid,
  }) async {
    final invalid = UsernameRules.validate(raw);
    if (invalid == UsernameAvailability.tooShort) {
      return UsernameReservationResult.tooShort;
    }
    if (invalid == UsernameAvailability.invalidFormat) {
      return UsernameReservationResult.invalidFormat;
    }
    final key = UsernameRules.normalise(raw);
    if (_reserved[key] != null && _reserved[key] != uid) {
      return UsernameReservationResult.raced;
    }
    _reserved[key] = uid;
    return UsernameReservationResult.reserved;
  }

  @override
  Future<String?> currentFor(String uid) async {
    for (final entry in _reserved.entries) {
      if (entry.value == uid) return entry.key;
    }
    return null;
  }
}

/// Production [UsernameRepository] backed by `cloud_firestore`. Swapped
/// in at bootstrap time when Firebase init succeeds — until then the
/// preview impl ships, so the app keeps working without a network.
class FirestoreUsernameRepository implements UsernameRepository {
  FirestoreUsernameRepository(this._db);

  final FirebaseFirestore _db;

  /// Collection holding one document per claimed username — doc id is
  /// the lowercased username, fields are { uid, createdAt }.
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  @override
  Future<UsernameAvailability> check(String raw) async {
    final invalid = UsernameRules.validate(raw);
    if (invalid != UsernameAvailability.available) return invalid;
    try {
      final snap = await _usernames.doc(UsernameRules.normalise(raw)).get();
      return snap.exists
          ? UsernameAvailability.taken
          : UsernameAvailability.available;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsernameRepository] check failed: $e');
      }
      return UsernameAvailability.error;
    }
  }

  @override
  Future<UsernameReservationResult> reserve({
    required String raw,
    required String uid,
  }) async {
    final invalid = UsernameRules.validate(raw);
    if (invalid == UsernameAvailability.tooShort) {
      return UsernameReservationResult.tooShort;
    }
    if (invalid == UsernameAvailability.invalidFormat) {
      return UsernameReservationResult.invalidFormat;
    }
    final key = UsernameRules.normalise(raw);
    try {
      return await _db.runTransaction<UsernameReservationResult>((txn) async {
        final doc = _usernames.doc(key);
        final snap = await txn.get(doc);
        if (snap.exists) {
          final ownerUid = snap.data()?['uid'] as String?;
          if (ownerUid == uid) {
            // Idempotent — same user re-running flow.
            return UsernameReservationResult.reserved;
          }
          return UsernameReservationResult.raced;
        }
        txn.set(doc, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return UsernameReservationResult.reserved;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsernameRepository] reserve failed: $e');
      }
      return UsernameReservationResult.error;
    }
  }

  @override
  Future<String?> currentFor(String uid) async {
    try {
      final results = await _usernames
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (results.docs.isEmpty) return null;
      return results.docs.first.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsernameRepository] currentFor failed: $e');
      }
      return null;
    }
  }
}
