import 'package:sidepal/features/scoring/presentation/score_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ScoreTaskDialogResult?> _open(
  WidgetTester tester, {
  bool requireSubmit = false,
  bool requireReasonAlways = false,
}) async {
  ScoreTaskDialogResult? result;
  var completed = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () async {
              result = await ScoreTaskDialog.show(
                context,
                taskTitle: 'Write report',
                requireSubmit: requireSubmit,
                requireReasonAlways: requireReasonAlways,
              );
              completed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(completed, isFalse);
  return result;
}

void main() {
  testWidgets('flexible: tap outside dismisses and returns null',
      (tester) async {
    await _open(tester);
    await tester.tapAt(const Offset(5, 5)); // barrier
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
  });

  testWidgets('flexible: shows Cancel button', (tester) async {
    await _open(tester);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('requireSubmit: outside tap does not dismiss, no Cancel button',
      (tester) async {
    await _open(tester, requireSubmit: true);
    expect(find.text('Cancel'), findsNothing);
    await tester.tapAt(const Offset(5, 5)); // barrier — should be inert
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsOneWidget);
  });

  testWidgets('requireSubmit: Save at default 100% closes the card',
      (tester) async {
    await _open(tester, requireSubmit: true);
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
  });

  testWidgets('requireReasonAlways: Save at 100% without reason is blocked',
      (tester) async {
    await _open(tester, requireSubmit: true, requireReasonAlways: true);
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('A reason is required in extreme mode.'), findsOneWidget);
    expect(find.text('Score Task'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Deep session, done.');
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
  });
}
