# PRD: Phase 1-A — ScheduleMutationCoordinator + Domain Event System + Unified Recompute Graph

**Branch:** `platform-refactor`
**Status:** Draft
**Relates to:** `PRD/Platform_Refactor/Runtime_Consolidation_and_Platform_Stabilization.md` — Phase 1, Tasks 1–3

---

## 1. Introduction / Overview

### The problem

Today every place in the app that changes a task, goal, reminder, or schedule manually reaches into Riverpod and fires its own set of invalidations:

```
add_task_screen.dart       → invalidateTaskListProviders(ref)
home_screen.dart           → invalidateTaskListProviders + invalidateTodayCoachingDelivery
goal_detail_screen.dart    → ref.invalidate(analyticsPeriodBundleProvider)
proactive_suggestion_card  → ref.invalidate(proactiveSuggestionsProvider)
ai_action_executor         → ref.invalidate(todayAllTasksRowsProvider)
tasks_hub_screen           → invalidateTaskListProviders x5 (scattered calls)
... 15+ more files
```

There is no single place that owns "a schedule mutation happened, here is everything that must react." The result is:

- Stale coaching focus after task edits
- Proactive suggestions that don't reflect the latest schedule
- Analytics bundle recomputing before reminders have been rescheduled
- Duplicate recomputes when multiple systems fire at once
- New mutations have no obvious checklist of what they must trigger

### The solution (this PRD)

Introduce three tightly connected systems:

1. **`ScheduleMutationCoordinator`** — the single entry point for all schedule-affecting mutations. Routes the mutation through: validation → atomic commit → derived recompute → notification reconciliation → event publish.
2. **Domain Event System** — a plain-Dart `StreamController`-based event bus. Replaces direct cross-system `ref.invalidate` calls with observable events (`TaskCreated`, `TaskUpdated`, `TimeBlockChanged`, etc.). Riverpod providers *subscribe* to events rather than being poked directly.
3. **Unified Recompute Graph** — a deterministic, debounced, generation-protected recompute pipeline triggered by the coordinator (via the event bus). Defines a strict dependency order: overlaps → analytics → streaks → coaching focus → suggestions → layer3/4 insights → AI summaries → notification reconciliation.

### What this is NOT

This is **not a rewrite**. The goal is to consolidate and normalize the existing systems:

- `PostSyncRefreshCoordinator` → extended and promoted to `ScheduleMutationCoordinator`
- `AiActionExecutor` → migrated to route through the coordinator
- `AttentionOrchestratorService` → remains authoritative for notification delivery decisions; the coordinator calls it, not the other way around
- All existing repositories and services remain intact

Migration is **incremental via an adapter pattern**: the coordinator is introduced first, then call sites are migrated screen by screen.

---

## 2. Goals

- G1: Any schedule-affecting mutation fires a consistent, complete, deterministic recompute — no stale coaching or stale suggestions after a task save.
- G2: No scattered `ref.invalidate` calls in widgets or services. All recompute flows through the coordinator.
- G3: Domain events are observable by any subsystem without direct coupling.
- G4: New features can add a mutation type and immediately get full recompute coverage by going through the coordinator.
- G5: The recompute graph is debounced and coalescing so rapid mutations do not storm the system.
- G6: Riverpod providers do not own the runtime event system; the event system is framework-independent.

---

## 3. User Stories

- **As a user** editing a task time, I want the coaching focus and proactive suggestion cards to reflect my new schedule immediately — not show yesterday's stale state.
- **As a user** completing a task, I want the streak and discipline analytics to update immediately without me having to pull-to-refresh.
- **As a developer** adding a new mutation type, I want a single place to register it so recomputes, notifications, and events all fire correctly — without having to manually find every screen that needs an invalidation.
- **As a developer** debugging a stale UI, I want to trace exactly which mutation triggered which recompute, and see it in one place.

---

## 4. Functional Requirements

### FR-1: ScheduleMutationCoordinator — core pipeline

1. The system must provide a `ScheduleMutationCoordinator` class with a `run(MutationRequest)` method as the single entry point for all schedule-affecting mutations.
2. `run()` must execute the following pipeline in strict order:
   1. **Validation** — reject impossible mutations (duplicate, past-locked, conflict violations) before any write occurs.
   2. **Atomic Commit** — call the appropriate existing repository/service (planning, goals, reminders, time blocks). No new persistence logic.
   3. **Derived Recompute** — trigger the Unified Recompute Graph for the mutation type.
   4. **Notification Reconciliation** — call `AttentionOrchestratorService` to reconcile alarms for affected entities.
   5. **Event Publish** — emit a domain event on the event bus.
