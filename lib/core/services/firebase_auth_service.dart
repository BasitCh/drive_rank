import 'dart:async';

import 'package:drive_rank/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

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
    // Try to upgrade the current anonymous user to a Google-backed
    // account using `linkWithProvider` first. That preserves the uid
    // (so all the Firestore data we've written so far — trips,
    // leaderboard entry, friend list, public profile — stays tied to
    // the same user). If linking fails because the Google account is
    // already attached to another Firebase user we fall back to a
    // straight sign-in, which swaps the uid.
    try {
      final provider = fb.GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      final current = _auth.currentUser;
      if (kDebugMode) {
        debugPrint(
          '[FirebaseAuth] → signInWithGoogle '
          '(current=${current?.uid ?? "<none>"}, '
          'anon=${current?.isAnonymous ?? false})',
        );
      }

      if (current != null && current.isAnonymous) {
        try {
          await current.linkWithProvider(provider);
          if (kDebugMode) {
            debugPrint('[FirebaseAuth] ✓ linked anonymous → Google');
          }
          return SignInResult.success;
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'provider-already-linked' ||
              e.code == 'email-already-in-use') {
            // Google account already belongs to a different Firebase
            // user — fall through and sign in straight to that one.
            if (kDebugMode) {
              debugPrint(
                '[FirebaseAuth] link rejected (${e.code}) — '
                'falling back to signInWithProvider',
              );
            }
          } else {
            rethrow;
          }
        }
      }

      await _auth.signInWithProvider(provider);
      if (kDebugMode) {
        debugPrint(
          '[FirebaseAuth] ✓ signInWithGoogle uid=${_auth.currentUser?.uid}',
        );
      }
      return SignInResult.success;
    } on fb.FirebaseAuthException catch (e, st) {
      if (e.code == 'web-context-cancelled' ||
          e.code == 'canceled' ||
          e.code == 'user-cancelled') {
        if (kDebugMode) {
          debugPrint('[FirebaseAuth] signInWithGoogle cancelled by user');
        }
        return SignInResult.cancelled;
      }
      if (kDebugMode) {
        debugPrint(
          '[FirebaseAuth] ✗ signInWithGoogle failed: ${e.code} — '
          '${e.message}\n${_googleSignInHint(e.code)}\n$st',
        );
      }
      return SignInResult.failed;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] ✗ signInWithGoogle unexpected: $e\n$st');
      }
      return SignInResult.failed;
    }
  }

  /// Translates the most common Google-sign-in error codes into the
  /// likely root cause + the exact fix step, printed alongside the
  /// raw error in the debug console. Saves a round trip to Stack
  /// Overflow when a build doesn't work end-to-end the first time.
  static String _googleSignInHint(String code) {
    switch (code) {
      case 'internal-error':
      case 'invalid-credential':
        return 'Likely: Android SHA-1 fingerprint missing from Firebase. '
            'Run `cd android && ./gradlew signingReport`, copy the '
            "debug variant's SHA-1 + SHA-256, paste them under "
            'Firebase Console → Project settings → Your apps → '
            'Android app → Add fingerprint. Re-download google-services.json '
            'and re-run.';
      case 'network-request-failed':
        return 'Device has no internet, or Firebase domains are blocked.';
      case 'operation-not-allowed':
        return 'Google provider not enabled in Firebase Console → '
            'Authentication → Sign-in method.';
      case 'api-not-available':
        return 'Google Play Services missing or out of date on this device.';
      case 'web-context-cancelled':
      case 'canceled':
      case 'user-cancelled':
        return 'User dismissed the picker.';
      default:
        return 'Unrecognised code — check the message above.';
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // After explicit sign-out we still need an authenticated principal
    // (every Firestore rule requires it). Drop back to a fresh
    // anonymous session — the user's local Drift data stays put.
    await ensureSignedIn();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      if (kDebugMode) debugPrint('[FirebaseAuth] ✓ account deleted');
    } on fb.FirebaseAuthException catch (e) {
      // `requires-recent-login` is the one realistic failure mode for
      // an anonymous/lightly-authenticated user — Firebase wants a
      // fresh credential before allowing deletion. We don't have a
      // re-auth UI for this MVP; local data teardown (the part Play
      // policy actually cares about) proceeds regardless, so this is
      // logged, not rethrown.
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] ✗ deleteAccount failed: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FirebaseAuth] ✗ deleteAccount failed: $e');
    }
    // Every Firestore rule requires an authenticated principal — drop
    // back to a fresh anonymous session the same way signOut() does,
    // so the app doesn't end up in a signed-out-forever state.
    await ensureSignedIn();
  }

  /// Ensures `_auth.currentUser` is non-null by signing in
  /// anonymously if needed. Called from bootstrap right after
  /// Firebase init — Firestore reads/writes all gate on
  /// `request.auth != null`, so without this every call returns
  /// `permission-denied` and the app feels broken.
  ///
  /// Idempotent: if a previous session is still cached on disk it
  /// re-uses that uid; no extra anonymous account is created.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    try {
      final cred = await _auth.signInAnonymously();
      _last = _toAuthUser(cred.user) ?? _pendingAnonymous;
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] signed in anonymously as ${_last.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] anonymous sign-in failed: $e');
      }
      rethrow;
    }
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
