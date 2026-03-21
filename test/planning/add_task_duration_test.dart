import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/planning/domain/add_task_duration.dart';

void main() {
  group('addTaskDurationMinutes', () {
    test('maps known labels', () {
      expect(addTaskDurationMinutes('15 MIN'), 15);
      expect(addTaskDurationMinutes('25 MIN'), 25);
      expect(addTaskDurationMinutes('45 MIN'), 45);
      expect(addTaskDurationMinutes('1 HOUR'), 60);
    });

    test('defaults for unknown label', () {
      expect(addTaskDurationMinutes('unknown'), 25);
    });
  });

  group('durationLabelFromMinutes', () {
    test('maps to chip labels', () {
      expect(durationLabelFromMinutes(10), '15 MIN');
      expect(durationLabelFromMinutes(20), '25 MIN');
      expect(durationLabelFromMinutes(40), '45 MIN');
      expect(durationLabelFromMinutes(90), '1 HOUR');
    });
  });
}
