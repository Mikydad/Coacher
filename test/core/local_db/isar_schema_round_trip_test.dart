import 'package:coach_for_life/core/local_db/isar_collections/isar_block.dart';
import 'package:coach_for_life/core/local_db/isar_collections/isar_goal.dart';
import 'package:coach_for_life/core/local_db/isar_collections/isar_reminder.dart';
import 'package:coach_for_life/core/local_db/isar_collections/isar_routine.dart';
import 'package:coach_for_life/core/local_db/isar_collections/isar_task.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_categories.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IsarRoutine round-trip', () {
    const original = Routine(
      id: 'r1',
      title: 'Day',
      dateKey: '2026-04-05',
      orderIndex: 2,
      modeId: 'disciplined',
      mode: RoutineMode.disciplined,
      createdAtMs: 10,
      updatedAtMs: 20,
    );
    final back = IsarRoutine.fromDomain(original).toDomain();
    expect(back.id, original.id);
    expect(back.title, original.title);
    expect(back.dateKey, original.dateKey);
    expect(back.orderIndex, original.orderIndex);
    expect(back.modeId, original.modeId);
    expect(back.mode, original.mode);
    expect(back.createdAtMs, original.createdAtMs);
    expect(back.updatedAtMs, original.updatedAtMs);
  });

  test('IsarBlock round-trip', () {
    const original = TaskBlock(
      id: 'b1',
      routineId: 'r1',
      title: 'Morning',
      orderIndex: 1,
      startMinutesFromMidnight: 480,
      endMinutesFromMidnight: 720,
      urgencyScore: 40,
      modeRefId: 'flexible',
      createdAtMs: 5,
      updatedAtMs: 6,
    );
    final back = IsarBlock.fromDomain(original).toDomain();
    expect(back.id, original.id);
    expect(back.routineId, original.routineId);
    expect(back.title, original.title);
    expect(back.orderIndex, original.orderIndex);
    expect(back.startMinutesFromMidnight, original.startMinutesFromMidnight);
    expect(back.endMinutesFromMidnight, original.endMinutesFromMidnight);
    expect(back.urgencyScore, original.urgencyScore);
    expect(back.modeRefId, original.modeRefId);
    expect(back.createdAtMs, original.createdAtMs);
    expect(back.updatedAtMs, original.updatedAtMs);
  });

  test('IsarTask round-trip', () {
    const original = PlannedTask(
      id: 't1',
      routineId: 'r1',
      blockId: 'b1',
      title: 'Deep work',
      durationMinutes: 45,
      priority: 2,
      orderIndex: 3,
      reminderEnabled: true,
      reminderTimeIso: '2026-04-05T09:00:00.000',
      status: TaskStatus.inProgress,
      createdAtMs: 100,
      updatedAtMs: 200,
      category: 'Study',
      planDateKey: '2026-04-05',
      notes: 'focus',
      sequenceIndex: 9,
      strictModeRequired: true,
      modeRefId: 'extreme',
    );
    final back = IsarTask.fromDomain(original).toDomain();
    expect(back.id, original.id);
    expect(back.routineId, original.routineId);
    expect(back.blockId, original.blockId);
    expect(back.title, original.title);
    expect(back.durationMinutes, original.durationMinutes);
    expect(back.priority, original.priority);
    expect(back.orderIndex, original.orderIndex);
    expect(back.reminderEnabled, original.reminderEnabled);
    expect(back.reminderTimeIso, original.reminderTimeIso);
    expect(back.status, original.status);
    expect(back.createdAtMs, original.createdAtMs);
    expect(back.updatedAtMs, original.updatedAtMs);
    expect(back.category, original.category);
    expect(back.planDateKey, original.planDateKey);
    expect(back.notes, original.notes);
    expect(back.sequenceIndex, original.sequenceIndex);
    expect(back.strictModeRequired, original.strictModeRequired);
    expect(back.modeRefId, original.modeRefId);
  });

  test('IsarReminder round-trip', () {
    const original = ReminderConfig(
      id: 'rem1',
      taskId: 't1',
      taskTitle: 'Do thing',
      enabled: true,
      scheduledAtIso: '2026-04-05T08:00:00.000',
      modeRefId: 'disciplined',
      blockUrgencyScore: 88,
      pendingAction: true,
      escalationLevel: 2,
      emergencyBypass: true,
      lastTriggeredAtMs: 50,
      nextPromptAtIso: '2026-04-05T09:00:00.000',
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    final back = IsarReminder.fromDomain(original).toDomain();
    expect(back.id, original.id);
    expect(back.taskId, original.taskId);
    expect(back.taskTitle, original.taskTitle);
    expect(back.enabled, original.enabled);
    expect(back.scheduledAtIso, original.scheduledAtIso);
    expect(back.modeRefId, original.modeRefId);
    expect(back.blockUrgencyScore, original.blockUrgencyScore);
    expect(back.pendingAction, original.pendingAction);
    expect(back.escalationLevel, original.escalationLevel);
    expect(back.emergencyBypass, original.emergencyBypass);
    expect(back.lastTriggeredAtMs, original.lastTriggeredAtMs);
    expect(back.nextPromptAtIso, original.nextPromptAtIso);
    expect(back.createdAtMs, original.createdAtMs);
    expect(back.updatedAtMs, original.updatedAtMs);
  });

  test('IsarGoal round-trip', () {
    final original = UserGoal(
      id: 'g1',
      title: 'Read',
      categoryId: GoalCategories.study,
      horizon: GoalHorizon.monthly,
      status: GoalStatus.active,
      measurementKind: MeasurementKind.sessions,
      targetValue: 12.5,
      customLabel: 'books',
      intensity: 4,
      periodStartMs: 100,
      periodEndMs: 900,
      periodMode: GoalPeriodMode.calendar,
      durationDays: null,
      reminderEnabled: true,
      reminderMinutesFromMidnight: 120,
      reminderStyle: GoalReminderStyle.dailyOnce,
      createdAtMs: 11,
      updatedAtMs: 22,
    );
    final back = IsarGoal.fromDomain(original).toDomain();
    expect(back.id, original.id);
    expect(back.title, original.title);
    expect(back.categoryId, original.categoryId);
    expect(back.horizon, original.horizon);
    expect(back.status, original.status);
    expect(back.measurementKind, original.measurementKind);
    expect(back.targetValue, original.targetValue);
    expect(back.customLabel, original.customLabel);
    expect(back.intensity, original.intensity);
    expect(back.periodStartMs, original.periodStartMs);
    expect(back.periodEndMs, original.periodEndMs);
    expect(back.periodMode, original.periodMode);
    expect(back.durationDays, original.durationDays);
    expect(back.reminderEnabled, original.reminderEnabled);
    expect(back.reminderMinutesFromMidnight, original.reminderMinutesFromMidnight);
    expect(back.reminderStyle, original.reminderStyle);
    expect(back.createdAtMs, original.createdAtMs);
    expect(back.updatedAtMs, original.updatedAtMs);
  });
}
