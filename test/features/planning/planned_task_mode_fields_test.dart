import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTask _sample({
  String? modeRefId,
  bool strictModeRequired = false,
}) {
  return PlannedTask(
    id: 't1',
    routineId: 'r1',
    blockId: 'b1',
    title: 'Test',
    durationMinutes: 25,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 2,
    strictModeRequired: strictModeRequired,
    modeRefId: modeRefId,
  );
}

void main() {
  test('toMap / fromMap round-trip preserves modeRefId and strictModeRequired', () {
    final original = _sample(modeRefId: 'disciplined', strictModeRequired: true);
    final restored = PlannedTask.fromMap(original.toMap());
    expect(restored.modeRefId, 'disciplined');
    expect(restored.strictModeRequired, isTrue);
  });

  test('fromMap defaults for missing mode fields', () {
    final t = PlannedTask.fromMap({
      'id': 't1',
      'routineId': 'r1',
      'blockId': 'b1',
      'title': 'Legacy',
      'durationMinutes': 10,
      'priority': 3,
      'orderIndex': 0,
      'reminderEnabled': false,
      'status': 'notStarted',
      'createdAtMs': 1,
      'updatedAtMs': 2,
    });
    expect(t.modeRefId, isNull);
    expect(t.strictModeRequired, isFalse);
  });
}
