import 'package:isar/isar.dart';

import '../../../features/planning/domain/models/task_item.dart';

part 'isar_task.g.dart';

@collection
class IsarTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String taskId;

  @Index()
  late String routineId;

  @Index()
  late String blockId;

  @Index()
  String? planDateKey;

  @Index()
  late int updatedAtMs;

  late String title;
  late int durationMinutes;
  late int priority;
  late int orderIndex;
  late bool reminderEnabled;
  String? reminderTimeIso;
  late String statusName;
  late int createdAtMs;
  String? category;
  String? notes;
  int? sequenceIndex;
  late bool strictModeRequired;
  String? modeRefId;

  static IsarTask fromDomain(PlannedTask t) {
    return IsarTask()
      ..taskId = t.id
      ..routineId = t.routineId
      ..blockId = t.blockId
      ..planDateKey = t.planDateKey
      ..updatedAtMs = t.updatedAtMs
      ..title = t.title
      ..durationMinutes = t.durationMinutes
      ..priority = t.priority
      ..orderIndex = t.orderIndex
      ..reminderEnabled = t.reminderEnabled
      ..reminderTimeIso = t.reminderTimeIso
      ..statusName = t.status.name
      ..createdAtMs = t.createdAtMs
      ..category = t.category
      ..notes = t.notes
      ..sequenceIndex = t.sequenceIndex
      ..strictModeRequired = t.strictModeRequired
      ..modeRefId = t.modeRefId;
  }

  PlannedTask toDomain() {
    return PlannedTask(
      id: taskId,
      routineId: routineId,
      blockId: blockId,
      title: title,
      durationMinutes: durationMinutes,
      priority: priority,
      orderIndex: orderIndex,
      reminderEnabled: reminderEnabled,
      reminderTimeIso: reminderTimeIso,
      status: _taskStatusFromStorage(statusName),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      category: category,
      planDateKey: planDateKey,
      notes: notes,
      sequenceIndex: sequenceIndex,
      strictModeRequired: strictModeRequired,
      modeRefId: modeRefId,
    );
  }
}

TaskStatus _taskStatusFromStorage(String? raw) {
  for (final v in TaskStatus.values) {
    if (v.name == raw) return v;
  }
  return TaskStatus.notStarted;
}
