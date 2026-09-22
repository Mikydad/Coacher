import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_providers.dart';
import 'package:sidepal/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:sidepal/features/analytics/presentation/progress/day_suggestions_card.dart';

class _NoOpDismissedRepo implements DismissedSuggestionRepository {
  @override
  Future<void> logDismissal(ProactiveSuggestionType type) async {}
  @override
  Future<int> countDismissals(
    ProactiveSuggestionType type, {
    int withinDays = 7,
  }) async => 0;
  @override
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async => {};
  @override
  Future<Set<ProactiveSuggestionType>> typesDismissedToday() async => {};
  @override
  Future<void> purgeOldEntries({int olderThanDays = 7}) async {}
}

final _suggestions = [
  ProactiveSuggestion(
    id: 'a',
    type: ProactiveSuggestionType.scheduleGap,
    title: 'Gap A',
    description: 'Desc A',
    preDraftedInput: 'input A',
    confidence: 0.9,
    generatedAt: DateTime(2026, 5, 23),
  ),
  ProactiveSuggestion(
    id: 'b',
    type: ProactiveSuggestionType.goalBehindPace,
    title: 'Gap B',
    description: 'Desc B',
    preDraftedInput: 'input B',
    confidence: 0.8,
    generatedAt: DateTime(2026, 5, 23),
  ),
];

Future<void> _pump(
  WidgetTester tester,
  List<ProactiveSuggestion> suggestions,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dismissedSuggestionRepositoryProvider.overrideWithValue(
          _NoOpDismissedRepo(),
        ),
        proactiveSuggestionsProvider.overrideWith((ref) async => suggestions),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DaySuggestionsCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Progress DAY view hosts the suggestions (2026-09-22): collapsed to one
/// line by default, tap to expand, nothing when there is nothing active.
void main() {
  testWidgets('collapsed by default: header + count, no cards', (tester) async {
    await _pump(tester, _suggestions);
    expect(find.text('SUGGESTIONS FOR TODAY'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Gap A'), findsNothing);
    expect(find.text('Gap B'), findsNothing);
  });

  testWidgets('tapping the header expands the cards, tapping again collapses', (
    tester,
  ) async {
    await _pump(tester, _suggestions);
    await tester.tap(find.byKey(DaySuggestionsCard.headerKey));
    await tester.pumpAndSettle();
    expect(find.text('Gap A'), findsOneWidget);
    expect(find.text('Gap B'), findsOneWidget);

    await tester.tap(find.byKey(DaySuggestionsCard.headerKey));
    await tester.pumpAndSettle();
    expect(find.text('Gap A'), findsNothing);
  });

  testWidgets('renders nothing when there are no active suggestions', (
    tester,
  ) async {
    await _pump(tester, const []);
    expect(find.text('SUGGESTIONS FOR TODAY'), findsNothing);
  });
}
