import 'package:coach_for_life/features/education/presentation/first_time_feature_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({String guideId = 'focus'}) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: FirstTimeFeatureCard(guideId: guideId)),
    // The tasks guide's '/add-task' is special-cased to a bottom sheet in
    // _tryIt, so the routed branch is exercised with the focus guide.
    routes: {'/focus': (_) => const Scaffold(body: Text('FOCUS PAGE'))},
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders nothing until prefs load, then shows the guide', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    // First frame: seen-set still null → hidden.
    expect(find.text('Focus Sessions'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Focus Sessions'), findsOneWidget);
    expect(
      find.text('A distraction-free timer for one task at a time.'),
      findsOneWidget,
    );
  });

  testWidgets('stays hidden when already seen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'education_seen_cards_v1': ['focus'],
    });
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Focus Sessions'), findsNothing);
  });

  testWidgets('More expands the what/how content', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Deep work happens'), findsNothing);
    expect(find.textContaining('Focus starts a timed session'), findsOneWidget);
  });

  testWidgets('Got it hides the card and persists', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Sessions'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('education_seen_cards_v1'), contains('focus'));
  });

  testWidgets('Try it marks seen and navigates to the guide route', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Focus Sessions'), findsOneWidget);

    await tester.tap(find.text('Try it'));
    await tester.pumpAndSettle();

    expect(find.text('FOCUS PAGE'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('education_seen_cards_v1'), contains('focus'));
  });
}
