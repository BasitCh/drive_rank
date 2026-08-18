import 'dart:async';

import 'package:flutter/foundation.dart';

/// A user from the auth layer's perspective. `uid` is the only field the
/// rest of the app needs — name/email are nice-to-have for the profile.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}

/// Result of a sign-in attempt.
enum SignInResult {
  /// User completed sign-in.
  success,

  /// User dismissed the platform sign-in dialog without completing.
  cancelled,

  /// Sign-in failed (network, bad credential, …) — caller surfaces a
  /// retryable toast.
  failed,
}

/// Auth boundary the rest of the app reads from.
///
/// Two implementations are registered behind this interface:
///
///  - `AnonymousAuthService` (default) — generates a stable local-only
///    UID, returns it from `currentUser`, and treats sign-in/-out as
///    no-ops. The app boots and runs without Firebase configured.
///  - `FirebaseAuthService` — registered in place of the anonymous
///    one when Firebase init succeeds at bootstrap time.
///
/// The repository layer keys all trip rows off `currentUser.uid` so the
/// switch from anonymous → Google preserves trip ownership trivially in
/// Session-5-plus when account linking lands.
abstract class AuthService {
  AuthUser get currentUser;
  Stream<AuthUser> get userChanges;

  Future<SignInResult> signInWithGoogle();
  Future<void> signOut();

  /// Permanently deletes the remote account (Google Play "Delete my
  /// account" requirement). Best-effort — implementations should not
  /// throw on failure so local data teardown can still proceed; the
  /// caller decides how to surface a partial failure.
  Future<void> deleteAccount();
}

/// Default implementation — every install gets a stable local UID. No
/// network, no platform dialogs, no failure modes. Registered manually
/// in bootstrap when Firebase init fails or is skipped.
class AnonymousAuthService implements AuthService {
  AnonymousAuthService();

  static const String _stableLocalUid = 'local';

  final _controller = StreamController<AuthUser>.broadcast();

  @override
  AuthUser get currentUser =>
      const AuthUser(uid: _stableLocalUid, isAnonymous: true);

  @override
  Stream<AuthUser> get userChanges => _controller.stream;

  @override
  Future<SignInResult> signInWithGoogle() async {
    // Without Firebase Auth configured we can't run the Google flow.
    // Surface a clear "not configured" failure so the UI can show the
    // appropriate copy — Session 5+ swaps in FirebaseAuthService once
    // firebase_options.dart is generated.
    return SignInResult.failed;
  }

  @override
  Future<void> signOut() async {
    // No-op for the anonymous service.
  }

  @override
  Future<void> deleteAccount() async {
    // No-op — there's no remote account to delete without Firebase.
  }
}
