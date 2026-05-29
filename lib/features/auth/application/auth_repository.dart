import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_auth_config.dart';
import '../domain/auth_failure.dart';
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
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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
      clientId: GoogleAuthConfig.iosClientId,
      serverClientId:
          GoogleAuthConfig.hasWebClientId ? GoogleAuthConfig.webClientId : null,
    );
    _googleSignInInitialized = true;
  }

  @override
  Future<(AuthFailure?, User?)> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

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
        result = await current.linkWithCredential(credential);
        debugPrint(
            '[Auth] linkAnonymousWithGoogle uid=${_shortUid(result.user?.uid)}');
      } else {
        result = await _auth.signInWithCredential(credential);
        debugPrint('[Auth] signInWithGoogle uid=${_shortUid(result.user?.uid)}');
      }
      return (null, result.user);
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
          '[Auth] signInWithEmail failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
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
      debugPrint('[Auth] createUserWithEmail uid=${_shortUid(result.user?.uid)} verificationSent=true');
      return (null, result.user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] createUserWithEmail failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
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
          '[Auth] linkAnonymous failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
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
          '[Auth] updatePassword success uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] updatePassword failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
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
          '[Auth] reauthenticate success uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] reauthenticate failed: code=${e.code} uid_prefix=${_shortUid(_auth.currentUser?.uid)}');
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
          '[Auth] deleteAccount failed: code=${e.code} uid_prefix=${_shortUid(uid)}');
      return _mapException(e);
    }
  }

  // ── Exception mapping ─────────────────────────────────────────────────────────

  AuthFailure _mapException(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' || 'user-not-found' || 'invalid-credential' =>
        const InvalidCredentials(),
      'email-already-in-use' || 'credential-already-in-use' =>
        const EmailAlreadyInUse(),
      'weak-password' => const WeakPassword(),
      'requires-recent-login' => const RequiresRecentLogin(),
      'network-request-failed' => const NetworkFailure(),
      _ => UnknownAuthFailure(e.message ?? e.code),
    };
  }

  String _shortUid(String? uid) =>
      uid == null ? 'null' : '${uid.substring(0, uid.length.clamp(0, 8))}…';
}
