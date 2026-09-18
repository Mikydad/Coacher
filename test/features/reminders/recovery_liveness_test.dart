import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/application/recovery_liveness.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// The Recovery Card shows a row only when "Do now" can land somewhere real
/// (Miko, 2026-09-18): the task still exists and is not done, the goal is
/// active. Anything else is a ghost.
void main() {
  ReminderOccurrence occ(String kind, String id) => ReminderOccurrence(
    id: '$kind-$id',
    entityId: id,
    entityKind: kind,
    dateKey: '2026-09-18',
    scheduledAtMs: DateTime(2026, 9, 18, 9).millisecondsSinceEpoch,
    windowMinutes: 30,
    entityTitle: id,
    state: ReminderOccurrenceState.overdue,
    taxonomy: ReminderTaxonomy.flexible,
    createdAtMs: 1,
    updatedAtMs: 1,
  );

  PlannedTask task(String id, TaskStatus status) => PlannedTask(
    id: id,
    routineId: 'r',
    blockId: 'b',
    title: id,
    durationMinutes: 30,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: null,
    status: status,
    createdAtMs: 1,
    updatedAtMs: 1,
    planDateKey: '2026-09-18',
  );

  UserGoal goal(String id, GoalStatus status) => UserGoal(
    id: id,
    title: id,
    categoryId: 'study',
    status: status,
    measurementKind: MeasurementKind.minutes,
    targetValue: 1,
    intensity: 3,
    periodStartMs: 0,
    periodEndMs: 1,
    repeatCadence: GoalRepeatCadence.daily,
    repeatInterval: 1,
    reminderEnabled: false,
    reminderMinutesFromMidnight: null,
    reminderStyle: GoalReminderStyle.dailyOnce,
    createdAtMs: 0,
    updatedAtMs: 0,
  );

  test('only ACTIVE goals are live — paused and completed are not', () {
    final ids = RecoveryLiveness.activeGoalIds([
      goal('active', GoalStatus.active),
      goal('paused', GoalStatus.paused),
      goal('done', GoalStatus.completed),
    ]);
    expect(ids, {'active'});
  });

  test('a task is live while it exists and is not completed', () {
    expect(RecoveryLiveness.taskIsLive(null), isFalse);
    expect(
      RecoveryLiveness.taskIsLive(task('t', TaskStatus.completed)),
      isFalse,
    );
    for (final s in [
      TaskStatus.notStarted,
      TaskStatus.inProgress,
      TaskStatus.partial,
    ]) {
      expect(RecoveryLiveness.taskIsLive(task('t', s)), isTrue, reason: '$s');
    }
  });

  test('task lookups happen once per distinct task, never per row', () async {
    final asked = <String>[];
    final live = await RecoveryLiveness.liveTaskIds(
      [
        occ('task', 'a'),
        occ('task', 'a'),
        occ('task', 'gone'),
        occ('goal', 'g'), // goals never hit the task lookup
      ],
      taskById: (id) async {
        asked.add(id);
        return id == 'gone' ? null : task(id, TaskStatus.notStarted);
      },
    );
    expect(asked, unorderedEquals(['a', 'gone']));
    expect(live, {'a'});
  });

  test('the predicate drops ghosts and passes kinds it cannot judge', () {
    final isLive = RecoveryLiveness.predicate(
      activeGoalIds: {'g-live'},
      liveTaskIds: {'t-live'},
    );
    expect(isLive(occ('goal', 'g-live')), isTrue);
    expect(isLive(occ('goal', 'g-paused')), isFalse);
    expect(isLive(occ('task', 't-live')), isTrue);
    expect(isLive(occ('task', 't-deleted')), isFalse);
    expect(isLive(occ('activity', 'anything')), isTrue);
  });
}
