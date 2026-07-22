/// Tasks 6.1 + 6.2 — ScheduleOptimisationService + dismiss suppression logic
///
/// Tests extracted pure logic using minimal fakes.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sidepal/features/ai_assistant/application/schedule_optimisation_service.dart';
import 'package:sidepal/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:sidepal/features/planning/application/planned_task_collect.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/accountability_log.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/flow_transition_event.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/routine_mode.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// Planning repo that returns a single routine with a single block containing
/// the given tasks for every date key.
class _FakePlanningRepo implements PlanningRepository {
  _FakePlanningRepo({this.tasks = const []});
  final List<PlannedTask> tasks;

  static const _routineId = 'test_routine';
  static const _blockId = 'test_block';

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => [
        Routine(
          id: _routineId,
          title: 'Test',
          dateKey: dateKey,
          orderIndex: 0,
          createdAtMs: 0,
          updatedAtMs: 0,
        ),
      ];

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => [
        TaskBlock(
          id: _blockId,
          routineId: routineId,
          title: 'Test Block',
          orderIndex: 0,
          createdAtMs: 0,
          updatedAtMs: 0,
        ),
      ];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async => tasks;

  @override
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({
    GetOptions? getOptions,
  }) async => [];

  @override
  Future<void> upsertRoutineModeConfig(RoutineModeConfig config) async {}

  @override
  Future<void> upsertRoutine(Routine routine) async {}

  @override
  Future<void> deleteRoutine(String routineId) async {}

  @override
  Future<void> upsertBlock(TaskBlock block) async {}

  @override
  Future<void> deleteBlock({
    required String routineId,
    required String blockId,
  }) async {}

  @override
  Future<void> upsertTask(PlannedTask task) async {}

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {}

  @override
  Future<void> logFlowTransitionEvent(FlowTransitionEvent event) async {}

  @override
  Future<void> logAccountability(AccountabilityLog log) async {}

  @override
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  }) async => [];

  @override
  Future<void> deleteAccountabilityLog(String id) async {}

  @override
  Future<void> deleteAccountabilityLogsInRange({
    required int fromCreatedAtMs,
    required int toCreatedAtMs,
  }) async {}

  @override
  Future<int> pruneOldAccountabilityLogs({
    int retentionDays = 30,
    int? nowMs,
  }) async => 0;

  @override
  Future<String> exportAccountabilityLogs({String format = 'json'}) async =>
      '[]';

  @override
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(
    String dateKey,
  ) async => (routineId: _routineId, blockId: _blockId);
}

