import 'dart:async';

import 'package:drive_rank/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Production [AuthService] backed by Firebase Auth.
///
/// Registered in the `firebase` injectable environment — only wired up
/// at bootstrap when `Firebase.initializeApp()` succeeds. If you've just
/// run `flutterfire configure`, the bootstrap auto-detects the new
/// config and the app starts using this service on the next launch.
///
/// Google sign-in uses `signInWithProvider(GoogleAuthProvider)` (modern
/// Firebase Auth 5.x flow) — no separate `google_sign_in` package
/// dependency, which keeps the iOS reverse-client-id configuration
/// limited to the Firebase plist.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth) {
    _last = _toAuthUser(_auth.currentUser) ?? _pendingAnonymous;
    _sub = _auth.authStateChanges().listen((u) {
      _last = _toAuthUser(u) ?? _pendingAnonymous;
      _controller.add(_last);
    });
  }

  static const AuthUser _pendingAnonymous = AuthUser(
    uid: 'pending',
    isAnonymous: true,
  );

  final fb.FirebaseAuth _auth;

  late final StreamSubscription<fb.User?> _sub;
  AuthUser _last = _pendingAnonymous;
  final _controller = StreamController<AuthUser>.broadcast();

  @override
  AuthUser get currentUser => _last;

  @override
  Stream<AuthUser> get userChanges => _controller.stream;

  @override
  Future<SignInResult> signInWithGoogle() async {
    try {
      // On a missing native config this throws a `FirebaseException` rather
      // than silently failing. The caller surfaces a retryable toast.
      final provider = fb.GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      await _auth.signInWithProvider(provider);
      return SignInResult.success;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' ||
          e.code == 'canceled' ||
          e.code == 'user-cancelled') {
        return SignInResult.cancelled;
      }
      return SignInResult.failed;
    } catch (_) {
      return SignInResult.failed;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  AuthUser? _toAuthUser(fb.User? u) {
    if (u == null) return null;
    return AuthUser(
      uid: u.uid,
      isAnonymous: u.isAnonymous,
      displayName: u.displayName,
      email: u.email,
      photoUrl: u.photoURL,
    );
  }

  Future<void> dispose() async {
    await _sub.cancel();
    await _controller.close();
  }
}
