import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/planning/application/task_schedule_display.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';

PlannedTask _sleepTask({
  required String reminderTimeIso,
  int durationMinutes = 8 * 60,
}) {
  return PlannedTask(
    id: 't1',
    routineId: 'r1',
    blockId: 'b1',
    title: 'Sleep',
    durationMinutes: durationMinutes,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: reminderTimeIso,
    status: TaskStatus.notStarted,
    createdAtMs: 0,
    updatedAtMs: 0,
    category: 'Sleep',
  );
}

void main() {
  group('taskScheduledTimeLabelForDisplay', () {
    test('sleep task shows start – end range for today', () {
      final now = DateTime(2026, 5, 23, 18, 0);
      final start = DateTime(2026, 5, 23, 22, 0);
      final task = _sleepTask(reminderTimeIso: start.toIso8601String());

      expect(
        taskScheduledTimeLabelForDisplay(task, now),
        '10:00 PM – 6:00 AM',
      );
    });

    test('non-sleep task shows start time only', () {
      final now = DateTime(2026, 5, 23, 18, 0);
      final start = DateTime(2026, 5, 23, 14, 30);
      final task = PlannedTask(
        id: 't2',
        routineId: 'r1',
        blockId: 'b1',
        title: 'Study',
        durationMinutes: 25,
        priority: 3,
        orderIndex: 0,
        reminderEnabled: true,
        reminderTimeIso: start.toIso8601String(),
        status: TaskStatus.notStarted,
        createdAtMs: 0,
        updatedAtMs: 0,
        category: 'Study',
      );

      expect(taskScheduledTimeLabelForDisplay(task, now), '2:30 PM');
    });
  });
}
