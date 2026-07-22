import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAiOperatingLayerClient schedule queries', () {
    test('returns informational answer for tomorrow question', () async {
      const client = MockAiOperatingLayerClient();
      final payload = AiOperatingLayerPayload(
        userInput: 'What is my plan for tomorrow?',
        tomorrowTasks: [
          {
            'title': 'Study',
            'time': '09:00',
            'duration': '25 min',
            'status': 'notStarted',
          },
        ],
        tomorrowSchedule: [
          {
            'title': 'Study',
            'startTime': '09:00',
            'endTime': '09:25',
          },
        ],
      );

      final result = await client.parseIntent(payload);

      expect(result.isInformational, isTrue);
      expect(result.informationalMessage, contains('Study'));
      expect(result.informationalMessage, contains('09:00'));
      expect(result.suggestedPrompts, isNotEmpty);
    });

    test('returns empty schedule message when tomorrow has no tasks', () async {
      const client = MockAiOperatingLayerClient();
      const payload = AiOperatingLayerPayload(
        userInput: 'What\'s on my schedule tomorrow?',
      );

      final result = await client.parseIntent(payload);

      expect(result.responseType, AiResponseType.informational);
      expect(result.informationalMessage, contains('Nothing scheduled'));
    });

    test('returns mutate plan for action requests', () async {
      const client = MockAiOperatingLayerClient();
      const payload = AiOperatingLayerPayload(
        userInput: 'Add workout at 6am tomorrow',
      );

      final result = await client.parseIntent(payload);

      expect(result.isMutate, isTrue);
      expect(result.actions, isNotEmpty);
    });

    test('returns unsupported for circle queries', () async {
      const client = MockAiOperatingLayerClient();
      const payload = AiOperatingLayerPayload(
        userInput: 'What did my circle post?',
      );

      final result = await client.parseIntent(payload);

      expect(result.isUnsupported, isTrue);
      expect(result.informationalMessage, contains('Circles'));
    });

    test('returns suggest plan for planning requests', () async {
      const client = MockAiOperatingLayerClient();
      const payload = AiOperatingLayerPayload(
        userInput: 'Help me plan tomorrow',
      );

      final result = await client.parseIntent(payload);

      expect(result.isSuggest, isTrue);
      expect(result.informationalMessage, contains('Study'));
      expect(result.actions, hasLength(2));
    });
  });
}
