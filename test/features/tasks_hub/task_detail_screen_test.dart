import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/routine_mode.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/scoring/application/scoring_controller.dart';
import 'package:sidepal/features/tasks_hub/presentation/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/no_op_planning_repository.dart';

const _dateKey = '2026-07-05';

PlannedTask _task({
  String id = 't1',
  TaskStatus status = TaskStatus.notStarted,
  String? modeRefId,
  String? notes,
}) {
  return PlannedTask(
    id: id,
    routineId: 'r1',
    blockId: 'b1',
    title: 'Deep work: design review',
    durationMinutes: 45,
    priority: 2,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: '${_dateKey}T09:30:00.000',
    status: status,
    createdAtMs: DateTime(2026, 7, 1, 8).millisecondsSinceEpoch,
    updatedAtMs: DateTime(2026, 7, 4, 21, 15).millisecondsSinceEpoch,
    category: 'Study',
    planDateKey: _dateKey,
    notes: notes,
    modeRefId: modeRefId,
  );
}

class _FakeRepo extends NoOpPlanningRepository {
  _FakeRepo(this.tasks);

  final List<PlannedTask> tasks;

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async =>
      tasks;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => const [
        Routine(
          id: 'r1',
          title: 'Morning Routine',
          dateKey: _dateKey,
          orderIndex: 0,
          modeId: 'disciplined',
          // ignore: deprecated_member_use_from_same_package
          mode: RoutineMode.disciplined,
          createdAtMs: 0,
          updatedAtMs: 0,
        ),
      ];

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => const [
        TaskBlock(
          id: 'b1',
          routineId: 'r1',
          title: 'Focus Block',
          orderIndex: 0,
          startMinutesFromMidnight: 9 * 60,
          endMinutesFromMidnight: 11 * 60,
          createdAtMs: 0,
          updatedAtMs: 0,
        ),
      ];
}

Widget _app(_FakeRepo repo, {Map<String, int> scores = const {}}) {
  return ProviderScope(
    overrides: [
      planningRepositoryProvider.overrideWithValue(repo),
      scoredTaskStatusesProvider.overrideWith((ref) => scores),
    ],
    child: const MaterialApp(
      home: TaskDetailScreen(
        args: TaskDetailArgs(
          taskId: 't1',
          routineId: 'r1',
          blockId: 'b1',
          dateKey: _dateKey,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders full task detail: title, schedule, coaching, activity',
      (tester) async {
    await tester.pumpWidget(
      _app(_FakeRepo([_task(notes: 'Bring the printed mockups.')]),
          scores: {'t1': 80}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deep work: design review'), findsOneWidget);
    expect(find.text('NOT STARTED'), findsOneWidget);
    expect(find.text('STUDY'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('On · 9:30 AM'), findsOneWidget);
    expect(find.text('Focus Block · 9:00 AM–11:00 AM'), findsOneWidget);
    expect(find.text('Morning Routine'), findsOneWidget);
    // No task-level mode → inherited from the disciplined routine.
    expect(find.text('Disciplined · from routine'), findsOneWidget);
    expect(find.text('P2 · High'), findsOneWidget);
    // Lower cards render lazily — scroll them into view before asserting.
    await tester.scrollUntilVisible(
      find.text('80%'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bring the printed mockups.'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Start focus'), findsOneWidget);
    expect(find.text('Mark done'), findsOneWidget);
  });

  testWidgets('task-level mode override wins over routine mode',
      (tester) async {
    await tester.pumpWidget(_app(_FakeRepo([_task(modeRefId: 'extreme')])));
    await tester.pumpAndSettle();

    expect(find.text('Extreme · set on task'), findsOneWidget);
  });

  testWidgets('completed task disables both action buttons', (tester) async {
    await tester.pumpWidget(
      _app(_FakeRepo([_task(status: TaskStatus.completed)])),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMPLETED'), findsOneWidget);
    final startButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Completed'),
    );
    expect(startButton.onPressed, isNull);
    final doneButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Mark done'),
    );
    expect(doneButton.onPressed, isNull);
  });

  testWidgets('missing task shows not-found state', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(const [])));
    await tester.pumpAndSettle();

    expect(
      find.text('Task not found. It may have been deleted.'),
      findsOneWidget,
    );
  });
}
