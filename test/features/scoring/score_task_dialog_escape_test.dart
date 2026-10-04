import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/scoring/presentation/score_task_dialog.dart';

/// Regression (Miko, 2026-09-27): in Extreme a mistaken End opened a rating
/// card with no way out. Strict modes now ask "Leave without rating?"
/// instead of trapping; flexible still leaves at once.
void main() {
  late ScoreTaskDialogResult? result;
  late bool closed;

  Future<void> open(WidgetTester tester, {required bool strict}) async {
    closed = false;
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ScoreTaskDialog.show(
                  context,
                  taskTitle: 'Write proposal',
                  requireSubmit: strict,
                  requireReasonAlways: strict,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsOneWidget);
  }

  Future<void> tapOutside(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  }

  testWidgets('strict: tapping outside asks first; "Rate it" stays', (
    tester,
  ) async {
    await open(tester, strict: true);
    await tapOutside(tester);

    expect(find.text('Leave without rating?'), findsOneWidget);
    await tester.tap(find.text('Rate it'));
    await tester.pumpAndSettle();

    expect(find.text('Leave without rating?'), findsNothing);
    expect(find.text('Score Task'), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('strict: "Leave without rating" closes with no score', (
    tester,
  ) async {
    await open(tester, strict: true);
    await tapOutside(tester);
    await tester.tap(find.text('Leave without rating'));
    await tester.pumpAndSettle();

    expect(find.text('Score Task'), findsNothing);
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('strict: the visible "Not now" asks the same question', (
    tester,
  ) async {
    await open(tester, strict: true);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Leave without rating?'), findsOneWidget);
  });

  testWidgets('strict: Save still records a score (reason required)', (
    tester,
  ) async {
    await open(tester, strict: true);
    await tester.enterText(find.byType(TextField), 'Got interrupted');
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result?.completionPercent, 100);
    expect(result?.reason, 'Got interrupted');
  });

  testWidgets('flexible: tapping outside leaves at once, no question', (
    tester,
  ) async {
    await open(tester, strict: false);
    await tapOutside(tester);

    expect(find.text('Leave without rating?'), findsNothing);
    expect(closed, isTrue);
    expect(result, isNull);
  });
}
