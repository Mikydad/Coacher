import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthInitializer {
  const AuthInitializer._();

  /// Returns whether a Firebase user is available (existing session or new anonymous).
  static Future<bool> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      debugPrint('Firebase Auth already signed in: ${auth.currentUser!.uid}');
      return true;
    }
    try {
      final credential = await auth.signInAnonymously();
      debugPrint('Signed in anonymously: ${credential.user?.uid}');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Anonymous sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