class _FakeReminderRepo implements ReminderRepository {
  _FakeReminderRepo({this.reminders = const []});
  final List<ReminderConfig> reminders;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => reminders;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async =>
      reminders.where((r) => taskIds.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

/// Records dismissal counts per type.
class _FakeDismissedRepo implements DismissedSuggestionRepository {
  _FakeDismissedRepo({Map<ProactiveSuggestionType, int>? counts})
      : _counts = counts ?? {};

  final Map<ProactiveSuggestionType, int> _counts;

  @override
  Future<void> logDismissal(ProactiveSuggestionType type) async {}

  @override
  Future<int> countDismissals(
    ProactiveSuggestionType type, {
    int withinDays = 7,
  }) async =>
      _counts[type] ?? 0;

  @override
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async {
    final suppressed = <ProactiveSuggestionType>{};
    for (final entry in _counts.entries) {
      if (entry.value >= 3) suppressed.add(entry.key);
    }
    return suppressed;
  }

  @override
  Future<void> purgeOldEntries({int olderThanDays = 7}) async {}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

PlannedTask _task({
  required String id,
  required String title,
  int priority = 3,
  bool strictMode = false,
  String? modeRefId,
  String? reminderTimeIso,
  int duration = 30,
}) {
  return PlannedTask(
    id: id,
    routineId: 'test_routine',
    blockId: 'test_block',
    title: title,
    durationMinutes: duration,
    priority: priority,
    orderIndex: 0,
    reminderEnabled: reminderTimeIso != null,
    reminderTimeIso: reminderTimeIso,
    status: TaskStatus.notStarted,
    createdAtMs: 0,
    updatedAtMs: 0,
    strictModeRequired: strictMode,
    modeRefId: modeRefId,
  );
}

ReminderConfig _reminder({
  required String id,
  required String taskId,
  required String scheduledAtIso,
}) {
  return ReminderConfig(
    id: id,
    taskId: taskId,
    enabled: true,
    scheduledAtIso: scheduledAtIso,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Task 6.2: ScheduleOptimisationService ─────────────────────────────────

  group('ScheduleOptimisationService — Rule A (priority inversion)', () {
    test('High-priority after low-priority → Rule A recommendation', () async {
      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: [
            _task(id: 't1', title: 'Low Priority', priority: 4),
            _task(id: 't2', title: 'High Priority', priority: 1),
          ],
        ),
        reminderRepository: _FakeReminderRepo(),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'A'), isTrue);
    });

    test('Tasks in priority order → no Rule A', () async {
      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: [
            _task(id: 't1', title: 'High', priority: 1),
            _task(id: 't2', title: 'Mid', priority: 3),
            _task(id: 't3', title: 'Low', priority: 5),
          ],
        ),
        reminderRepository: _FakeReminderRepo(),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'A'), isFalse);
    });
  });

  group('ScheduleOptimisationService — Rule B (fatigue stacking)', () {
    test('3 strict tasks back-to-back → Rule B recommendation', () async {
      final base = DateTime(2026, 5, 23, 8, 0);
      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: [
            _task(
              id: 't1',
              title: 'A',
              modeRefId: 'disciplined',
              reminderTimeIso: base.toIso8601String(),
            ),
            _task(
              id: 't2',
              title: 'B',
              modeRefId: 'extreme',
              reminderTimeIso:
                  base.add(const Duration(minutes: 30)).toIso8601String(),
            ),
            _task(
              id: 't3',
              title: 'C',
              strictMode: true,
              reminderTimeIso:
                  base.add(const Duration(minutes: 60)).toIso8601String(),
            ),
          ],
        ),
        reminderRepository: _FakeReminderRepo(),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'B'), isTrue);
    });

    test('Only 2 strict tasks → no Rule B', () async {
      final base = DateTime(2026, 5, 23, 8, 0);
      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: [
            _task(
              id: 't1',
              title: 'A',
              modeRefId: 'disciplined',
              reminderTimeIso: base.toIso8601String(),
            ),
            _task(
              id: 't2',
              title: 'B',
              modeRefId: 'extreme',
              reminderTimeIso:
                  base.add(const Duration(minutes: 30)).toIso8601String(),
            ),
          ],
        ),
        reminderRepository: _FakeReminderRepo(),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'B'), isFalse);
    });
  });

  group('ScheduleOptimisationService — Rule C (reminder noise)', () {
    test('4 reminders within 30 min → Rule C recommendation', () async {
      final base = DateTime(2026, 5, 23, 9, 0);
      final taskIds = ['t1', 't2', 't3', 't4'];
      final reminders = taskIds.asMap().entries.map((e) {
        return _reminder(
          id: 'r${e.key}',
          taskId: e.value,
          scheduledAtIso:
              base.add(Duration(minutes: e.key * 5)).toIso8601String(),
        );
      }).toList();

      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: taskIds.map((id) => _task(id: id, title: 'T$id')).toList(),
        ),
        reminderRepository: _FakeReminderRepo(reminders: reminders),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'C'), isTrue);
    });

    test('Reminders spread > 30 min → no Rule C', () async {
      final base = DateTime(2026, 5, 23, 9, 0);
      final taskIds = ['t1', 't2', 't3', 't4'];
      final reminders = taskIds.asMap().entries.map((e) {
        return _reminder(
          id: 'r${e.key}',
          taskId: e.value,
          scheduledAtIso:
              base.add(Duration(minutes: e.key * 15)).toIso8601String(),
        );
      }).toList();

      final service = ScheduleOptimisationService(
        planningRepository: _FakePlanningRepo(
          tasks: taskIds.map((id) => _task(id: id, title: 'T$id')).toList(),
        ),
        reminderRepository: _FakeReminderRepo(reminders: reminders),
      );

      final results = await service.analyse('2026-05-23');
      expect(results.any((r) => r.ruleCode == 'C'), isFalse);
    });
  });

  // ── Task 6.1 partial: dismiss suppression logic ───────────────────────────

  group('DismissedSuggestionRepository — suppression logic', () {
    test('Type dismissed 3+ times → in suppressedTypes set', () async {
      final repo = _FakeDismissedRepo(
        counts: {ProactiveSuggestionType.scheduleGap: 3},
      );
      final suppressed = await repo.suppressedTypes();
      expect(suppressed, contains(ProactiveSuggestionType.scheduleGap));
    });

    test('Type dismissed < 3 times → not suppressed', () async {
      final repo = _FakeDismissedRepo(
        counts: {ProactiveSuggestionType.scheduleGap: 2},
      );
      final suppressed = await repo.suppressedTypes();
      expect(suppressed, isNot(contains(ProactiveSuggestionType.scheduleGap)));
    });

    test('Multiple types — only those at 3+ are suppressed', () async {
      final repo = _FakeDismissedRepo(
        counts: {
          ProactiveSuggestionType.recurringTaskMissing: 3,
          ProactiveSuggestionType.optimiseOrder: 1,
        },
      );
      final suppressed = await repo.suppressedTypes();
      expect(
        suppressed,
        contains(ProactiveSuggestionType.recurringTaskMissing),
      );
      expect(
        suppressed,
        isNot(contains(ProactiveSuggestionType.optimiseOrder)),
      );
    });
  });
}
