import '../../../../core/validation/model_validators.dart';

enum TaskStatus { notStarted, inProgress, completed, partial }

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
  };

  static PlannedTask fromMap(Map<String, dynamic> map) => PlannedTask(
    id: map['id'] as String,
    routineId: map['routineId'] as String,
    blockId: map['blockId'] as String,
    title: map['title'] as String,
    durationMinutes: map['durationMinutes'] as int,
    priority: map['priority'] as int,
    orderIndex: map['orderIndex'] as int,
    reminderEnabled: map['reminderEnabled'] as bool,
    reminderTimeIso: map['reminderTimeIso'] as String?,
    status: TaskStatus.values.byName(map['status'] as String),
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
    category: map['category'] as String?,
    planDateKey: map['planDateKey'] as String?,
    notes: map['notes'] as String?,
  );
}
