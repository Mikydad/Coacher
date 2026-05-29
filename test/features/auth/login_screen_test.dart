import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:coach_for_life/features/auth/application/auth_providers.dart';
import 'package:coach_for_life/features/auth/application/auth_repository_interface.dart';
import 'package:coach_for_life/features/auth/domain/auth_failure.dart';
import 'package:coach_for_life/features/auth/presentation/login_screen.dart';
import 'package:coach_for_life/features/auth/presentation/widgets/auth_error_text.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeAuthRepo implements AuthRepositoryInterface {
  _FakeAuthRepo({this.signInResult});

  final (AuthFailure?, User?)? signInResult;
  int signInCallCount = 0;

  @override
  User? get currentUser => null;
  @override
  bool get isSignedIn => false;
  @override
  bool get isAnonymous => false;
  @override
  Stream<User?> authStateChanges() => const Stream.empty();
  @override
  Future<void> signOut() async {}
  @override
  Future<(AuthFailure?, User?)> signInAnonymously() async =>
      (const NetworkFailure(), null);
  @override
  Future<(AuthFailure?, User?)> signInWithGoogle() async =>
      (const AuthSignInCanceled(), null);
  @override
  Future<(AuthFailure?, User?)> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    return signInResult ?? (const InvalidCredentials(), null);
  }

  @override
  Future<(AuthFailure?, User?)> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      (null, null);
  @override
  Future<(AuthFailure?, User?)> linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async =>
      (null, null);
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<AuthFailure?> updatePassword(String newPassword) async => null;
  @override
  Future<AuthFailure?> reauthenticate({
    required String email,
    required String password,
  }) async =>
      null;
  @override
  Future<AuthFailure?> deleteAccount() async => null;
}

class _SlowSignInRepo extends _FakeAuthRepo {
  _SlowSignInRepo(this._future);
  final Future<(AuthFailure?, User?)> _future;

  @override
  Future<(AuthFailure?, User?)> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _future;
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen(AuthRepositoryInterface fake) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      authStateProvider.overrideWith((_) => const Stream.empty()),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen', () {
    testWidgets('submit with empty fields → validation error, no network call',
        (tester) async {
      final fake = _FakeAuthRepo();
      await tester.pumpWidget(_buildScreen(fake));

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.byType(AuthErrorText), findsOneWidget);
      expect(
          find.text('Please enter your email and password.'), findsOneWidget);
      expect(fake.signInCallCount, 0);
    });

    testWidgets(
        'mock returns InvalidCredentials → AuthErrorText shown',
        (tester) async {
      final fake =
          _FakeAuthRepo(signInResult: (const InvalidCredentials(), null));
      await tester.pumpWidget(_buildScreen(fake));

      await tester.enterText(
          find.widgetWithText(TextField, 'Email address'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AuthErrorText), findsOneWidget);
      expect(fake.signInCallCount, 1);
    });

    testWidgets('loading state → button is disabled', (tester) async {
      final completer = Completer<(AuthFailure?, User?)>();
      final fake = _SlowSignInRepo(completer.future);

      await tester.pumpWidget(_buildScreen(fake));

      await tester.enterText(
          find.widgetWithText(TextField, 'Email address'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'pass1234');

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);

      completer.complete((const InvalidCredentials(), null));
      await tester.pump();
    });
  });
}
