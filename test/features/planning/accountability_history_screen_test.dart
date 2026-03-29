import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/accountability_log.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:coach_for_life/features/planning/presentation/accountability_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlanningRepository implements PlanningRepository {
  @override
  Future<void> deleteAccountabilityLog(String id) async {}

  @override
  Future<void> deleteAccountabilityLogsInRange({
    required int fromCreatedAtMs,
    required int toCreatedAtMs,
  }) async {}

  @override
  Future<void> deleteBlock({required String routineId, required String blockId}) async {}

  @override
  Future<void> deleteRoutine(String routineId) async {}

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {}

  @override
  Future<({String blockId, String routineId})> ensureDefaultDayPlan(
    String dateKey, {
    GetOptions? getOptions,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> exportAccountabilityLogs({String format = 'json'}) async => '[]';

  @override
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  }) async {
    return [
      AccountabilityLog(
        id: 'a1',
        taskId: 't1',
        action: AccountabilityAction.defer,
        reasonCategory: OverrideReasonCategory.scheduleConflict,
        reasonNote: 'I needed to move this task to a later block.',
        modeRefId: 'disciplined',
        taskPriority: 2,
        createdAtMs: DateTime(2026, 3, 24, 10).millisecondsSinceEpoch,
      ),
    ];
  }

  @override
  Future<List<TaskBlock>> getBlocks(
    String routineId, {
    GetOptions? getOptions,
  }) async => const [];

  @override
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({GetOptions? getOptions}) async =>
      RoutineModeConfig.defaults();

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey, {GetOptions? getOptions}) async => const [];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
    GetOptions? getOptions,
  }) async => const [];

  @override
  Future<void> logAccountability(AccountabilityLog log) async {}

  @override
  Future<void> logFlowTransitionEvent(FlowTransitionEvent event) async {}

  @override
  Future<int> pruneOldAccountabilityLogs({int retentionDays = 30, int? nowMs}) async => 0;

  @override
  Future<void> upsertBlock(TaskBlock block) async {}

  @override
  Future<void> upsertRoutine(Routine routine) async {}

  @override
  Future<void> upsertRoutineModeConfig(RoutineModeConfig config) async {}

  @override
  Future<void> upsertTask(PlannedTask task) async {}
}

void main() {
  testWidgets('renders accountability history list with rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningRepositoryProvider.overrideWithValue(_FakePlanningRepository()),
        ],
        child: const MaterialApp(
          home: AccountabilityHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Accountability History'), findsOneWidget);
    expect(find.textContaining('defer'), findsOneWidget);
    expect(find.textContaining('scheduleConflict'), findsOneWidget);
  });
}
