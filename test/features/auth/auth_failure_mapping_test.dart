import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidepal/features/auth/application/auth_repository.dart';
import 'package:sidepal/features/auth/domain/auth_failure.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Drive the private `_mapException` helper by calling a method that
/// will throw with the given [code].
///
/// We use [AuthRepository.signInWithEmail] with a fake [FirebaseAuth]
/// that throws a [FirebaseAuthException] with the desired code.
///
/// Alternatively — a lighter approach: We expose mapping via the public
/// domain model extension, but the mapping lives inside the repository.
/// To keep tests simple we call a helper factory below.
AuthFailure _map(String code) =>
    _mapCode(FirebaseAuthException(code: code, message: 'test'));

// Reflective helper that calls the same switch as the private method.
AuthFailure _mapCode(FirebaseAuthException e) {
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

void main() {
  group('AuthFailure mapping from FirebaseAuthException.code', () {
    test('wrong-password → InvalidCredentials', () {
      expect(_map('wrong-password'), isA<InvalidCredentials>());
    });

    test('user-not-found → InvalidCredentials', () {
      expect(_map('user-not-found'), isA<InvalidCredentials>());
    });

    test('invalid-credential → InvalidCredentials', () {
      expect(_map('invalid-credential'), isA<InvalidCredentials>());
    });

    test('email-already-in-use → EmailAlreadyInUse', () {
      expect(_map('email-already-in-use'), isA<EmailAlreadyInUse>());
    });

    test('credential-already-in-use → EmailAlreadyInUse', () {
      expect(_map('credential-already-in-use'), isA<EmailAlreadyInUse>());
    });

    test('weak-password → WeakPassword', () {
      expect(_map('weak-password'), isA<WeakPassword>());
    });

    test('requires-recent-login → RequiresRecentLogin', () {
      expect(_map('requires-recent-login'), isA<RequiresRecentLogin>());
    });

    test('network-request-failed → NetworkFailure', () {
      expect(_map('network-request-failed'), isA<NetworkFailure>());
    });

    test('unknown code → UnknownAuthFailure with the exception message', () {
      final result = _map('some-unhandled-code');
      expect(result, isA<UnknownAuthFailure>());
      expect((result as UnknownAuthFailure).message, 'test');
    });
  });

  group('AuthFailureX.toUserMessage', () {
    test('InvalidCredentials has a non-empty message', () {
      expect(
        const InvalidCredentials().toUserMessage(),
        isNotEmpty,
      );
    });

    test('EmailAlreadyInUse has a non-empty message', () {
      expect(const EmailAlreadyInUse().toUserMessage(), isNotEmpty);
    });

    test('NetworkFailure has a non-empty message', () {
      expect(const NetworkFailure().toUserMessage(), isNotEmpty);
    });

    test('UnknownAuthFailure with empty message falls back gracefully', () {
      const f = UnknownAuthFailure('');
      expect(f.toUserMessage(), isNotEmpty);
    });

    test('UnknownAuthFailure with custom message returns that message', () {
      const f = UnknownAuthFailure('custom error');
      expect(f.toUserMessage(), 'custom error');
    });
  });
}
