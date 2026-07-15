import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';

/// Abstract interface for [AuthRepository].
///
/// Extracted so that tests can supply lightweight fakes without depending on
/// a real [FirebaseAuth] instance.
abstract class AuthRepositoryInterface {
  User? get currentUser;
  bool get isSignedIn;
  bool get isAnonymous;

  Stream<User?> authStateChanges();

  Future<void> signOut();
  Future<(AuthFailure?, User?)> signInAnonymously();

  /// Signs in with Google; an anonymous session is upgraded in place
  /// (linked — same uid, data kept). [forceAccountPicker] re-shows the
  /// account chooser ("Try another account" in the link-conflict dialog).
  Future<(AuthFailure?, User?)> signInWithGoogle({bool forceAccountPicker});
  Future<(AuthFailure?, User?)> signInWithApple();

  /// After a [CredentialAlreadyLinked] failure: signs into the existing
  /// account that owns the identity (this device's anonymous session is
  /// abandoned — the "use my old data" recovery path).
  Future<(AuthFailure?, User?)> signInWithPendingLinkConflict();
  Future<(AuthFailure?, User?)> signInWithEmail({
    required String email,
    required String password,
  });
  Future<(AuthFailure?, User?)> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  });
  Future<(AuthFailure?, User?)> linkAnonymousWithEmail({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<AuthFailure?> updatePassword(String newPassword);
  Future<AuthFailure?> reauthenticate({
    required String email,
    required String password,
  });
  Future<AuthFailure?> deleteAccount();
}
