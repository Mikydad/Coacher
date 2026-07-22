import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_response_parser.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOperatingLayerJsonMap', () {
    test('parses informational response with suggested prompts', () {
      final result = parseOperatingLayerJsonMap(
        {
          'responseType': 'informational',
          'message': 'Tomorrow you have Study at 9:00.',
          'suggestedPrompts': ['Add a task tomorrow at 2pm'],
        },
        'sess1',
      );

      expect(result.sessionId, 'sess1');
      expect(result.responseType, AiResponseType.informational);
      expect(result.isInformational, isTrue);
      expect(result.informationalMessage, contains('Study'));
      expect(result.suggestedPrompts, ['Add a task tomorrow at 2pm']);
      expect(result.actions, isEmpty);
    });

    test('parses unsupported response', () {
      final result = parseOperatingLayerJsonMap(
        {
          'responseType': 'unsupported',
          'message': 'Community features are not available in Coach AI yet.',
        },
        'sess2',
      );

      expect(result.isUnsupported, isTrue);
      expect(result.informationalMessage, contains('Community'));
    });

    test('parses follow-up question', () {
      final result = parseOperatingLayerJsonMap(
        {
          'responseType': 'followUp',
          'followUpQuestion': 'What time should the workout start?',
        },
        'sess3',
      );

      expect(result.requiresFollowUp, isTrue);
      expect(result.followUpQuestion, contains('time'));
    });

    test('parses mutate plan with actions', () {
      final result = parseOperatingLayerJsonMap(
        {
          'responseType': 'mutate',
          'actions': [
            {
              'actionType': 'createTask',
              'parameters': {
                'title': 'Run',
                'time': '06:00',
                'duration': 30,
                'date': 'tomorrow',
              },
              'confidence': 0.9,
            },
          ],
          'conflicts': [],
        },
        'sess4',
      );

      expect(result.isMutate, isTrue);
      expect(result.actions, hasLength(1));
      expect(result.actions.first.actionType, ActionType.createTask);
    });

    test('legacy empty actions with message becomes informational', () {
      final result = parseOperatingLayerJsonMap(
        {
          'message': 'Nothing scheduled for tomorrow yet.',
          'actions': [],
        },
        'sess5',
      );

      expect(result.isInformational, isTrue);
      expect(result.informationalMessage, contains('Nothing scheduled'));
    });

    test('parses suggest response with draft actions', () {
      final result = parseOperatingLayerJsonMap(
        {
          'responseType': 'suggest',
          'message': 'Tomorrow morning is open. I\'d add Study at 9.',
          'actions': [
            {
              'actionType': 'createTask',
              'parameters': {
                'title': 'Study',
                'time': '09:00',
                'duration': 45,
                'date': 'tomorrow',
              },
              'confidence': 0.9,
            },
          ],
          'suggestedPrompts': ['Apply this plan'],
        },
        'sess6',
      );

      expect(result.isSuggest, isTrue);
      expect(result.informationalMessage, contains('Study'));
      expect(result.actions, hasLength(1));
      expect(result.suggestedPrompts, ['Apply this plan']);
    });
  });
}
