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
  Future<(AuthFailure?, User?)> signInWithGoogle();
  Future<(AuthFailure?, User?)> signInWithApple();
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
