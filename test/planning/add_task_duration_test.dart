import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/planning/domain/add_task_duration.dart';

void main() {
  group('addTaskDurationMinutes', () {
    test('maps known labels', () {
      expect(addTaskDurationMinutes('15 MIN'), 15);
      expect(addTaskDurationMinutes('25 MIN'), 25);
      expect(addTaskDurationMinutes('45 MIN'), 45);
      expect(addTaskDurationMinutes('1 HOUR'), 60);
      expect(addTaskDurationMinutes('6 HOURS'), 360);
      expect(addTaskDurationMinutes('7 HOURS'), 420);
      expect(addTaskDurationMinutes('8 HOURS'), 480);
    });

    test('custom uses provided minutes', () {
      expect(
        addTaskDurationMinutes('CUSTOM', customMinutes: 90),
        90,
      );
      expect(
        addTaskDurationMinutes('CUSTOM', customMinutes: 150),
        150,
      );
    });

    test('defaults for unknown label', () {
      expect(addTaskDurationMinutes('unknown'), 25);
    });
  });

  group('durationLabelFromMinutes', () {
    test('maps to chip labels', () {
      expect(durationLabelFromMinutes(15), '15 MIN');
      expect(durationLabelFromMinutes(25), '25 MIN');
      expect(durationLabelFromMinutes(45), '45 MIN');
      expect(durationLabelFromMinutes(60), '1 HOUR');
    });

    test('non-preset maps to custom', () {
      expect(durationLabelFromMinutes(90), kAddTaskCustomDurationKey);
      expect(durationLabelFromMinutes(120), kAddTaskCustomDurationKey);
    });

    test('maps sleep durations when category is Sleep', () {
      expect(durationLabelFromMinutes(360, category: 'Sleep'), '6 HOURS');
      expect(durationLabelFromMinutes(420, category: 'Sleep'), '7 HOURS');
      expect(durationLabelFromMinutes(480, category: 'Sleep'), '8 HOURS');
    });
  });

  group('formatAddTaskDurationChipLabel', () {
    test('formats minutes and hours', () {
      expect(formatAddTaskDurationChipLabel(45), '45m');
      expect(formatAddTaskDurationChipLabel(60), '1h');
      expect(formatAddTaskDurationChipLabel(90), '1h 30m');
    });
  });
}
