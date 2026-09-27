import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/timer/presentation/focus_stage.dart';

void main() {
  testWidgets('celebration shows the task, focus minutes and Continue', (
    tester,
  ) async {
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FocusCelebration(
              ringSize: 240,
              taskLabel: 'Write the landing page',
              focusedMinutes: 25,
              onContinue: () => continued++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task done!'), findsOneWidget);
    expect(find.text('Write the landing page'), findsOneWidget);
    expect(find.text('25 min of focus'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('under a minute of focus hides the minutes chip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FocusCelebration(
              ringSize: 240,
              taskLabel: 'Quick one',
              focusedMinutes: 0,
              onContinue: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('min of focus'), findsNothing);
  });
}