3. The coordinator must be a plain Dart singleton (no Riverpod dependency) so it can be called from services, background workers, and tests without a widget tree.
4. The coordinator must expose a `ProviderContainer` setter (called once at bootstrap) so the recompute step can invalidate Riverpod providers.

### FR-2: MutationRequest model

5. The system must define a sealed `MutationRequest` class hierarchy. Initial mutation types required:
   - `TaskCreatedMutation`
   - `TaskUpdatedMutation`
   - `TaskDeletedMutation`
   - `TaskCompletedMutation`
   - `TaskDeferredMutation`
   - `TimeBlockChangedMutation`
   - `ReminderChangedMutation`
   - `ContextOverrideChangedMutation`
   - `GoalChangedMutation`
6. Each `MutationRequest` must carry: `entityId`, `entityKind`, `sourceContext` (which screen/service triggered it), and mutation-type-specific payload fields.

### FR-3: Domain Event System

7. The system must provide a `ScheduleDomainEventBus` — a plain Dart class backed by a `StreamController<ScheduleDomainEvent>.broadcast()`.
8. It must be a singleton accessible without Riverpod (e.g. `ScheduleDomainEventBus.instance`).
9. Required event types (sealed class hierarchy):
   - `TaskCreatedEvent`, `TaskUpdatedEvent`, `TaskDeletedEvent`
   - `TaskCompletedEvent`, `TaskDeferredEvent`
   - `TimeBlockChangedEvent`
   - `ReminderChangedEvent`
   - `ContextOverrideChangedEvent`
   - `FocusChangedEvent`
   - `ScheduleConflictResolvedEvent`
10. Each event must carry: `entityId`, `entityKind`, `occurredAtMs`, and event-type-specific fields.
11. Riverpod providers that currently react to mutations via direct invalidation must be refactored to subscribe to events via `ScheduleDomainEventBus.instance.stream.listen(...)` in their `ref.onDispose`-guarded lifecycle.
12. The event bus must never throw even if a subscriber throws — errors in subscribers must be caught and logged, not allowed to bubble.

### FR-4: Unified Recompute Graph

13. The system must define a `UnifiedRecomputeGraph` class that accepts a `RecomputeScope` (which subsystems need to recompute) and executes them in the following strict dependency order:
    1. Overlap detection (time block conflict re-check)
    2. Analytics bundle (`analyticsPeriodBundleProvider`)
    3. Streak rollup (embedded in bundle; no separate step)
    4. Coaching focus (`recomputeCoachingFocusProvider` — light path only, not full layer34)
    5. Proactive suggestions (`proactiveSuggestionsProvider`)
    6. Layer 3 delivery insights (`layer3DeliveryDayInsightsProvider`)
    7. Layer 4 delivery decision (`layer4RefreshTodayDeliveryProvider`)
    8. AI summaries (`currentAiSummaryProvider`)
    9. Notification reconciliation (trigger `AttentionOrchestratorService`)
14. The graph must be debounced with a **400 ms** coalescing window (replacing the 450 ms in `PostSyncRefreshCoordinator`).
15. The graph must use a **generation counter** per recompute scope: if a newer mutation arrives before the previous recompute finishes, the in-flight recompute is cancelled/skipped.
16. Each step in the graph must be independently skippable via the `RecomputeScope` so that e.g. a context override change does not re-run analytics bundle unnecessarily.
17. The existing `PostSyncRefreshCoordinator` must be **refactored to delegate to** `UnifiedRecomputeGraph` rather than running its own separate invalidation logic. It must not be deleted — keep it as a thin adapter so existing call sites (sync, lifecycle) continue to work while migration proceeds.

### FR-5: Adapter layer (incremental migration)

18. The system must provide an `invalidateViaCoordinator(WidgetRef ref, MutationContext)` adapter function that wraps the coordinator's `run()` method. This lets existing widget-level `invalidateTaskListProviders(ref)` calls be migrated one file at a time to the coordinator without a big-bang rewrite.
19. The existing `invalidateTaskListProviders` and `invalidateTodayCoachingDelivery` helpers must **not** be deleted in this phase. They remain as legacy paths while migration is in progress.
20. Each migrated call site must add a `// migrated to coordinator` comment replacing the old invalidation call, so the audit trail is clear.

### FR-6: Integration with existing mutation entry points

