/// Sealed hierarchy of all schedule-affecting mutation requests.
///
/// Every mutation that changes tasks, goals, reminders, time blocks, or
/// context overrides must be expressed as a [MutationRequest] and routed
/// through [ScheduleMutationCoordinator.run].
sealed class MutationRequest {
  const MutationRequest({
    required this.entityId,
    required this.entityKind,
    required this.sourceContext,
    int? occurredAtMs,
  }) : occurredAtMs = occurredAtMs ?? 0;

  /// Primary entity being mutated (task id, goal id, etc.).
  final String entityId;

  /// Human-readable kind: `'task'`, `'goal'`, `'reminder'`,
  /// `'timeBlock'`, `'contextOverride'`.
  final String entityKind;

  /// Which screen or service triggered this mutation, for tracing.
  /// E.g. `'add_task_screen'`, `'ai_action_executor'`, `'tasks_hub'`.
  final String sourceContext;

  /// Epoch milliseconds when the mutation was initiated.
  final int occurredAtMs;
}

// ─── Task mutations ───────────────────────────────────────────────────────────

final class TaskCreatedMutation extends MutationRequest {
  const TaskCreatedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.dateStr,
    this.timeBlockId,
    super.occurredAtMs,
  }) : super(entityKind: 'task');

  final String dateStr;
  final String? timeBlockId;
}

final class TaskUpdatedMutation extends MutationRequest {
  const TaskUpdatedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.dateStr,
    this.timeBlockId,
    super.occurredAtMs,
  }) : super(entityKind: 'task');

  final String dateStr;
  final String? timeBlockId;
}

final class TaskDeletedMutation extends MutationRequest {
  const TaskDeletedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.dateStr,
    super.occurredAtMs,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskCompletedMutation extends MutationRequest {
  const TaskCompletedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.dateStr,
    super.occurredAtMs,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskDeferredMutation extends MutationRequest {
  const TaskDeferredMutation({
    required super.entityId,
    required super.sourceContext,
    required this.fromDateStr,
    required this.toDateStr,
    super.occurredAtMs,
  }) : super(entityKind: 'task');

  final String fromDateStr;
  final String toDateStr;
}

// ─── Time block mutation ──────────────────────────────────────────────────────

final class TimeBlockChangedMutation extends MutationRequest {
  const TimeBlockChangedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.dateStr,
    super.occurredAtMs,
  }) : super(entityKind: 'timeBlock');

  final String dateStr;
}

// ─── Reminder mutation ────────────────────────────────────────────────────────

final class ReminderChangedMutation extends MutationRequest {
  const ReminderChangedMutation({
    required super.entityId,
    required super.sourceContext,
    super.occurredAtMs,
  }) : super(entityKind: 'reminder');
}

// ─── Context override mutation ────────────────────────────────────────────────

final class ContextOverrideChangedMutation extends MutationRequest {
  const ContextOverrideChangedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.overrideType,
    super.occurredAtMs,
  }) : super(entityKind: 'contextOverride');

  final String overrideType;
}

// ─── Goal mutation ────────────────────────────────────────────────────────────

final class GoalChangedMutation extends MutationRequest {
  const GoalChangedMutation({
    required super.entityId,
    required super.sourceContext,
    required this.changeKind,
    super.occurredAtMs,
  }) : super(entityKind: 'goal');

  /// `'created'`, `'updated'`, `'deleted'`, `'paused'`, `'completed'`
  final String changeKind;
}
