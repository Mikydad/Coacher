import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mutation_request.dart';
import 'recompute_scope.dart';
import 'schedule_domain_event.dart';
import 'schedule_domain_event_bus.dart';
import 'unified_recompute_graph.dart';

/// Result of a [ScheduleMutationCoordinator.run] call.
class MutationResult {
  const MutationResult({required this.success, this.errorMessage});

  const MutationResult.ok() : this(success: true);
  const MutationResult.failed(String message)
    : this(success: false, errorMessage: message);

  final bool success;
  final String? errorMessage;

  @override
  String toString() =>
      success ? 'MutationResult.ok' : 'MutationResult.failed($errorMessage)';
}

/// Single entry point for all schedule-affecting mutations.
///
/// Routes every mutation through a strict pipeline:
/// 1. Validate
/// 2. Commit (via existing service/repository façades)
/// 3. Trigger [UnifiedRecomputeGraph]
/// 4. Reconcile notifications (Phase 1-B)
/// 5. Publish domain event on [ScheduleDomainEventBus]
///
/// Design rules:
/// - Plain-Dart singleton — no Riverpod dependency except the injected
///   [ProviderContainer] used by the recompute graph.
/// - Call [attachContainer] once at app bootstrap.
/// - [_commit] stubs throw [UnimplementedError] for mutations whose call
///   sites have not yet been migrated. They are migrated one at a time per
///   the incremental adapter pattern (see PRD T4–T6).
class ScheduleMutationCoordinator {
  ScheduleMutationCoordinator._();

  static final ScheduleMutationCoordinator instance =
      ScheduleMutationCoordinator._();

  ProviderContainer? _container;

  /// Called once at app bootstrap — must be called before [run].
  void attachContainer(ProviderContainer container) {
    _container = container;
    UnifiedRecomputeGraph.instance.attachContainer(container);
  }

