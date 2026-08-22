import 'package:sidepal/features/ai_assistant/application/ai_action_param_normaliser.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:flutter_test/flutter_test.dart';

AiAction _task(Map<String, dynamic> params) =>
    AiAction(actionType: ActionType.createTask, parameters: params);

void main() {
  group('alias keys', () {
    test('startTime fills time; durationMinutes fills duration', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'Workout', 'startTime': '14:00', 'durationMinutes': 60}),
      );
      expect(n.parameters['time'], '14:00');
      expect(n.parameters['duration'], 60);
    });

    test('canonical keys are never stomped by aliases', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': '09:00', 'startTime': '14:00'}),
      );
      expect(n.parameters['time'], '09:00');
    });

    test('moveTask title alias fills taskTitle', () {
      final n = AiActionParamNormaliser.normalise(
        AiAction(
          actionType: ActionType.moveTask,
          parameters: {'title': 'Workout', 'date': 'tomorrow'},
        ),
      );
      expect(n.parameters['taskTitle'], 'Workout');
      expect(n.parameters['destinationDate'], 'tomorrow');
    });

    test('reminder time alias + canonicalization', () {
      final n = AiActionParamNormaliser.normalise(
        AiAction(
          actionType: ActionType.addReminder,
          parameters: {'title': 'Workout', 'time': '2 pm'},
        ),
      );
      expect(n.parameters['taskTitle'], 'Workout');
      expect(n.parameters['reminderTime'], '14:00');
    });
  });

  group('time value canonicalization', () {
    test('12-hour forms become HH:mm', () {
      for (final (raw, expected) in [
        ('2 pm', '14:00'),
        ('2pm', '14:00'),
        ('2.30pm', '14:30'),
        ('02:00 PM', '14:00'),
        ('12 am', '00:00'),
        ('12 pm', '12:00'),
        ('14:00', '14:00'),
      ]) {
        final n = AiActionParamNormaliser.normalise(
          _task({'title': 'A', 'time': raw}),
        );
        expect(n.parameters['time'], expected, reason: 'raw=$raw');
      }
    });

    test('a bare ambiguous hour is left untouched, never guessed', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': '2'}),
      );
      expect(n.parameters['time'], '2');
    });

    test('digit-less junk time values are dropped, not kept', () {
      // Model drift produced reminderTime "min", which passed the
      // missing-field check and rendered as "… at min" (2026-08-22).
      final reminder = AiActionParamNormaliser.normalise(
        const AiAction(
          actionType: ActionType.addReminder,
          parameters: {'taskTitle': 'Workout', 'reminderTime': 'min'},
        ),
      );
      expect(reminder.parameters.containsKey('reminderTime'), isFalse);

      final task = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': 'morning ish'}),
      );
      expect(task.parameters.containsKey('time'), isFalse);
    });

    test('a range yields start time AND derives duration', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': '14:00–15:00'}),
      );
      expect(n.parameters['time'], '14:00');
      expect(n.parameters['duration'], 60);
    });

    test('range with trailing meridiem only: start inherits it', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': '2-3pm'}),
      );
      expect(n.parameters['time'], '14:00');
      expect(n.parameters['duration'], 60);
    });

    test('range never overrides an explicit duration', () {
      final n = AiActionParamNormaliser.normalise(
        _task({'title': 'A', 'time': '14:00-15:00', 'duration': 25}),
      );
      expect(n.parameters['duration'], 25);
    });
  });

  group('duration value parsing', () {
    test('string forms become minutes ints', () {
      for (final (raw, expected) in [
        ('90', 90),
        ('90 min', 90),
        ('45 minutes', 45),
        ('1.5 hours', 90),
        ('1h', 60),
      ]) {
        final n = AiActionParamNormaliser.normalise(
          _task({'title': 'A', 'time': '09:00', 'duration': raw}),
        );
        expect(n.parameters['duration'], expected, reason: 'raw=$raw');
      }
    });
  });

  group('free-text answer extraction', () {
    test('time answers', () {
      expect(AiActionParamNormaliser.extractTimeAnswer('At 2 pm'), '14:00');
      expect(AiActionParamNormaliser.extractTimeAnswer('2 pm'), '14:00');
      expect(
        AiActionParamNormaliser.extractTimeAnswer('14:30 works for me'),
        '14:30',
      );
      expect(AiActionParamNormaliser.extractTimeAnswer('perfect'), isNull);
    });

    test('duration answers', () {
      expect(AiActionParamNormaliser.extractDurationAnswer('30 minutes'), 30);
      expect(AiActionParamNormaliser.extractDurationAnswer('an hour'), 60);
      expect(
        AiActionParamNormaliser.extractDurationAnswer(
          '45',
          bareNumberIsMinutes: true,
        ),
        45,
      );
      expect(AiActionParamNormaliser.extractDurationAnswer('45'), isNull);
    });

    test('date answers', () {
      expect(AiActionParamNormaliser.extractDateAnswer('tomorrow please'),
          'tomorrow');
      expect(AiActionParamNormaliser.extractDateAnswer('today'), 'today');
      expect(AiActionParamNormaliser.extractDateAnswer('on friday'), isNull);
    });
  });

  group('looksPlanShapedProse', () {
    test('matches the degraded plan bubbles from the bug report', () {
      expect(
        looksPlanShapedProse(
          "Here's the plan — confirm below:\n• Workout Session: 14:00–15:00",
        ),
        isTrue,
      );
      expect(
        looksPlanShapedProse(
          "Here's the plan for your workout at 2 PM today. Ready to confirm this?",
        ),
        isTrue,
      );
    });

    test('never matches schedule answers or chit-chat', () {
      expect(looksPlanShapedProse('Tomorrow you have Study at 9:00.'), isFalse);
      expect(
        looksPlanShapedProse("I'm doing well, thanks for asking!"),
        isFalse,
      );
      expect(
        looksPlanShapedProse('A good plan is to study in the morning.'),
        isFalse,
      );
    });
  });
}
