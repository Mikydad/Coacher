/// Task 6.4 — ProactiveSuggestionSection widget tests.
library;

import 'dart:async';

import 'package:coach_for_life/features/ai_assistant/application/ai_assistant_providers.dart';
import 'package:coach_for_life/features/ai_assistant/application/proactive_suggestion_display.dart';
import 'package:coach_for_life/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:coach_for_life/features/ai_assistant/presentation/widgets/proactive_suggestion_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _s1 = ProactiveSuggestion(
  id: '1',
  type: ProactiveSuggestionType.scheduleGap,
  title: 'Free slot',
  description: 'Gap at 10:00',
  preDraftedInput: 'Add goal at 10:00',
  confidence: 0.75,
  generatedAt: DateTime(2026, 5, 23),
);

final _s2 = ProactiveSuggestion(
  id: '2',
  type: ProactiveSuggestionType.goalBehindPace,
  title: 'Behind pace',
  description: 'Catch up',
  preDraftedInput: 'Schedule session',
  confidence: 0.8,
  generatedAt: DateTime(2026, 5, 23),
);

final _s3 = ProactiveSuggestion(
  id: '3',
  type: ProactiveSuggestionType.optimiseOrder,
  title: 'Reorder',
  description: 'Priority inversion',
  preDraftedInput: 'Move tasks',
  confidence: 0.7,
  generatedAt: DateTime(2026, 5, 23),
);

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

Widget _wrap(List<ProactiveSuggestion> suggestions) {
  return ProviderScope(
    overrides: [
      dismissedSuggestionRepositoryProvider
          .overrideWithValue(_NoOpDismissedRepo()),
      proactiveSuggestionsProvider.overrideWith(
        (ref) async => suggestions,
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ProactiveSuggestionSection()),
    ),
  );
}

void main() {
  group('ProactiveSuggestionSection', () {
    testWidgets('3 suggestions → 1 card + show more link', (tester) async {
      await tester.pumpWidget(_wrap([_s1, _s2, _s3]));
      await tester.pumpAndSettle();

      expect(find.text('Free slot'), findsOneWidget);
      expect(find.text('Behind pace'), findsNothing);
      expect(find.text('Reorder'), findsNothing);
      expect(find.text('Show 2 more'), findsOneWidget);
      expect(find.textContaining('Coach'), findsNothing);
    });

    testWidgets('tap show more expands all cards on Home', (tester) async {
      await tester.pumpWidget(_wrap([_s1, _s2, _s3]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show 2 more'));
      await tester.pumpAndSettle();

      expect(find.text('Free slot'), findsOneWidget);
      expect(find.text('Behind pace'), findsOneWidget);
      expect(find.text('Reorder'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('show less collapses back to one card', (tester) async {
      await tester.pumpWidget(_wrap([_s1, _s2, _s3]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show 2 more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      expect(find.text('Free slot'), findsOneWidget);
      expect(find.text('Behind pace'), findsNothing);
      expect(find.text('Show 2 more'), findsOneWidget);
    });

    testWidgets('auto-collapses after idle period', (tester) async {
      await tester.pumpWidget(_wrap([_s1, _s2, _s3]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show 2 more'));
      await tester.pumpAndSettle();
      expect(find.text('Behind pace'), findsOneWidget);

      await tester.pump(kHomeSuggestionsAutoCollapseDuration);
      await tester.pumpAndSettle();

      expect(find.text('Behind pace'), findsNothing);
      expect(find.text('Show 2 more'), findsOneWidget);
    });

    testWidgets('1 suggestion → single card, no expand link', (tester) async {
      await tester.pumpWidget(_wrap([_s1]));
      await tester.pumpAndSettle();

      expect(find.text('Free slot'), findsOneWidget);
      expect(find.textContaining('Show'), findsNothing);
    });

    testWidgets('0 suggestions → section collapses', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      expect(find.text('Free slot'), findsNothing);
      expect(find.byType(ProactiveSuggestionSection), findsOneWidget);
    });

    testWidgets('Loading state → skeleton card shown', (tester) async {
      final neverCompletes = Completer<List<ProactiveSuggestion>>().future;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proactiveSuggestionsProvider.overrideWith((ref) => neverCompletes),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProactiveSuggestionSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProactiveSuggestionSection), findsOneWidget);
      expect(find.text("Let's do it"), findsNothing);
    });
  });
}