21. `AiActionExecutor.execute()` must be updated to call `ScheduleMutationCoordinator.run()` after each successful action dispatch rather than calling `ref.invalidate` directly.
22. `AddTaskScreen._onSave()` must be updated to call the coordinator after `upsertTask` + `_syncTimeBlock` + `_persistReminder` succeed.
23. The coordinator must be tested with: task create, task update, task complete, context override change.

---

## 5. Non-Goals (Out of Scope for this PRD)

- Replacing `AttentionOrchestratorService` internals — it remains authoritative; the coordinator calls its reconcile method.
- Full AI executor hardening with rollback / undo — that is PRD 1-B.
- Notification Ledger persistence — that is PRD 1-B.
- Migrating every single call site in this PR — the adapter allows incremental migration; the full sweep is a follow-up task.
- Multi-device sync changes.
- Phase 2+ work (auth, subscriptions, community).

---

## 6. Design Considerations

### Module layout

```
lib/core/runtime/
  schedule_mutation_coordinator.dart    ← new
  mutation_request.dart                 ← new (sealed class hierarchy)
  unified_recompute_graph.dart          ← new
  recompute_scope.dart                  ← new
  schedule_domain_event_bus.dart        ← new
  schedule_domain_event.dart            ← new (sealed class hierarchy)
```

`PostSyncRefreshCoordinator` stays in `lib/core/sync/` as a thin adapter.

### Design principles

- **No Riverpod import in `lib/core/runtime/`** except for the `ProviderContainer` reference used for invalidation. The module must be testable in plain Dart without a Flutter test environment.
- **Coordinator is not a Riverpod provider** — it is a Dart singleton, same pattern as `SyncService.instance` and `OfflineStore.instance`.
- **Subscribers use `ref.onDispose` guards** to cancel stream subscriptions and avoid memory leaks.

### Recompute scope matrix (reference)

| Mutation type | overlaps | analytics | focus | suggestions | layer3/4 | notification |
|---|---|---|---|---|---|---|
| TaskCreated | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| TaskUpdated | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| TaskCompleted | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| TaskDeleted | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| TaskDeferred | — | ✓ | — | ✓ | — | ✓ |
| TimeBlockChanged | ✓ | — | — | ✓ | — | ✓ |
| ReminderChanged | — | — | — | — | — | ✓ |
| ContextOverrideChanged | — | — | — | — | — | ✓ |
| GoalChanged | — | ✓ | ✓ | ✓ | ✓ | — |

---

## 7. Technical Considerations

- **Existing infrastructure to build on:**
  - `PostSyncRefreshCoordinator` — generation counter pattern and debounce already proven; extend, don't replace.
  - `AttentionOrchestratorService` — pure Dart, already testable; call its reconcile method from the coordinator.
  - `AiActionExecutor` — already uses repository façades; safe to add coordinator call at the end of `execute()`.
- **Dart sealed classes** for `MutationRequest` and `ScheduleDomainEvent` — requires Dart 3+ (already in use in this project).
- **Stream broadcast** for the event bus — `broadcast()` needed because multiple subscribers (analytics, suggestions, notifications) listen simultaneously.
- **ProviderContainer attachment** — the coordinator receives the container at bootstrap (same pattern as `PostSyncRefreshCoordinator` uses `appRootProviderContainer`). This is the only framework coupling point.
- **Test strategy** — unit tests for the coordinator pipeline with fake repositories; integration tests for the recompute graph with a real Riverpod container.

---

## 8. Success Metrics

| Priority | Metric |
|----------|--------|
| 1 (highest) | After any task save or edit, coaching focus + proactive suggestions reflect the new schedule — verified by widget test |
| 2 | `AiActionExecutor` has no direct `ref.invalidate` calls — verified by static analysis / grep |
| 3 | Zero duplicate recompute logs for a single task save (one recompute cycle fires, not two or three) |
| 4 | `invalidateTaskListProviders` call count in widgets drops by ≥ 80% (remaining calls use the coordinator) |

---

## 9. Open Questions

1. Should `UnifiedRecomputeGraph` step 4 (coaching focus) run the **light path** only (read from Isar, no layer34 re-run) or trigger a fresh `layer34RecomputeNow` on certain mutations? Recommendation: light path only for mutations; full layer34 only on explicit user refresh.
2. Should `ScheduleDomainEventBus` events be persisted to Isar for replay on boot, or stay purely in-memory? Recommendation: in-memory for now; persistence deferred to Phase 2 sync integrity work.
3. Which screen should be the **first** migrated call site (pilot migration) — `AddTaskScreen`, `TasksHubScreen`, or `AiActionExecutor`? Recommendation: `AiActionExecutor` first — highest risk, most visible, easiest to isolate in tests.

