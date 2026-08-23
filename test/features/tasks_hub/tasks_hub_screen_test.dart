import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/planning/application/planned_task_collect.dart';
import 'package:sidepal/features/planning/application/planned_task_providers.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/tasks_hub/presentation/tasks_hub_screen.dart';

PlannedTaskRow _row(
  String id, {
  String? category,
  TaskStatus status = TaskStatus.notStarted,
  String dateKey = '2026-08-23',
}) {
  return PlannedTaskRow(
    dateKey: dateKey,
    routineId: 'r1',
    blockId: 'b1',
    task: PlannedTask(
      id: id,
      routineId: 'r1',
      blockId: 'b1',
      title: 'Task $id with a title long enough to wrap onto a second line',
      durationMinutes: 30,
      priority: 2,
      orderIndex: 0,
      reminderEnabled: true,
      reminderTimeIso: '${dateKey}T09:30:00.000',
      status: status,
      createdAtMs: 1,
      updatedAtMs: 1,
      category: category,
      planDateKey: dateKey,
    ),
  );
}

Widget _screen(List<PlannedTaskRow> today, List<PlannedTaskRow> other) {
  return ProviderScope(
    overrides: [
      todayAllTasksRowsProvider.overrideWith((ref) => Stream.value(today)),
      openTasksOutsideTodayProvider.overrideWith((ref) => Stream.value(other)),
    ],
    child: const MaterialApp(home: TasksHubScreen()),
  );
}

void main() {
  // Regression: the tile Row uses CrossAxisAlignment.stretch (full-height
  // stripe) inside shrink-wrapped lists — without a bounded height
  // (IntrinsicHeight) every row failed layout ("RenderBox was not laid
  // out") and the page rendered nothing. Pumping both sections is the pin.
  testWidgets('hub renders rows in both sections without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(
        [_row('t1', category: 'Study'), _row('t2')],
        [_row('t3', category: 'Work', dateKey: '2026-08-21')],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Task t1'), findsOneWidget);
    expect(find.textContaining('Task t2'), findsOneWidget);
    expect(find.textContaining('Task t3'), findsOneWidget);
    // Meta line: raw status.name is gone; the empty circle carries it.
    expect(find.textContaining('notStarted'), findsNothing);
    expect(find.textContaining('2026-08-21'), findsOneWidget);
  });

  testWidgets('done row keeps rendering and shows Done in the meta', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen([_row('t1', status: TaskStatus.completed)], const []),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Done'), findsOneWidget);
  });
}
