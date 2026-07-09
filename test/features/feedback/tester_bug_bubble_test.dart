import 'package:coach_for_life/features/feedback/application/tester_mode_controller.dart';
import 'package:coach_for_life/features/feedback/presentation/tester_bug_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedTesterMode extends TesterModeController {
  _FixedTesterMode(bool value) {
    state = value;
  }
}

Widget _host({required bool testerMode}) => ProviderScope(
  overrides: [
    testerModeProvider.overrideWith((ref) => _FixedTesterMode(testerMode)),
  ],
  child: MaterialApp(
    builder: (context, child) => Stack(
      textDirection: TextDirection.ltr,
      children: [?child, const TesterBugBubbleLayer()],
    ),
    home: const Scaffold(body: Center(child: Text('content'))),
  ),
);

void main() {
  testWidgets('bubble is visible when tester mode is on', (tester) async {
    await tester.pumpWidget(_host(testerMode: true));
    await tester.pump();
    expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);
  });

  testWidgets('bubble is absent when tester mode is off', (tester) async {
    await tester.pumpWidget(_host(testerMode: false));
    await tester.pump();
    expect(find.byIcon(Icons.bug_report_rounded), findsNothing);
  });

  testWidgets('bubble survives a tap (hide-for-capture must not dispose it)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(testerMode: true));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bug_report_rounded));
    await tester.pumpAndSettle();

    // Regression: hide-for-capture used to REMOVE the bubble from the tree,
    // disposing the state mid-flow — the hidden flag never reset and the
    // bubble vanished until the next app launch.
    expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);
  });

  testWidgets('bubble can be dragged and snaps to an edge', (tester) async {
    await tester.pumpWidget(_host(testerMode: true));
    await tester.pump();

    final bubble = find.byIcon(Icons.bug_report_rounded);
    final before = tester.getCenter(bubble);
    // Cross the horizontal midline so the edge-snap lands on the LEFT.
    await tester.drag(bubble, const Offset(-500, -100));
    await tester.pump();

    final after = tester.getCenter(bubble);
    expect(after, isNot(before));
    // Snapped to the left edge: 8px margin + 24px half-size.
    expect(after.dx, 8 + 24);
  });
}