---

## 10. Implementation Tasks

### T1 — Domain models (foundation, no app changes yet)

**Goal:** Define the sealed class hierarchies and the event bus. Zero UI impact. Start here so every subsequent task has something to import.

- [ ] **T1.1** Create `lib/core/runtime/` directory
- [ ] **T1.2** Create `lib/core/runtime/mutation_request.dart`
  - Sealed base class `MutationRequest` with fields: `entityId`, `entityKind`, `sourceContext`, `occurredAtMs`
  - Subclasses: `TaskCreatedMutation`, `TaskUpdatedMutation`, `TaskDeletedMutation`, `TaskCompletedMutation`, `TaskDeferredMutation`, `TimeBlockChangedMutation`, `ReminderChangedMutation`, `ContextOverrideChangedMutation`, `GoalChangedMutation`
  - Each subclass carries its mutation-specific payload (e.g. `TaskCreatedMutation` has `taskId`, `dateStr`, `timeBlockId?`)
- [ ] **T1.3** Create `lib/core/runtime/schedule_domain_event.dart`
  - Sealed base class `ScheduleDomainEvent` with fields: `entityId`, `entityKind`, `occurredAtMs`
  - Subclasses: `TaskCreatedEvent`, `TaskUpdatedEvent`, `TaskDeletedEvent`, `TaskCompletedEvent`, `TaskDeferredEvent`, `TimeBlockChangedEvent`, `ReminderChangedEvent`, `ContextOverrideChangedEvent`, `FocusChangedEvent`, `ScheduleConflictResolvedEvent`
- [ ] **T1.4** Create `lib/core/runtime/schedule_domain_event_bus.dart`
  - `ScheduleDomainEventBus` singleton (`ScheduleDomainEventBus.instance`)
  - Backed by `StreamController<ScheduleDomainEvent>.broadcast()`
  - `void emit(ScheduleDomainEvent event)` — catches and logs subscriber errors, never re-throws
  - `Stream<ScheduleDomainEvent> get stream`
  - `void dispose()` for tests
- [ ] **T1.5** Write unit tests in `test/core/runtime/schedule_domain_event_bus_test.dart`
  - Test: emitting an event delivers to all subscribers
  - Test: a subscriber that throws does not crash the bus
  - Test: dispose closes the stream

---

### T2 — RecomputeScope + UnifiedRecomputeGraph

**Goal:** The recompute pipeline in isolation — no coordinator yet. `PostSyncRefreshCoordinator` will delegate to it at the end of this task.

- [ ] **T2.1** Create `lib/core/runtime/recompute_scope.dart`
  - `RecomputeScope` class with boolean flags: `overlaps`, `analytics`, `focus`, `suggestions`, `layer34`, `aiSummary`, `notifications`
  - Factory constructors from the scope matrix in section 6:
    - `RecomputeScope.forTaskMutation()` — all flags true
    - `RecomputeScope.forTaskCompletion()` — analytics, focus, suggestions, layer34, notifications
    - `RecomputeScope.forTimeBlockChange()` — overlaps, suggestions, notifications
    - `RecomputeScope.forReminderChange()` — notifications only
    - `RecomputeScope.forContextOverrideChange()` — notifications only
    - `RecomputeScope.forGoalChange()` — analytics, focus, suggestions, layer34
    - `RecomputeScope.forFullRefresh()` — all flags true (used by sync)
  - `RecomputeScope merge(RecomputeScope other)` — bitwise OR, for coalescing
- [ ] **T2.2** Create `lib/core/runtime/unified_recompute_graph.dart`
  - `UnifiedRecomputeGraph` singleton (`UnifiedRecomputeGraph.instance`)
  - `ProviderContainer? _container` — set via `attachContainer(ProviderContainer)`
  - Generation counter `int _generation = 0` per pending scope
  - `static const Duration kDebounce = Duration(milliseconds: 400)`
  - `void schedule(RecomputeScope scope)` — merges scope into `_pendingScope`, bumps generation, resets debounce timer
  - `Future<void> _flush()` — captures generation snapshot; executes steps in dependency order skipping disabled flags; aborts if generation changed mid-run
  - Step execution order (match FR-4 §13):
    1. `overlaps` → call `TimeBlockSyncService.recheckConflicts()` if available
    2. `analytics` → `container.invalidate(analyticsPeriodBundleProvider)`
    3. `focus` → `container.invalidate(recomputeCoachingFocusProvider)` (light path)
    4. `suggestions` → `container.invalidate(proactiveSuggestionsProvider)`
    5. `layer34` → `invalidateTodayCoachingDeliveryFromContainer(container)`
    6. `aiSummary` → `container.invalidate(currentAiSummaryProvider)` if provider exists
    7. `notifications` → call `AttentionOrchestratorService` reconcile via container
  - `@visibleForTesting void flushNowForTests()`
  - `@visibleForTesting void resetForTests()`
