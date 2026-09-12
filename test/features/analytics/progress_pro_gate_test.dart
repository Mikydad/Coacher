import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/presentation/progress/progress_pro_gate.dart';

void main() {
  Widget host({required bool blocked, required VoidCallback onUnlock, required VoidCallback onChildTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ProgressProGate(
          blocked: blocked,
          onUnlock: onUnlock,
          child: SizedBox(
            height: 300,
            child: Center(
              child: ElevatedButton(onPressed: onChildTap, child: const Text('inner')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('unblocked: child is live, no pill', (tester) async {
    var childTaps = 0;
    await tester.pumpWidget(host(blocked: false, onUnlock: () {}, onChildTap: () => childTaps++));
    expect(find.text('Unlock Progress'), findsNothing);
    await tester.tap(find.text('inner'));
    expect(childTaps, 1);
  });

  testWidgets('blocked: pill shown, child taps absorbed, pill opens unlock', (tester) async {
    var childTaps = 0;
    var unlocks = 0;
    await tester.pumpWidget(
      host(blocked: true, onUnlock: () => unlocks++, onChildTap: () => childTaps++),
    );
    expect(find.text('Unlock Progress'), findsOneWidget);
    // The pill sits over the child's centre, so probe the child's corner:
    // absorbed, and not an unlock either.
    await tester.tapAt(tester.getTopLeft(find.byType(ProgressProGate)) + const Offset(12, 12));
    // And the inner button itself, reached through the blur layer.
    await tester.tap(find.text('inner'), warnIfMissed: false);
    expect(childTaps, 0);
    final unlocksBefore = unlocks;
    await tester.tap(find.text('Unlock Progress'));
    expect(unlocks, unlocksBefore + 1);
  });
}
