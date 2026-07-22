import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sidepal/features/auth/application/auth_providers.dart';
import 'package:sidepal/features/auth/application/auth_repository_interface.dart';
import 'package:sidepal/features/auth/domain/auth_failure.dart';
import 'package:sidepal/features/auth/presentation/sign_up_screen.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeAuthRepo implements AuthRepositoryInterface {
  _FakeAuthRepo({this.createResult, this.linkResult});

  final (AuthFailure?, User?)? createResult;
  final (AuthFailure?, User?)? linkResult;

  @override
  User? get currentUser => null; // not anonymous → use createUserWithEmail path
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
  Future<(AuthFailure?, User?)> signInWithApple() async =>
      (const AuthSignInCanceled(), null);
  @override
  Future<(AuthFailure?, User?)> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      (null, null);
  @override
  Future<(AuthFailure?, User?)> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      createResult ?? (null, null);
  @override
  Future<(AuthFailure?, User?)> linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async =>
      linkResult ?? (null, null);
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

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen(AuthRepositoryInterface fake) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      authStateProvider.overrideWith((_) => const Stream.empty()),
    ],
    child: const MaterialApp(
      home: SignUpScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SignUpScreen', () {
    testWidgets('password shorter than 8 chars → inline error before submit',
        (tester) async {
      final fake = _FakeAuthRepo();
      await tester.pumpWidget(_buildScreen(fake));

      // Accept ToS.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'Email address'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password (min 8 characters)'),
          'short');
      await tester.enterText(
          find.widgetWithText(TextField, 'Confirm password'), 'short');

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(
          find.text('Password must be at least 8 characters.'), findsOneWidget);
    });

    testWidgets('confirm password mismatch → inline error before submit',
        (tester) async {
      final fake = _FakeAuthRepo();
      await tester.pumpWidget(_buildScreen(fake));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'Email address'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password (min 8 characters)'),
          'password1');
      await tester.enterText(
          find.widgetWithText(TextField, 'Confirm password'), 'password2');

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('mock returns EmailAlreadyInUse → dialog shown',
        (tester) async {
      final fake =
          _FakeAuthRepo(createResult: (const EmailAlreadyInUse(), null));
      await tester.pumpWidget(_buildScreen(fake));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'Email address'), 'exists@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password (min 8 characters)'),
          'password1');
      await tester.enterText(
          find.widgetWithText(TextField, 'Confirm password'), 'password1');

      await tester.tap(find.text('Create account'));
      await tester.pump();
      await tester.pump(); // let async + showDialog run

      expect(find.text('Account already exists'), findsOneWidget);
    });

    testWidgets('ToS unchecked → submit button disabled', (tester) async {
      final fake = _FakeAuthRepo();
      await tester.pumpWidget(_buildScreen(fake));

      // Do NOT tap the checkbox.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull,
          reason: 'Button must be disabled until ToS is checked');
    });
  });
}
