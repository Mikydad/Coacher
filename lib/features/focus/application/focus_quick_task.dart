import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';

/// Creates an open task on **today’s** plan (local calendar) and persists to Firestore.
Future<void> persistQuickPlannedTaskForToday(
  PlanningRepository planning,
  String title,
) async {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return;

  const server = GetOptions(source: Source.server);
  final today = DateKeys.todayKey();
  late final ({String routineId, String blockId}) day;
  late final List<PlannedTask> existing;
  try {
    day = await planning.ensureDefaultDayPlan(today, getOptions: server);
    existing = await planning.getTasks(
      routineId: day.routineId,
      blockId: day.blockId,
      getOptions: server,
    );
  } catch (_) {
    day = await planning.ensureDefaultDayPlan(today);
    existing = await planning.getTasks(
      routineId: day.routineId,
      blockId: day.blockId,
    );
  }
  final orderIndex = existing.isEmpty
      ? 0
      : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

  String modeRefId = 'flexible';
  try {
    final routines = await planning.getRoutinesForDate(today, getOptions: server);
    for (final r in routines) {
      if (r.id == day.routineId) {
        modeRefId = r.modeId;
        break;
      }
    }
  } catch (_) {
    try {
      final routines = await planning.getRoutinesForDate(today);
      for (final r in routines) {
        if (r.id == day.routineId) {
          modeRefId = r.modeId;
          break;
        }
      }
    } catch (_) {}
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final task = PlannedTask(
    id: StableId.generate('task'),
    routineId: day.routineId,
    blockId: day.blockId,
    title: trimmed,
    durationMinutes: 25,
    priority: 3,
    orderIndex: orderIndex,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: now,
    updatedAtMs: now,
    planDateKey: today,
    modeRefId: modeRefId,
  );
  await planning.upsertTask(task);
}
