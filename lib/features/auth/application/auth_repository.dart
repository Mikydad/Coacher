import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/google_auth_config.dart';
import '../domain/auth_failure.dart';
import 'apple_auth_nonce.dart';
import 'auth_repository_interface.dart';

/// Wraps [FirebaseAuth] and maps all exceptions to typed [AuthFailure] values.
///
/// Plain Dart — no Riverpod, no Flutter imports beyond [debugPrint].
/// Injected via [authRepositoryProvider].
class AuthRepository implements AuthRepositoryInterface {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInInitialized = false;

  /// Credential from a link attempt that failed with credential-already-in-use
  /// (the identity already owns another PathPal account). Held so the user can
  /// choose to switch to that account ([signInWithPendingLinkConflict]).
  AuthCredential? _pendingLinkConflictCredential;

  // ── Getters ──────────────────────────────────────────────────────────────────

  @override
  User? get currentUser => _auth.currentUser;
  @override
  bool get isSignedIn => _auth.currentUser != null;
  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // ── Streams ──────────────────────────────────────────────────────────────────

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ── Sign-out ─────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    debugPrint('[Auth] signOut uid=${_shortUid(_auth.currentUser?.uid)}');
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ── Anonymous ────────────────────────────────────────────────────────────────

  @override
  Future<(AuthFailure?, User?)> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      debugPrint('[Auth] signInAnonymously uid=${_shortUid(result.user?.uid)}');
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      final failure = _mapException(e);
      debugPrint('[Auth] signInAnonymously failed: code=${e.code}');
      return (failure, null);
    }
  }

  // ── Google ───────────────────────────────────────────────────────────────────

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(
      clientId: GoogleAuthConfig.hasIosClientId
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.hasWebClientId
          ? GoogleAuthConfig.webClientId
          : null,
    );
    _googleSignInInitialized = true;
  }

  @override
  Future<(AuthFailure?, User?)> signInWithGoogle({
    bool forceAccountPicker = false,
  }) async {
    try {
      await _ensureGoogleSignInInitialized();

      // "Try another account": drop the remembered Google session so the
      // account chooser is shown instead of silently reusing the last pick.
      if (forceAccountPicker) {
        await _googleSignIn.signOut();
      }

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('[Auth] signInWithGoogle failed: missing idToken');
        return (
          const UnknownAuthFailure(
            'Google sign-in did not return a token. Add your Web client ID '
            'in Firebase (see lib/core/config/google_auth_config.dart).',
          ),
          null,
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final current = _auth.currentUser;
      final UserCredential result;
      if (current != null && current.isAnonymous) {
        try {
          result = await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          final conflict = _captureLinkConflict(
            e,
            fallbackCredential: credential,
            email: e.email ?? googleUser.email,
            providerLabel: 'Google',
          );
          if (conflict != null) return (conflict, null);
          rethrow;
        }
        debugPrint(
          '[Auth] linkAnonymousWithGoogle uid=${_shortUid(result.user?.uid)}',
        );
      } else {
        result = await _auth.signInWithCredential(credential);
        debugPrint(
          '[Auth] signInWithGoogle uid=${_shortUid(result.user?.uid)}',
        );
      }

      final user = await _applyGoogleProfileToFirebaseUser(
        result.user,
        googleUser,
      );
      return (null, user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        debugPrint('[Auth] signInWithGoogle canceled');
        return (const AuthSignInCanceled(), null);
      }
      debugPrint('[Auth] signInWithGoogle failed: ${e.code} ${e.description}');
      return (UnknownAuthFailure(e.description ?? e.code.name), null);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signInWithGoogle firebase failed: code=${e.code}');
      return (_mapException(e), null);
    } catch (e) {
      debugPrint('[Auth] signInWithGoogle failed: $e');
      return (UnknownAuthFailure('$e'), null);
    }
  }

  // ── Apple ────────────────────────────────────────────────────────────────────

  @override
  Future<(AuthFailure?, User?)> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        return (
          const UnknownAuthFailure(
            'Sign in with Apple is not available on this device.',
          ),
          null,
        );
      }

      final rawNonce = generateAppleAuthNonce();
      final hashedNonce = sha256Nonce(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('[Auth] signInWithApple failed: missing identityToken');
        return (
          const UnknownAuthFailure(
            'Apple sign-in did not return a token. Enable Apple in Firebase '
            'Console → Authentication → Sign-in method.',
          ),
          null,
        );
      }

      final credential = OAuthProvider(
        'apple.com',
      ).credential(idToken: idToken, rawNonce: rawNonce);

      final current = _auth.currentUser;
      final UserCredential result;
      if (current != null && current.isAnonymous) {
        try {
          result = await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          final conflict = _captureLinkConflict(
            e,
            fallbackCredential: credential,
            email: e.email ?? appleCredential.email,
            providerLabel: 'Apple',
          );
          if (conflict != null) return (conflict, null);
          rethrow;
        }
        debugPrint(
          '[Auth] linkAnonymousWithApple uid=${_shortUid(result.user?.uid)}',
        );
      } else {
        result = await _auth.signInWithCredential(credential);
        debugPrint('[Auth] signInWithApple uid=${_shortUid(result.user?.uid)}');
      }

      final user = result.user;
      if (user != null &&
          (user.displayName == null || user.displayName!.trim().isEmpty)) {
        final given = appleCredential.givenName;
        final family = appleCredential.familyName;
        if (given != null || family != null) {
          final name = [
            given,
            family,
          ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
          if (name.isNotEmpty) {
            await user.updateDisplayName(name);
          }
        }
      }

      return (null, result.user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[Auth] signInWithApple canceled');
        return (const AuthSignInCanceled(), null);
      }
      debugPrint('[Auth] signInWithApple failed: ${e.code}');
      return (UnknownAuthFailure(e.message), null);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signInWithApple firebase failed: code=${e.code}');
      return (_mapException(e), null);
    } catch (e) {
      debugPrint('[Auth] signInWithApple failed: $e');
      return (UnknownAuthFailure('$e'), null);
    }
  }

  // ── Email / password ─────────────────────────────────────────────────────────

  @override
  Future<(AuthFailure?, User?)> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('[Auth] signInWithEmail uid=${_shortUid(result.user?.uid)}');
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] signInWithEmail failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return (_mapException(e), null);
    }
  }

  @override
  Future<(AuthFailure?, User?)> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await result.user?.updateDisplayName(displayName.trim());
      }
      // Trigger email verification immediately after account creation.
      await result.user?.sendEmailVerification();
      debugPrint(
        '[Auth] createUserWithEmail uid=${_shortUid(result.user?.uid)} verificationSent=true',
      );
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] createUserWithEmail failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return (_mapException(e), null);
    }
  }

  // ── Anonymous → email linking ─────────────────────────────────────────────────

  /// Links the current anonymous session to an email/password credential.
  ///
  /// On success the Firebase uid is **unchanged** — existing Firestore data
  /// at `users/{uid}` is preserved without any migration.
  @override
  Future<(AuthFailure?, User?)> linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return (const UnknownAuthFailure('No signed-in user to link.'), null);
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final result = await user.linkWithCredential(credential);
      debugPrint('[Auth] linkAnonymous uid=${_shortUid(result.user?.uid)}');
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] linkAnonymous failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return (_mapException(e), null);
    }
  }

  // ── Password reset ────────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Log only the email prefix — never the full address.
    final prefix = email.contains('@')
        ? '${email.split('@').first.substring(0, email.split('@').first.length.clamp(0, 3))}***'
        : '***';
    debugPrint('[Auth] sendPasswordResetEmail email_prefix=$prefix');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Account management ────────────────────────────────────────────────────────

  @override
  Future<AuthFailure?> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      debugPrint(
        '[Auth] updatePassword success uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] updatePassword failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return _mapException(e);
    }
  }

  @override
  Future<AuthFailure?> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      debugPrint(
        '[Auth] reauthenticate success uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] reauthenticate failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}',
      );
      return _mapException(e);
    }
  }

  @override
  Future<AuthFailure?> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    try {
      debugPrint('[Auth] deleteAccount uid_prefix=${_shortUid(uid)}');
      await _auth.currentUser?.delete();
      debugPrint('[Auth] deleteAccount success uid_prefix=${_shortUid(uid)}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] deleteAccount failed: code=${e.code} uid_prefix=${_shortUid(uid)}',
      );
      return _mapException(e);
    }
  }

  // ── Link-conflict recovery ───────────────────────────────────────────────────

  /// When a link attempt hits credential-already-in-use (the identity already
  /// owns another PathPal account — reinstall / phone change), cache the
  /// credential and return the typed conflict; null for unrelated errors.
  CredentialAlreadyLinked? _captureLinkConflict(
    FirebaseAuthException e, {
    required AuthCredential fallbackCredential,
    required String? email,
    required String providerLabel,
  }) {
    if (e.code != 'credential-already-in-use' &&
        e.code != 'email-already-in-use') {
      return null;
    }
    _pendingLinkConflictCredential = e.credential ?? fallbackCredential;
    debugPrint(
      '[Auth] link conflict ($providerLabel): identity already owns an '
      'account — pending credential cached',
    );
    return CredentialAlreadyLinked(email: email, providerLabel: providerLabel);
  }

  @override
  Future<(AuthFailure?, User?)> signInWithPendingLinkConflict() async {
    final credential = _pendingLinkConflictCredential;
    if (credential == null) {
      return (
        const UnknownAuthFailure(
          'The sign-in session expired. Tap Connect and pick the account '
          'again.',
        ),
        null,
      );
    }
    try {
      // Replaces the anonymous session with the existing account; its data
      // pulls down via the normal uid-change path (AuthGate + merge).
      final result = await _auth.signInWithCredential(credential);
      _pendingLinkConflictCredential = null;
      debugPrint(
        '[Auth] switched to existing linked account '
        'uid=${_shortUid(result.user?.uid)}',
      );
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      _pendingLinkConflictCredential = null;
      debugPrint('[Auth] pending-conflict sign-in failed: code=${e.code}');
      return (_mapException(e), null);
    }
  }

  // ── Exception mapping ─────────────────────────────────────────────────────────

  AuthFailure _mapException(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => const InvalidCredentials(),
      'email-already-in-use' ||
      'credential-already-in-use' => const EmailAlreadyInUse(),
      'weak-password' => const WeakPassword(),
      'requires-recent-login' => const RequiresRecentLogin(),
      'network-request-failed' => const NetworkFailure(),
      _ => UnknownAuthFailure(e.message ?? e.code),
    };
  }

  /// Copies Google account name/photo onto the Firebase user when missing.
  Future<User?> _applyGoogleProfileToFirebaseUser(
    User? user,
    GoogleSignInAccount googleUser,
  ) async {
    if (user == null) return null;

    final googleName = googleUser.displayName?.trim();
    final googlePhoto = googleUser.photoUrl?.trim();

    final needsName =
        googleName != null &&
        googleName.isNotEmpty &&
        (user.displayName == null || user.displayName!.trim().isEmpty);
    final needsPhoto =
        googlePhoto != null &&
        googlePhoto.isNotEmpty &&
        (user.photoURL == null || user.photoURL!.trim().isEmpty);

    if (!needsName && !needsPhoto) return user;

    if (needsName) {
      await user.updateDisplayName(googleName);
      debugPrint('[Auth] signInWithGoogle set displayName from Google profile');
    }
    if (needsPhoto) {
      await user.updatePhotoURL(googlePhoto);
    }
    await user.reload();
    return _auth.currentUser ?? user;
  }

  String _shortUid(String? uid) =>
      uid == null ? 'null' : '${uid.substring(0, uid.length.clamp(0, 8))}…';
}
