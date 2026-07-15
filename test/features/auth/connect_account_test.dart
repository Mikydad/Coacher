import 'package:coach_for_life/features/auth/domain/auth_failure.dart';
import 'package:coach_for_life/features/auth/presentation/widgets/connect_account_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/auth/application/auth_providers.dart';

/// Minimal fake [User] — only the members ConnectAccountSection reads.
class _FakeUser implements User {
  _FakeUser({
    required this.isAnonymous,
    this.email,
    List<String> providerIds = const [],
  }) : _providerIds = providerIds;

  @override
  final bool isAnonymous;
  @override
  final String? email;
  final List<String> _providerIds;

  @override
  List<UserInfo> get providerData => [
    for (final id in _providerIds) _FakeUserInfo(id),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserInfo implements UserInfo {
  _FakeUserInfo(this.providerId);
  @override
  final String providerId;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(User? user) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
  ],
  child: const MaterialApp(home: Scaffold(body: ConnectAccountSection())),
);

void main() {
  group('CredentialAlreadyLinked', () {
    test('message names the provider when known', () {
      const failure = CredentialAlreadyLinked(providerLabel: 'Google');
      expect(
        failure.toUserMessage(),
        'This Google account is already connected to an existing PathPal '
        'account.',
      );
    });

    test('message stays sensible without a provider label', () {
      const failure = CredentialAlreadyLinked();
      expect(failure.toUserMessage(), contains('already connected'));
    });
  });

  group('ConnectAccountSection (guest connect prompt on Profile)', () {
    testWidgets('anonymous user sees the single Connect account button', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_FakeUser(isAnonymous: true)));
      await tester.pump();
      expect(find.text('Connect account'), findsOneWidget);
      expect(find.text('Connect with Google'), findsNothing);
    });

    testWidgets('tapping the button opens the provider sheet', (tester) async {
      await tester.pumpWidget(_host(_FakeUser(isAnonymous: true)));
      await tester.pump();
      await tester.tap(find.text('Connect account'));
      await tester.pumpAndSettle();
      expect(find.text('Connect an account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('registered user sees nothing here (identity lives in '
        'Account settings)', (tester) async {
      await tester.pumpWidget(
        _host(
          _FakeUser(
            isAnonymous: false,
            email: 'miko@example.com',
            providerIds: const ['google.com'],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Connect account'), findsNothing);
      expect(find.text('Account connected'), findsNothing);
    });

    testWidgets('renders nothing while signed out', (tester) async {
      await tester.pumpWidget(_host(null));
      await tester.pump();
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('ConnectedIdentityCard (Account settings)', () {
    Widget hostCard(User user) => MaterialApp(
      home: Scaffold(body: ConnectedIdentityCard(user: user)),
    );

    testWidgets('Google user shows the Google badge + email', (tester) async {
      await tester.pumpWidget(
        hostCard(
          _FakeUser(
            isAnonymous: false,
            email: 'miko@example.com',
            providerIds: const ['google.com'],
          ),
        ),
      );
      expect(find.text('Account connected'), findsOneWidget);
      expect(find.text('Google · miko@example.com'), findsOneWidget);
    });

    testWidgets('email user falls back to the Email badge', (tester) async {
      await tester.pumpWidget(
        hostCard(
          _FakeUser(
            isAnonymous: false,
            email: 'miko@example.com',
            providerIds: const ['password'],
          ),
        ),
      );
      expect(find.text('Email · miko@example.com'), findsOneWidget);
    });
  });
}
