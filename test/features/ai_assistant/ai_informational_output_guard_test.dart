import 'package:coach_for_life/features/ai_assistant/application/ai_informational_output_guard.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_schedule_answer_formatter.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiInformationalOutputGuard', () {
    test('passes clean schedule summaries through unchanged', () {
      const text = "Here's your plan for tomorrow:\n• Study 09:00–09:45";
      expect(AiInformationalOutputGuard.looksLikeInternalLeak(text), isFalse);
      expect(AiInformationalOutputGuard.sanitize(text), equals(text));
    });

    test('detects internal field names', () {
      const text = 'Your periodStartMs is 1234567890';
      expect(AiInformationalOutputGuard.looksLikeInternalLeak(text), isTrue);
      expect(
        AiInformationalOutputGuard.sanitize(text),
        isNot(contains('periodStartMs')),
      );
    });

    test('detects UUID-like identifiers', () {
      const text = 'Task abcdef12-3456-7890-abcd-ef1234567890 is scheduled';
      expect(AiInformationalOutputGuard.looksLikeInternalLeak(text), isTrue);
    });
  });

  group('formatter output safety', () {
    test('schedule and goal formatters avoid internal tokens', () {
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
        weekOverview: [
          {'label': 'today', 'date': '2026-06-16', 'taskCount': 2, 'scheduledCount': 1},
        ],
      );

      final goalAnswer =
          AiScheduleAnswerFormatter.tryAnswerScheduleQuery(payload);
      expect(goalAnswer, isNotNull);
      expect(AiInformationalOutputGuard.looksLikeInternalLeak(goalAnswer!), isFalse);

      const weekPayload = AiOperatingLayerPayload(
        userInput: 'What does my week look like?',
        weekOverview: [
          {'label': 'today', 'date': '2026-06-16', 'taskCount': 1, 'scheduledCount': 1},
        ],
      );
      final weekAnswer =
          AiScheduleAnswerFormatter.tryAnswerScheduleQuery(weekPayload);
      expect(weekAnswer, isNotNull);
      expect(AiInformationalOutputGuard.looksLikeInternalLeak(weekAnswer!), isFalse);
    });
  });
}
