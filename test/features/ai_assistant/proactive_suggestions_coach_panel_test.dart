import 'package:coach_for_life/features/ai_assistant/application/ai_assistant_providers.dart';
import 'package:coach_for_life/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:coach_for_life/features/ai_assistant/presentation/widgets/proactive_suggestions_coach_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoOpDismissedRepo implements DismissedSuggestionRepository {
  @override
  Future<void> logDismissal(ProactiveSuggestionType type) async {}

  @override
  Future<int> countDismissals(
    ProactiveSuggestionType type, {
    int withinDays = 7,
  }) async =>
      0;

  @override
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async => {};

  @override
  Future<void> purgeOldEntries({int olderThanDays = 7}) async {}
}

void main() {
  testWidgets('Coach panel lists all active suggestions', (tester) async {
    final suggestions = [
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dismissedSuggestionRepositoryProvider
              .overrideWithValue(_NoOpDismissedRepo()),
          proactiveSuggestionsProvider.overrideWith((ref) async => suggestions),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProactiveSuggestionsCoachPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUGGESTIONS FOR TODAY'), findsOneWidget);
    expect(find.text('Gap A'), findsOneWidget);
    expect(find.text('Gap B'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
