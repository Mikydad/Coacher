import 'package:sidepal/features/scoring/presentation/score_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the dialog and leaves it showing; the returned record's `result`
/// getter reads whatever `show` eventually resolved to.
Future<ScoreTaskDialogResult? Function()> _open(
  WidgetTester tester, {
  bool requireSubmit = false,
  bool requireReasonAlways = false,
  int initialPercent = 100,
  int reasonThresholdPercent = 100,
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
                initialPercent: initialPercent,
                reasonThresholdPercent: reasonThresholdPercent,
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
  return () => result;
}

void main() {
  testWidgets('flexible: tap outside dismisses and returns null', (
    tester,
  ) async {
    await _open(tester);
    await tester.tapAt(const Offset(5, 5)); // barrier
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
  });

  testWidgets('flexible: shows Cancel button', (tester) async {
    await _open(tester);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('requireSubmit: outside tap does not dismiss, no Cancel button', (
    tester,
  ) async {
    await _open(tester, requireSubmit: true);
    expect(find.text('Cancel'), findsNothing);
    await tester.tapAt(const Offset(5, 5)); // barrier — should be inert
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsOneWidget);
  });

  testWidgets('requireSubmit: Save at default 100% closes the card', (
    tester,
  ) async {
    await _open(tester, requireSubmit: true);
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
  });

  testWidgets('requireReasonAlways: Save at 100% without reason is blocked', (
    tester,
  ) async {
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

  testWidgets('initialPercent pre-fills the slider readout', (tester) async {
    await _open(tester, initialPercent: 50, reasonThresholdPercent: 80);
    expect(find.text('Completion: 50%'), findsOneWidget);
  });

  testWidgets('at or above the threshold there is no reason field', (
    tester,
  ) async {
    final result = await _open(
      tester,
      initialPercent: 90,
      reasonThresholdPercent: 80,
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('Score Task'), findsNothing);
    expect(result()?.completionPercent, 90);
    expect(result()?.reason, isNull);
  });

  testWidgets('below the threshold the reason is shown and required', (
    tester,
  ) async {
    await _open(tester, initialPercent: 50, reasonThresholdPercent: 80);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Reason (required below 80%)'), findsOneWidget);
    await tester.tap(find.text('Save Score'));
    await tester.pumpAndSettle();
    expect(find.text('Reason is required below 80%.'), findsOneWidget);
    expect(find.text('Score Task'), findsOneWidget);
  });

  testWidgets('mode thresholds mirror the streak bar', (tester) async {
    expect(ScoreTaskDialog.reasonThresholdForMode('flexible'), 80);
    expect(ScoreTaskDialog.reasonThresholdForMode('disciplined'), 90);
    expect(ScoreTaskDialog.reasonThresholdForMode('extreme'), 100);
    expect(ScoreTaskDialog.reasonThresholdForMode('unknown'), 80);
  });
}
