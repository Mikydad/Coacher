import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/presentation/intention_quick_add_sheet.dart';

/// Regression (Miko, 2026-09-27): the new-promise sheet overflowed on a
/// small phone with the keyboard up — a fixed Column with the keyboard's
/// height as padding and nothing to scroll.
void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Size size,
    required double keyboard,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showIntentionQuickAddSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('fits a small phone with the keyboard up', (tester) async {
    await openSheet(tester, size: const Size(320, 568), keyboard: 260);
    expect(tester.takeException(), isNull);
    expect(find.text('Find me a good time'), findsOneWidget);
  });

  testWidgets('fits an iPhone 13 mini with the keyboard up', (tester) async {
    await openSheet(tester, size: const Size(375, 812), keyboard: 336);
    expect(tester.takeException(), isNull);
  });
}
