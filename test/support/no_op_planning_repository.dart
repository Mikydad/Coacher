import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/accountability_log.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';

/// Minimal [PlanningRepository] for tests where [IsarPlanningRepository] only
/// touches Isar for routines/blocks/tasks.
class NoOpPlanningRepository implements PlanningRepository {
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
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(String dateKey) async {
    throw UnimplementedError('Use IsarPlanningRepository.ensureDefaultDayPlan');
  }

  @override
  Future<String> exportAccountabilityLogs({String format = 'json'}) async => '[]';

  @override
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  }) async =>
      const [];

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => const [];

  @override
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({GetOptions? getOptions}) async =>
      RoutineModeConfig.defaults();

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => const [];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async =>
      const [];

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
