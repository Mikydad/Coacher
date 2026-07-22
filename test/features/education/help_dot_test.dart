import 'package:sidepal/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:sidepal/features/education/presentation/help_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String guideId) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: Center(child: HelpDot(guideId)))),
);

void main() {
  testWidgets('tap opens the sheet with title, oneLiner, and steps', (
    tester,
  ) async {
    await tester.pumpWidget(_host('flowNow'));
    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    expect(find.text('🌊  Flow Now'), findsOneWidget);
    expect(
      find.text('The one task you should be doing right now.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('1.'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('HOW TO USE IT'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
  });

  testWidgets('topics without steps render no HOW section', (tester) async {
    await tester.pumpWidget(_host('taskIntegrity'));
    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    expect(find.text('🧭  Task Integrity'), findsOneWidget);
    expect(find.text('WHY IT MATTERS'), findsOneWidget);
    expect(find.text('HOW TO USE IT'), findsNothing);
  });

  testWidgets('unknown guide id is a silent no-op', (tester) async {
    await tester.pumpWidget(_host('doesNotExist'));
    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    expect(find.text('WHY IT MATTERS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ask Coach opens the coach sheet over the current page', (
    tester,
  ) async {
    await tester.pumpWidget(_host('flowNow'));
    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ask Coach about this'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Ask Coach about this'));
    // No pumpAndSettle: the coach screen shows a loading spinner in this
    // bare test host, which animates forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Coach is a sheet now (decision log 2026-07-16): the help sheet pops
    // and the coach sheet presents with the prefill in its route args.
    expect(find.byType(AiAssistantScreen), findsOneWidget);
    final route = ModalRoute.of(
      tester.element(find.byType(AiAssistantScreen)),
    );
    expect(route?.settings.name, AiAssistantScreen.routeName);
    final args = route?.settings.arguments;
    expect(args, isA<CoachRouteArgs>());
    expect(
      (args as CoachRouteArgs).preDraftedText,
      'Tell me about Flow Now',
    );
  });
}