  /// Execute the full mutation pipeline for [request].
  ///
  /// [commitOverride] lets call sites (e.g. [AiActionExecutor]) that have
  /// already performed the write pass a no-op commit so the coordinator still
  /// runs steps 3–5 (recompute, reconciliation, event). This is the adapter
  /// pattern for incremental migration: existing write code stays in place
  /// while the coordinator owns recompute and event publishing.
  ///
  /// Returns [MutationResult.failed] for validation errors or if the
  /// coordinator is not yet initialised.
  Future<MutationResult> run(
    MutationRequest request, {
    Future<void> Function()? commitOverride,
  }) async {
    // ── 1. Validate ──────────────────────────────────────────────────────────
    final validationError = _validate(request);
    if (validationError != null) {
      debugPrint(
        '[ScheduleMutationCoordinator] validation failed: $validationError',
      );
      return MutationResult.failed(validationError);
    }

    // ── 2. Commit ─────────────────────────────────────────────────────────────
    try {
      if (commitOverride != null) {
        await commitOverride();
      } else {
        await _commit(request);
      }
    } catch (e, st) {
      debugPrint('[ScheduleMutationCoordinator] commit error: $e\n$st');
      return MutationResult.failed(e.toString());
    }

    // ── 3. Derived recompute ──────────────────────────────────────────────────
    UnifiedRecomputeGraph.instance.schedule(_scopeFor(request));

    // ── 4. Notification reconciliation (wired in Phase 1-B) ──────────────────
    _reconcileNotifications(request);

    // ── 5. Publish domain event ───────────────────────────────────────────────
    final event = _eventFor(request);
    if (event != null) {
      ScheduleDomainEventBus.instance.emit(event);
    }

    return const MutationResult.ok();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  String? _validate(MutationRequest request) {
    if (request.entityId.isEmpty) {
      return 'entityId must not be empty';
    }
    if (_container == null) {
      return 'ScheduleMutationCoordinator not initialised — call attachContainer at bootstrap';
    }
    return null;
  }

  // ── Commit dispatch ─────────────────────────────────────────────────────────

  /// Routes the mutation to the correct repository/service.
  ///
  /// Stubs throw [UnimplementedError] until each call site is migrated.
  /// Migrate one mutation type at a time — add the actual implementation
  /// and remove the [UnimplementedError].
  Future<void> _commit(MutationRequest request) async {
    switch (request) {
      case TaskCreatedMutation():
        throw UnimplementedError(
          'TaskCreatedMutation: migrate call site to coordinator first',
        );
      case TaskUpdatedMutation():
        throw UnimplementedError(
          'TaskUpdatedMutation: migrate call site to coordinator first',
        );
      case TaskDeletedMutation():
        throw UnimplementedError(
          'TaskDeletedMutation: migrate call site to coordinator first',
        );
      case TaskCompletedMutation():
        // Wired in T4 — first live migration.
        await _commitTaskCompleted(request);
      case TaskDeferredMutation():
        throw UnimplementedError(
          'TaskDeferredMutation: migrate call site to coordinator first',
        );
      case TimeBlockChangedMutation():
        throw UnimplementedError(
          'TimeBlockChangedMutation: migrate call site to coordinator first',
        );
      case ReminderChangedMutation():
        throw UnimplementedError(
          'ReminderChangedMutation: migrate call site to coordinator first',
        );
      case ContextOverrideChangedMutation():
        throw UnimplementedError(
          'ContextOverrideChangedMutation: migrate call site to coordinator first',
        );
      case GoalChangedMutation():
        throw UnimplementedError(
          'GoalChangedMutation: migrate call site to coordinator first',
        );
    }
  }

  /// Placeholder for TaskCompleted — actual repository call wired in T4.
  /// This method is intentionally a hook for the first live migration.
  Future<void> _commitTaskCompleted(TaskCompletedMutation request) async {
    // Wired in T4 (AiActionExecutor pilot migration):
    // final repo = _container!.read(planningRepositoryProvider);
    // await repo.markTaskCompleted(request.entityId);
    debugPrint(
      '[ScheduleMutationCoordinator] TaskCompleted stub — wire repo in T4',
    );
  }

  // ── Notification reconciliation (Phase 1-B stub) ─────────────────────────

  void _reconcileNotifications(MutationRequest request) {
    // Wired in Phase 1-B when NotificationLedger is in place.
  }

  // ── Scope matrix ─────────────────────────────────────────────────────────────

  RecomputeScope _scopeFor(MutationRequest request) {
    return switch (request) {
      TaskCreatedMutation() => RecomputeScope.forTaskMutation(),
      TaskUpdatedMutation() => RecomputeScope.forTaskMutation(),
      TaskDeletedMutation() => RecomputeScope.forTaskMutation(),
      TaskCompletedMutation() => RecomputeScope.forTaskCompletion(),
      TaskDeferredMutation() => RecomputeScope.forTaskDeferred(),
      TimeBlockChangedMutation() => RecomputeScope.forTimeBlockChange(),
      ReminderChangedMutation() => RecomputeScope.forReminderChange(),
      ContextOverrideChangedMutation() =>
        RecomputeScope.forContextOverrideChange(),
      GoalChangedMutation() => RecomputeScope.forGoalChange(),
    };
  }

  // ── Event mapping ─────────────────────────────────────────────────────────────

  ScheduleDomainEvent? _eventFor(MutationRequest request) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return switch (request) {
      TaskCreatedMutation(:final entityId, :final dateStr) => TaskCreatedEvent(
        entityId: entityId,
        occurredAtMs: now,
        dateStr: dateStr,
      ),
      TaskUpdatedMutation(:final entityId, :final dateStr) => TaskUpdatedEvent(
        entityId: entityId,
        occurredAtMs: now,
        dateStr: dateStr,
      ),
      TaskDeletedMutation(:final entityId, :final dateStr) => TaskDeletedEvent(
        entityId: entityId,
        occurredAtMs: now,
        dateStr: dateStr,
      ),
      TaskCompletedMutation(:final entityId, :final dateStr) =>
        TaskCompletedEvent(
          entityId: entityId,
          occurredAtMs: now,
          dateStr: dateStr,
        ),
      TaskDeferredMutation(
        :final entityId,
        :final fromDateStr,
        :final toDateStr,
      ) =>
        TaskDeferredEvent(
          entityId: entityId,
          occurredAtMs: now,
          fromDateStr: fromDateStr,
          toDateStr: toDateStr,
        ),
      TimeBlockChangedMutation(:final entityId, :final dateStr) =>
        TimeBlockChangedEvent(
          entityId: entityId,
          occurredAtMs: now,
          dateStr: dateStr,
        ),
      ReminderChangedMutation(:final entityId) => ReminderChangedEvent(
        entityId: entityId,
        occurredAtMs: now,
      ),
      ContextOverrideChangedMutation(:final entityId, :final overrideType) =>
        ContextOverrideChangedEvent(
          entityId: entityId,
          occurredAtMs: now,
          overrideType: overrideType,
        ),
      GoalChangedMutation(:final entityId) => FocusChangedEvent(
        entityId: entityId,
        occurredAtMs: now,
      ),
    };
  }

  // ── Test helpers ──────────────────────────────────────────────────────────────

  @visibleForTesting
  void resetForTests() {
    _container = null;
    // ignore: invalid_use_of_visible_for_testing_member
    UnifiedRecomputeGraph.instance.resetForTests();
    // ignore: invalid_use_of_visible_for_testing_member
    ScheduleDomainEventBus.instance.resetForTests();
  }
}