- [ ] **T2.3** Refactor `lib/core/sync/post_sync_refresh_coordinator.dart`
  - Replace the `_flush()` body with: `UnifiedRecomputeGraph.instance.schedule(RecomputeScope.forFullRefresh())`
  - Keep the public API (`schedule()`, `scheduleAfterSuccessfulRemotePull()`) unchanged so no callers break
  - Keep debounce in `PostSyncRefreshCoordinator` as-is (it coalesces; `UnifiedRecomputeGraph` also debounces — this is fine, net result is two debounce windows: acceptable)
- [ ] **T2.4** Write unit tests in `test/core/runtime/unified_recompute_graph_test.dart`
  - Test: scheduling two mutations within 400 ms coalesces into one flush
  - Test: generation bump from a second mutation cancels the first in-flight flush
  - Test: `RecomputeScope.forReminderChange()` only triggers the notifications step
  - Test: `PostSyncRefreshCoordinator.scheduleAfterSuccessfulRemotePull()` delegates to graph (verify via flush count)

---

### T3 — ScheduleMutationCoordinator skeleton

**Goal:** Wire the coordinator singleton. No call sites migrated yet — just the framework and one smoke test.

- [ ] **T3.1** Create `lib/core/runtime/schedule_mutation_coordinator.dart`
  - `ScheduleMutationCoordinator` singleton (`ScheduleMutationCoordinator.instance`)
  - `void attachContainer(ProviderContainer container)` — called at bootstrap
  - `Future<MutationResult> run(MutationRequest request)` with pipeline:
    1. `_validate(request)` — basic guard (non-empty entityId; rejects if container not attached yet; extensible)
    2. `_commit(request)` — abstract dispatch by `MutationRequest` type; calls existing service/repository (see T3.2)
    3. `UnifiedRecomputeGraph.instance.schedule(_scopeFor(request))` — trigger recompute
    4. `_reconcileNotifications(request)` — placeholder for Phase 1-B `AttentionOrchestratorService` call; no-op for now
    5. `ScheduleDomainEventBus.instance.emit(_eventFor(request))` — publish event
  - `MutationResult` value object with: `bool success`, `String? errorMessage`
  - `_scopeFor(MutationRequest)` — returns the correct `RecomputeScope` from the scope matrix
  - `_eventFor(MutationRequest)` — maps mutation to corresponding domain event
- [ ] **T3.2** Implement `_commit()` dispatch stubs for all 9 mutation types
  - For now each stub calls `throw UnimplementedError('migrate call site first')` so the coordinator can exist without replacing existing flows
  - Exception: `TaskCompletedMutation` — wire up the actual task-completion repository call as the first live migration (used to verify the pipeline end-to-end)
- [ ] **T3.3** Register coordinator at bootstrap in `lib/core/bootstrap/app_bootstrap.dart`
  - After `OfflineStore.instance.initialize()`, add:
    ```dart
    ScheduleMutationCoordinator.instance.attachContainer(container);
    UnifiedRecomputeGraph.instance.attachContainer(container);
    ```
- [ ] **T3.4** Write unit tests in `test/core/runtime/schedule_mutation_coordinator_test.dart`
  - Test: `run(TaskCompletedMutation(...))` calls the task repo, schedules a recompute, and emits a `TaskCompletedEvent`
  - Test: `run(...)` with an unattached container returns `MutationResult(success: false, errorMessage: 'not initialized')`
  - Test: validation rejects a mutation with empty `entityId`

---

### T4 — Pilot migration: AiActionExecutor

**Goal:** First live call site migrated. Removes all `ref.invalidate` calls from `AiActionExecutor`.

