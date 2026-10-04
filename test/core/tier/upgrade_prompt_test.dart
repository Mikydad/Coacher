import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/tier/pro_plan_screen.dart';
import 'package:sidepal/core/tier/tier_limits.dart';
import 'package:sidepal/core/tier/upgrade_prompt.dart';
import 'package:sidepal/features/auth/application/auth_providers.dart';

/// Minimal fake [User] — only `isAnonymous` is read by the prompts.
class _FakeUser implements User {
  _FakeUser({required this.isAnonymous});

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A host whose buttons open the prompts, with the /pro route registered.
Widget _host(User? user, {ValueChanged<bool>? onAccountResult}) {
  return ProviderScope(
    overrides: [authStateProvider.overrideWith((_) => Stream.value(user))],
    child: MaterialApp(
      routes: {ProPlanScreen.routeName: (_) => const ProPlanScreen()},
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              ElevatedButton(
                key: const ValueKey('limit'),
                onPressed: () => showTierLimitSheet(
                  context,
                  title: 'Daily task limit reached',
                  message: 'The free plan includes 4 tasks per day.',
                ),
                child: const Text('limit'),
              ),
              ElevatedButton(
                key: const ValueKey('account'),
                onPressed: () async {
                  final ok = await ensureAccountFor(
                    context,
                    feature: 'groups',
                  );
                  onAccountResult?.call(ok);
                },
                child: const Text('account'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('showTierLimitSheet (PRD monetization §8)', () {
    testWidgets('signed-in free user: See Pro opens the Pro plan page', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_FakeUser(isAnonymous: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('limit')));
      await tester.pumpAndSettle();

      expect(find.text('Daily task limit reached'), findsOneWidget);
      expect(find.byKey(const ValueKey('tier_sheet_guest_line')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tier_sheet_see_pro')));
      await tester.pumpAndSettle();
      expect(find.byType(ProPlanScreen), findsOneWidget);
    });

    testWidgets('guest: leads with keeping their data, offers Sign in', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_FakeUser(isAnonymous: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('limit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tier_sheet_guest_line')), findsOneWidget);
      expect(find.textContaining("so you don't lose it"), findsOneWidget);
      expect(find.byKey(const ValueKey('tier_sheet_sign_in')), findsOneWidget);
      expect(find.byKey(const ValueKey('tier_sheet_see_pro')), findsNothing);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('Daily task limit reached'), findsNothing);
    });
  });

  group('ensureAccountFor (account-only features)', () {
    testWidgets('an account proceeds with no sheet', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(_FakeUser(isAnonymous: false), onAccountResult: (r) => result = r),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Sign in to use groups'), findsNothing);
    });

    testWidgets('a guest sees the polite sheet; Not now blocks the action', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _host(_FakeUser(isAnonymous: true), onAccountResult: (r) => result = r),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account')));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to use groups'), findsOneWidget);
      expect(find.textContaining('keeps your data safe'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('ProPlanScreen', () {
    test('comparison reads the live limits', () {
      final rows = {
        for (final r in proPlanRows(TierLimits.defaults)) r.feature: r,
      };
      expect(rows['Tasks']!.free, '4 a day');
      expect(rows['Habits']!.free, '4 a day');
      expect(rows['Goals']!.free, '3 active');
      expect(rows['Promises']!.free, '2 a week');
      expect(rows['Coach actions']!.free, '3 a day');
      expect(rows['Stakes']!.free, '1 a month');
      expect(rows['Time logging']!.free, 'Unlimited');
      expect(rows['Time insights + export']!.pro, 'Included');
    });

    testWidgets('purchase is inert until the store ships', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProPlanScreen())),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pro_plan_purchase')),
        200,
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('pro_plan_purchase')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Coming soon'), findsOneWidget);
    });
  });
}
