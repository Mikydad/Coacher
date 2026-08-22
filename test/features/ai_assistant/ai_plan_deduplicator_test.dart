import 'package:sidepal/features/ai_assistant/application/ai_plan_deduplicator.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const activeTasks = [
    {
      'title': 'meeting',
      'time': '17:00',
      'duration': '30 min',
      'status': 'notStarted',
    },
  ];

  group('AiPlanDeduplicator', () {
    test('drops addReminder for task already scheduled at same time', () {
      final actions = [
        AiAction(
          actionType: ActionType.addReminder,
          parameters: {
            'taskTitle': 'meeting',
            'reminderTime': '17:00',
            'date': 'today',
          },
        ),
        AiAction(
          actionType: ActionType.addReminder,
          parameters: {
            'taskTitle': 'take a supliment',
            'reminderTime': '15:00',
            'date': 'today',
          },
        ),
      ];

      final filtered = AiPlanDeduplicator.filter(
        actions,
        activeTasks,
        'add take a supliment reminder at 3pm',
      );

      expect(filtered, hasLength(1));
      expect(
        filtered.first.parameters['taskTitle'],
        equals('take a supliment'),
      );
    });

    test('keeps addReminder when user explicitly names that task', () {
      final actions = [
        AiAction(
          actionType: ActionType.addReminder,
          parameters: {
            'taskTitle': 'meeting',
            'reminderTime': '18:00',
            'date': 'today',
          },
        ),
      ];

      final filtered = AiPlanDeduplicator.filter(
        actions,
        activeTasks,
        'move the meeting reminder to 6pm',
      );

      expect(filtered, hasLength(1));
    });

    test('drops createTask when title already on today', () {
      final actions = [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {'title': 'meeting', 'time': '17:00', 'date': 'today'},
        ),
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'take a supliment',
            'time': '15:00',
            'date': 'today',
          },
        ),
      ];

      final filtered = AiPlanDeduplicator.filter(
        actions,
        activeTasks,
        'add supplement at 3pm',
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.parameters['title'], equals('take a supliment'));
    });

    test('does not filter when refining previous plan', () {
      final actions = [
        AiAction(
          actionType: ActionType.addReminder,
          parameters: {
            'taskTitle': 'meeting',
            'reminderTime': '17:00',
          },
        ),
      ];

      final filtered = AiPlanDeduplicator.filter(
        actions,
        activeTasks,
        'keep meeting',
        isRefiningPreviousPlan: true,
      );

      expect(filtered, hasLength(1));
    });

    // 2026-08-22 bug batch: exact-match dedup let cosmetic title variants
    // through and duplicates piled up on the task list.
    group('fuzzy title identity', () {
      test('drops createTask whose title differs only in punctuation/case',
          () {
        final actions = [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'create flutter todo list',
              'time': '06:50',
              'duration': 45,
              'date': 'today',
            },
          ),
        ];

        final filtered = AiPlanDeduplicator.filter(
          actions,
          [
            {'title': 'Create Flutter to-do list', 'time': '06:50'},
          ],
          'no that is it',
        );

        expect(filtered, isEmpty);
      });

      test('drops createTask whose title has a small typo of an existing one',
          () {
        final actions = [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'Finish the app errors',
              'time': '09:00',
              'duration': 30,
              'date': 'today',
            },
          ),
        ];

        final filtered = AiPlanDeduplicator.filter(
          actions,
          [
            {'title': 'finish the app erros', 'time': '09:00'},
          ],
          'ok',
        );

        expect(filtered, isEmpty);
      });

      test('keeps genuinely different short titles', () {
        final actions = [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'Run',
              'time': '06:00',
              'duration': 30,
              'date': 'today',
            },
          ),
        ];

        final filtered = AiPlanDeduplicator.filter(
          actions,
          [
            {'title': 'Rest', 'time': '21:00'},
          ],
          'add a run at 6',
        );

        expect(filtered, hasLength(1));
      });

      test('dedupes near-identical createTask actions WITHIN one plan', () {
        final actions = [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'Create Flutter to-do list',
              'time': '06:50',
              'duration': 45,
              'date': 'today',
            },
          ),
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'create flutter todo list',
              'time': '06:50',
              'duration': 45,
              'date': 'today',
            },
          ),
        ];

        final filtered = AiPlanDeduplicator.filter(
          actions,
          const [],
          'plan my morning',
        );

        expect(filtered, hasLength(1));
        expect(
          filtered.single.parameters['title'],
          'Create Flutter to-do list',
        );
      });
    });
  });
}