- [ ] **T4.1** Implement live `_commit()` dispatch in the coordinator for: `TaskCreatedMutation`, `TaskUpdatedMutation`, `TaskDeletedMutation`
  - Wire to the existing `PlanningRepository` calls that `AiActionExecutor` currently makes
  - Coordinator receives the needed repositories via constructor injection (not Riverpod-provided; they are passed in from the Riverpod provider that creates the coordinator)
- [ ] **T4.2** Update `lib/features/ai_assistant/application/ai_action_executor.dart`
  - In `execute()`, remove the `ref.invalidate(todayAllTasksRowsProvider)` and `ref.invalidate(openTasksOutsideTodayProvider)` block
  - After each successful `_dispatch(action)`, call `ScheduleMutationCoordinator.instance.run(...)` with the appropriate `MutationRequest`
  - Add `// migrated to coordinator` comment where the old invalidation was
- [ ] **T4.3** Verify no regressions in existing `AiActionExecutor` tests
  - Update mocks/fakes to expect coordinator calls instead of direct invalidations

---

### T5 — Pilot migration: AddTaskScreen

**Goal:** Second live call site. Removes scattered invalidations from the add/edit task save path.

- [ ] **T5.1** Implement live `_commit()` for `TaskCreatedMutation` and `TaskUpdatedMutation` (if not already done in T4.1)
- [ ] **T5.2** Update `lib/features/add_task/presentation/add_task_screen.dart`
  - Replace `invalidateTaskListProviders(ref)` calls in `_onSave()` and `onEntityMoved` with `ScheduleMutationCoordinator.instance.run(...)`
  - Add `// migrated to coordinator` comments
- [ ] **T5.3** Manual smoke test: add a task → confirm coaching focus and proactive suggestions update on Home without pull-to-refresh

---

### T6 — Pilot migration: TasksHubScreen (bulk clean-up)

**Goal:** Removes the 5 scattered `invalidateTaskListProviders` calls in the task hub.

- [ ] **T6.1** Audit `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` — identify each of the 5 invalidation sites and the mutation type each represents
- [ ] **T6.2** Replace each with the appropriate `ScheduleMutationCoordinator.instance.run(...)` call
- [ ] **T6.3** Add `// migrated to coordinator` comments at each site

---

### T7 — Bootstrap event bus subscribers (replace remaining direct invalidations)

**Goal:** Wire Riverpod providers to subscribe to domain events for the remaining call sites that can't easily call the coordinator (e.g. `proactive_suggestion_card`, `goal_detail_screen`).

- [ ] **T7.1** Identify all remaining direct `ref.invalidate` calls outside the coordinator (via grep for `ref.invalidate` and `invalidateTaskListProviders` in widget files)
- [ ] **T7.2** For each remaining call site, evaluate: can it call the coordinator directly, or does it need to subscribe to an event?
  - Call site in a `ConsumerWidget` action → call coordinator directly
  - Call site triggered by an async background event → subscribe to `ScheduleDomainEventBus`
- [ ] **T7.3** Wire `proactiveSuggestionsProvider` to listen to `TaskCreatedEvent | TaskUpdatedEvent | TaskDeletedEvent | TaskCompletedEvent` and self-invalidate (via `ref.invalidateSelf()` in a `ref.listen` subscriber)
- [ ] **T7.4** Wire `analyticsPeriodBundleProvider` similarly for `GoalChangedEvent`
- [ ] **T7.5** Remove the now-redundant explicit `ref.invalidate(analyticsPeriodBundleProvider)` in `goal_detail_screen.dart` and `analytics_progress_screen.dart` once T7.4 is verified

---

### T8 — Verification & success metric checks

- [ ] **T8.1** Run `flutter analyze` — zero new errors or warnings in `lib/core/runtime/`
- [ ] **T8.2** Run `flutter test test/core/runtime/` — all tests green
- [ ] **T8.3** Grep audit: `rg "ref\.invalidate" lib/` — count should be ≤ 20% of pre-migration count (baseline: ~35 call sites → target: ≤ 7 remaining)
- [ ] **T8.4** Grep audit: `rg "invalidateTaskListProviders" lib/` — count should be ≤ 3 (only `PostSyncRefreshCoordinator` adapter and test helpers)
- [ ] **T8.5** Manual test scenario:
  1. Open app on Home
  2. Add a new task for today
  3. Observe: proactive suggestions and coaching focus update without navigation away / pull-to-refresh
  4. Use AI to move a task
  5. Observe: same update behaviour, no console errors about duplicate recomputes
- [ ] **T8.6** Check `flutter logs` for "duplicate recompute" or "generation stale" debug lines — should see exactly one flush cycle per mutation
