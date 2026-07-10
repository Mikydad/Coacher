import 'package:coach_for_life/app/application/main_tab_navigation.dart';
import 'package:coach_for_life/features/education/presentation/help_dot.dart';
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

  testWidgets('Ask Coach prefills the coach tab deep link', (tester) async {
    await tester.pumpWidget(_host('flowNow'));
    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ask Coach about this'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Ask Coach about this'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(container.read(mainTabIndexProvider), MainTabIndex.coach);
    expect(
      container.read(coachTabArgsProvider)?.preDraftedText,
      'Tell me about Flow Now',
    );
  });
}
