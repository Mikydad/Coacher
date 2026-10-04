import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';

/// Phase 6 (goal↔task link): the new field must survive every hop of the
/// synced set — domain map (outbox + merge) and the Isar row.
void main() {
  PlannedTask task({String? goalId}) => PlannedTask(
    id: 't1',
    routineId: 'r',
    blockId: 'b',
    title: 'Practice',
    durationMinutes: 25,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 2,
    planDateKey: '2026-09-27',
    goalId: goalId,
  );

  test('goalId round-trips through toMap/fromMap and is omitted when null', () {
    final linked = task(goalId: 'g-music');
    expect(PlannedTask.fromMap(linked.toMap()).goalId, 'g-music');
    expect(task().toMap().containsKey('goalId'), isFalse);
    expect(PlannedTask.fromMap(task().toMap()).goalId, isNull);
  });

  test('goalId round-trips through the Isar row', () {
    final row = IsarTask.fromDomain(task(goalId: 'g-music'));
    expect(row.goalId, 'g-music');
    expect(row.toDomain().goalId, 'g-music');
    expect(IsarTask.fromDomain(task()).toDomain().goalId, isNull);
  });
}
