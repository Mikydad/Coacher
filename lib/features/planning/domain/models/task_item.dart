import '../../../../core/validation/model_validators.dart';

enum TaskStatus { notStarted, inProgress, completed, partial }

TaskStatus _taskStatusFromStorage(String? raw) {
  for (final v in TaskStatus.values) {
    if (v.name == raw) return v;
  }
  return TaskStatus.notStarted;
}

class PlannedTask {
  const PlannedTask({
    required this.id,
    required this.routineId,
    required this.blockId,
    required this.title,
    required this.durationMinutes,
    required this.priority,
    required this.orderIndex,
    required this.reminderEnabled,
    required this.reminderTimeIso,
    required this.status,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.category,
    /// Calendar day this task is planned for (`yyyy-MM-dd`). When set, lists for
    /// other days must ignore the task even if path data is inconsistent.
    this.planDateKey,
    this.notes,
    this.sequenceIndex,
    this.isHabitAnchor = false,
    this.strictModeRequired = false,
    this.modeRefId,
  });

  final String id;
  final String routineId;
  final String blockId;
  final String title;
  final int durationMinutes;
  final int priority; // 1 highest - 5 lowest
  final int orderIndex;
  final bool reminderEnabled;
  final String? reminderTimeIso;
  final TaskStatus status;
  final int createdAtMs;
  final int updatedAtMs;
  /// Optional label from Add Task classification chips (Study, Fitness, …).
  final String? category;
  final String? planDateKey;
  final String? notes;
  /// Optional user-defined order inside block (used by V2 sequence flow).
  final int? sequenceIndex;
  /// If true, this task behaves as a stable habit anchor in priority/overlap checks.
  final bool isHabitAnchor;
  /// Whether strict mode policy should be enforced for this task.
  final bool strictModeRequired;
  /// Optional policy/mode config id reference used during execution.
  final String? modeRefId;

  void validate() {
    ModelValidators.requireNotBlank(id, 'task.id');
    ModelValidators.requireNotBlank(routineId, 'task.routineId');
    ModelValidators.requireNotBlank(blockId, 'task.blockId');
    ModelValidators.requireNotBlank(title, 'task.title');
    ModelValidators.requireRange(
      value: durationMinutes,
      min: 1,
      max: 24 * 60,
      fieldName: 'task.durationMinutes',
    );
    ModelValidators.requireRange(
      value: priority,
      min: 1,
      max: 5,
      fieldName: 'task.priority',
    );
    if (sequenceIndex != null && sequenceIndex! < 0) {
      throw ArgumentError('task.sequenceIndex must be >= 0');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'routineId': routineId,
    'blockId': blockId,
    'title': title,
    'durationMinutes': durationMinutes,
    'priority': priority,
    'orderIndex': orderIndex,
    'reminderEnabled': reminderEnabled,
    'reminderTimeIso': reminderTimeIso,
    'status': status.name,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    if (category != null) 'category': category,
    if (planDateKey != null) 'planDateKey': planDateKey,
    if (notes != null) 'notes': notes,
    if (sequenceIndex != null) 'sequenceIndex': sequenceIndex,
    'isHabitAnchor': isHabitAnchor,
    'strictModeRequired': strictModeRequired,
    if (modeRefId != null) 'modeRefId': modeRefId,
  };

  static PlannedTask fromMap(Map<String, dynamic> map) => PlannedTask(
    id: map['id'] as String? ?? '',
    routineId: map['routineId'] as String? ?? '',
    blockId: map['blockId'] as String? ?? '',
    title: map['title'] as String? ?? 'Untitled Task',
    durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 25,
    priority: (map['priority'] as num?)?.toInt() ?? 3,
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    reminderEnabled: map['reminderEnabled'] as bool? ?? false,
    reminderTimeIso: map['reminderTimeIso'] as String?,
    status: _taskStatusFromStorage(map['status'] as String?),
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    category: map['category'] as String?,
    planDateKey: map['planDateKey'] as String?,
    notes: map['notes'] as String?,
    sequenceIndex: (map['sequenceIndex'] as num?)?.toInt(),
    isHabitAnchor: map['isHabitAnchor'] as bool? ?? false,
    strictModeRequired: map['strictModeRequired'] as bool? ?? false,
    modeRefId: map['modeRefId'] as String?,
  );
}
