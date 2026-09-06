import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// What happened when an account tried to hold a username.
enum UsernameClaim {
  /// The name is now this account's.
  claimed,

  /// It was already this account's — re-claiming is a no-op, which is
  /// what makes the claim safe to run on every launch.
  alreadyMine,

  /// Held by a different account.
  taken,

  /// Couldn't reach the reservation at all (offline, Firebase absent,
  /// rules rejected). Deliberately distinct from [taken]: a name whose
  /// status is *unknown* must never be reported to the user as somebody
  /// else's, and an upgrade that can't reach the network must not
  /// conclude the user's own name is unavailable.
  unknown,
}

/// Holds usernames, one account each.
///
/// Usernames were local-only until now — validated for shape, never for
/// uniqueness, so two accounts can already be `basit`. That was fine
/// while a username was cosmetic; friend search makes it an address, and
/// an address has to resolve to one person.
///
/// **Reservations are permanent.** Deleting an account does not free its
/// name. Releasing names would need a controlled deletion path — itself
/// a security operation — and would allow recycling: a handle appears in
/// a friend's list, is released, and is re-claimed by someone who now
/// inherits that history. A permanently held name costs a finite
/// namespace and nothing else.
abstract class UsernameReservationService {
  /// Attempts to hold [username] for [uid]. Idempotent for the same uid.
  Future<UsernameClaim> claim({required String uid, required String username});

  /// Whether [username] is free, or already held by [forUid].
  ///
  /// For the onboarding field's live feedback. Returns
  /// [UsernameClaim.unknown] rather than guessing when the lookup fails,
  /// so the UI can stay quiet instead of accusing a free name of being
  /// taken.
  Future<UsernameClaim> check({required String username, String? forUid});
}

/// Normalises a username to its reservation key.
///
/// One key per name regardless of case, so `Basit` and `basit` are the
/// same address — matching what `usernameLower` in the public profile
/// has always implied but never enforced.
String usernameKey(String username) => username.trim().toLowerCase();

/// Default when Firebase isn't initialised.
///
/// Reports every name as claimed rather than unknown: with no cloud
/// there is no shared namespace to collide in, and onboarding must not
/// stall on a check that can never resolve.
@LazySingleton(as: UsernameReservationService)
class NoopUsernameReservationService implements UsernameReservationService {
  const NoopUsernameReservationService();

  @override
  Future<UsernameClaim> claim({
    required String uid,
    required String username,
  }) async => UsernameClaim.claimed;

  @override
  Future<UsernameClaim> check({
    required String username,
    String? forUid,
  }) async => UsernameClaim.claimed;
}

/// Production implementation — one document per name at
/// `usernames/{usernameLower}`.
///
/// The document *is* the lock: Firestore rules allow a create only when
/// the doc doesn't exist, so two accounts racing for the same name
/// resolve server-side with exactly one winner. The transaction below
/// gives the loser a clean [UsernameClaim.taken] instead of a raw
/// permission error.
class FirestoreUsernameReservationService
    implements UsernameReservationService {
  FirestoreUsernameReservationService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String username) =>
      _firestore.collection('usernames').doc(usernameKey(username));

  @override
  Future<UsernameClaim> claim({
    required String uid,
    required String username,
  }) async {
    final key = usernameKey(username);
    if (key.isEmpty || uid.isEmpty) return UsernameClaim.unknown;

    try {
      return await _firestore.runTransaction<UsernameClaim>((tx) async {
        final ref = _ref(key);
        final snapshot = await tx.get(ref);
        if (snapshot.exists) {
          final holder = snapshot.data()?['uid'] as String?;
          return holder == uid ? UsernameClaim.alreadyMine : UsernameClaim.taken;
        }
        tx.set(ref, {
          'uid': uid,
          'claimedAt': FieldValue.serverTimestamp(),
        });
        return UsernameClaim.claimed;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Usernames] claim "$key" failed: $e');
      }
      // Could be offline, could be the rules refusing a create because
      // someone won the race between the read and the write. Either way
      // the caller keeps its local name and stays unclaimed rather than
      // treating an unknown as a refusal.
      return UsernameClaim.unknown;
    }
  }

  @override
  Future<UsernameClaim> check({
    required String username,
    String? forUid,
  }) async {
    final key = usernameKey(username);
    if (key.isEmpty) return UsernameClaim.unknown;
    try {
      final snapshot = await _ref(key).get();
      if (!snapshot.exists) return UsernameClaim.claimed;
      final holder = snapshot.data()?['uid'] as String?;
      return holder != null && holder == forUid
          ? UsernameClaim.alreadyMine
          : UsernameClaim.taken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Usernames] check "$key" failed: $e');
      }
      return UsernameClaim.unknown;
    }
  }
}
