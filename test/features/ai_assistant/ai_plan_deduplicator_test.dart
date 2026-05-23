import 'package:coach_for_life/features/ai_assistant/application/ai_plan_deduplicator.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
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
  });
}
