import 'package:coach_for_life/features/add_task/presentation/add_task_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: the Accountability + Deep Work half-width cards live inside a
/// ListView, where height is unbounded — the pairing row must not stretch
/// into infinite height (crashes layout, then floods semantics assertions).
void main() {
  // Mirrors _buildAccountabilityAndDeepWorkRow in add_task_screen.dart:
  // the IntrinsicHeight wrapper is what keeps the stretch bounded.
  Widget pairedRow() => IntrinsicHeight(
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: AddTaskSplitSettingCard(
          icon: Icons.verified_user_outlined,
          title: 'Accountability',
          subtitle: 'FLEXIBLE · FROM PROFILE',
          onTap: () {},
          trailing: const Text('CHANGE'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: AddTaskSplitSettingCard(
          icon: Icons.bolt_rounded,
          title: 'Deep Work',
          subtitle: 'NOTIFICATION BLACKOUT',
          onTap: () {},
          trailing: Switch.adaptive(value: false, onChanged: (_) {}),
        ),
      ),
    ],
    ),
  );

  testWidgets('paired settings row lays out inside an unbounded ListView', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ListView(children: [pairedRow()])),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Accountability'), findsOneWidget);
    expect(find.text('Deep Work'), findsOneWidget);
  });
}
