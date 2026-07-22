import 'package:sidepal/features/ai_assistant/application/ai_chat_suggestion_enricher.dart';
import 'package:sidepal/features/ai_assistant/application/ai_schedule_answer_formatter.dart';
import 'package:sidepal/features/ai_assistant/application/proactive_chat_conversion_tracker.dart';
import 'package:sidepal/features/ai_assistant/application/proactive_suggestion_source.dart';
import 'package:sidepal/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements ProactiveSuggestionSource {
  _FakeEngine(this._suggestions);

  final List<ProactiveSuggestion> _suggestions;

  @override
  Future<List<ProactiveSuggestion>> generateForToday() async => _suggestions;
}

class _FakeDismissedRepo implements DismissedSuggestionRepository {
  _FakeDismissedRepo(this._suppressed);

  final Set<ProactiveSuggestionType> _suppressed;

  @override
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async => _suppressed;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('AiChatSuggestionEnricher', () {
    test('returns proactive prompts when tomorrow is empty', () async {
      const payload = AiOperatingLayerPayload(
        userInput: 'What is my plan for tomorrow?',
        tomorrowTasks: [],
        tomorrowSchedule: [],
      );

      final enricher = AiChatSuggestionEnricher(
        proactiveEngine: _FakeEngine([
          ProactiveSuggestion(
            id: 's1',
            type: ProactiveSuggestionType.scheduleGap,
            title: 'Gap',
            description: 'Free time',
            preDraftedInput: 'Schedule study at 9am tomorrow',
            confidence: 0.9,
            generatedAt: DateTime(2026, 1, 1),
          ),
        ]),
        dismissedRepo: _FakeDismissedRepo({}),
      );

      final prompts = await enricher.promptsForInformationalGaps(payload);

      expect(prompts, ['Schedule study at 9am tomorrow']);
    });

    test('skips dismissed suggestion types', () async {
      const payload = AiOperatingLayerPayload(
        userInput: 'What is on tomorrow?',
        tomorrowTasks: [],
        tomorrowSchedule: [],
      );

      final enricher = AiChatSuggestionEnricher(
        proactiveEngine: _FakeEngine([
          ProactiveSuggestion(
            id: 's1',
            type: ProactiveSuggestionType.scheduleGap,
            title: 'Gap',
            description: 'Free time',
            preDraftedInput: 'Schedule study at 9am tomorrow',
            confidence: 0.9,
            generatedAt: DateTime(2026, 1, 1),
          ),
        ]),
        dismissedRepo: _FakeDismissedRepo({ProactiveSuggestionType.scheduleGap}),
      );

      final prompts = await enricher.promptsForInformationalGaps(payload);

      expect(prompts, isEmpty);
    });
  });

  group('AiScheduleAnswerFormatter', () {
    test('formats week overview from payload', () {
      const payload = AiOperatingLayerPayload(
        userInput: 'What does my week look like?',
        weekOverview: [
          {'label': 'today', 'date': '2026-06-16', 'taskCount': 2, 'scheduledCount': 1},
          {'label': 'tomorrow', 'date': '2026-06-17', 'taskCount': 0, 'scheduledCount': 0},
        ],
      );

      final answer = AiScheduleAnswerFormatter.tryAnswerScheduleQuery(payload);

      expect(answer, isNotNull);
      expect(answer, contains('week at a glance'));
      expect(answer, contains('2 tasks'));
    });

    test('formats goal progress with coaching tone', () {
      const payload = AiOperatingLayerPayload(
        userInput: 'How am I doing on my goals?',
        goalProgress: [
          {
            'title': 'Reading',
            'target': '30 pages',
            'daysMet': 3,
            'daysElapsed': 5,
            'totalDays': 30,
            'periodSummary': 'Jun 2026',
          },
        ],
        behaviorPreferences: {'coachingStyle': 'supportive'},
      );

      final answer = AiScheduleAnswerFormatter.tryAnswerScheduleQuery(payload);

      expect(answer, contains('Reading'));
      expect(answer, contains('3/30 pages'));
      expect(answer, contains('Keep showing up'));
    });
  });

  group('ProactiveChatConversionTracker', () {
    test('records conversions by type', () {
      ProactiveChatConversionTracker.conversionsByType.clear();
      ProactiveChatConversionTracker.record('scheduleGap');
      ProactiveChatConversionTracker.record('scheduleGap');

      expect(ProactiveChatConversionTracker.snapshot()['scheduleGap'], 2);
    });
  });
}
