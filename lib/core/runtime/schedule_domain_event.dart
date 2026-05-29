/// Sealed hierarchy of all domain events emitted after a successful
/// schedule mutation.
///
/// Published by [ScheduleDomainEventBus] after [ScheduleMutationCoordinator]
/// commits a mutation. Riverpod providers and services subscribe to the bus
/// rather than being invalidated directly.
sealed class ScheduleDomainEvent {
  const ScheduleDomainEvent({
    required this.entityId,
    required this.entityKind,
    required this.occurredAtMs,
  });

  final String entityId;
  final String entityKind;
  final int occurredAtMs;
}

// ─── Task events ──────────────────────────────────────────────────────────────

final class TaskCreatedEvent extends ScheduleDomainEvent {
  const TaskCreatedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.dateStr,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskUpdatedEvent extends ScheduleDomainEvent {
  const TaskUpdatedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.dateStr,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskDeletedEvent extends ScheduleDomainEvent {
  const TaskDeletedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.dateStr,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskCompletedEvent extends ScheduleDomainEvent {
  const TaskCompletedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.dateStr,
  }) : super(entityKind: 'task');

  final String dateStr;
}

final class TaskDeferredEvent extends ScheduleDomainEvent {
  const TaskDeferredEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.fromDateStr,
    required this.toDateStr,
  }) : super(entityKind: 'task');

  final String fromDateStr;
  final String toDateStr;
}

// ─── Time block event ─────────────────────────────────────────────────────────

final class TimeBlockChangedEvent extends ScheduleDomainEvent {
  const TimeBlockChangedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.dateStr,
  }) : super(entityKind: 'timeBlock');

  final String dateStr;
}

// ─── Reminder event ───────────────────────────────────────────────────────────

final class ReminderChangedEvent extends ScheduleDomainEvent {
  const ReminderChangedEvent({
    required super.entityId,
    required super.occurredAtMs,
  }) : super(entityKind: 'reminder');
}

// ─── Context override event ───────────────────────────────────────────────────

final class ContextOverrideChangedEvent extends ScheduleDomainEvent {
  const ContextOverrideChangedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.overrideType,
  }) : super(entityKind: 'contextOverride');

  final String overrideType;
}

// ─── Focus event ──────────────────────────────────────────────────────────────

final class FocusChangedEvent extends ScheduleDomainEvent {
  const FocusChangedEvent({
    required super.entityId,
    required super.occurredAtMs,
  }) : super(entityKind: 'focus');
}

// ─── Conflict resolved event ──────────────────────────────────────────────────

final class ScheduleConflictResolvedEvent extends ScheduleDomainEvent {
  const ScheduleConflictResolvedEvent({
    required super.entityId,
    required super.occurredAtMs,
    required this.conflictingEntityId,
  }) : super(entityKind: 'timeBlock');

  final String conflictingEntityId;
}
