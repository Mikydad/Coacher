import 'package:coach_for_life/features/planning/application/extension_policy.dart';
import 'package:coach_for_life/features/planning/application/routine_mode_policy_resolver.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTask _task({
  int priority = 3,
  bool strictModeRequired = false,
  String? modeRefId,
}) {
  return PlannedTask(
    id: 't1',
    routineId: 'r1',
    blockId: 'b1',
    title: 'Task',
    durationMinutes: 25,
    priority: priority,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 1,
    strictModeRequired: strictModeRequired,
    modeRefId: modeRefId,
  );
}

void main() {
  const resolver = RoutineModePolicyResolver();

  test('extension cap never exceeds +60 minutes', () {
    final policy = ExtensionPolicy.forTask(
      task: _task(modeRefId: 'flexible'),
      resolver: resolver,
      blockUrgencyScore: 20,
    );
    expect(policy.allowedMaxMinutes, lessThanOrEqualTo(60));
  });

  test('disciplined mode lowers extension allowance vs flexible', () {
    final flexible = ExtensionPolicy.forTask(
      task: _task(modeRefId: 'flexible'),
      resolver: resolver,
      blockUrgencyScore: 20,
    );
    final disciplined = ExtensionPolicy.forTask(
      task: _task(modeRefId: 'disciplined'),
      resolver: resolver,
      blockUrgencyScore: 20,
    );
    expect(disciplined.allowedMaxMinutes, lessThanOrEqualTo(flexible.allowedMaxMinutes));
  });

  test('inherits routine extreme when task has no explicit modeRefId', () {
    final routine = Routine(
      id: 'r1',
      title: 'Day',
      dateKey: '2026-01-01',
      orderIndex: 0,
      modeId: 'extreme',
      mode: RoutineMode.extreme,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    final fromRoutine = ExtensionPolicy.forTask(
      task: _task(modeRefId: null),
      resolver: resolver,
      blockUrgencyScore: 20,
      routine: routine,
    );
    final explicitFlexible = ExtensionPolicy.forTask(
      task: _task(modeRefId: 'flexible'),
      resolver: resolver,
      blockUrgencyScore: 20,
    );
    expect(fromRoutine.allowedMaxMinutes, lessThanOrEqualTo(explicitFlexible.allowedMaxMinutes));
  });

  test('strict task with urgency further constrains extension', () {
    final strictUrgent = ExtensionPolicy.forTask(
      task: _task(modeRefId: 'disciplined', strictModeRequired: true, priority: 1),
      resolver: resolver,
      blockUrgencyScore: 95,
    );
    expect(strictUrgent.allowedMaxMinutes, lessThanOrEqualTo(30));
    expect(strictUrgent.requiresReason, isTrue);
    expect(strictUrgent.requiresReflectionPrompt, isTrue);
  });
}
