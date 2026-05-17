## Relevant Files

- `tasks/prd-insight-engine-layer-4-delivery-engine.md` - Source PRD for Layer 4 delivery engine scope and requirements.
- `lib/features/analytics/domain/models/generated_insight.dart` - Layer 3 insight contract consumed by Layer 4.
- `lib/features/analytics/application/insight_generation_providers.dart` - Upstream Layer 3 providers for scoped insight reads.
- `lib/features/analytics/application/` - Home for Layer 4 selection, suppression, routing, and delivery orchestration logic.
- `lib/features/analytics/domain/models/` - Place for Layer 4 delivery decision/history contracts and enums.
- `lib/features/analytics/data/` - Repository adapters for Layer 4 decision state and delivery history persistence.
- `lib/core/local_db/isar_collections/` - Isar entities/schemas for delivery history and decision snapshots.
- `lib/core/di/providers.dart` - Dependency wiring for Layer 4 repositories/services/providers.
- `lib/features/home/presentation/home_screen.dart` - Home delivery surface integration target.
- `lib/features/analytics/presentation/analytics_progress_screen.dart` - Progress delivery surface integration target.
- `lib/features/timer/` and `lib/features/execution/` - Runtime focus state signals used for interruption safety.
- `lib/core/notifications/` and reminder services - Notification routing integration for allowed Layer 4 decisions.
- `test/features/analytics/` - Unit/integration tests for delivery selection, suppression, routing, and deterministic behavior.
- `test/support/` - Shared fixtures/no-op repositories for predictable delivery policy test setup.

### Notes

- Layer 4 must consume Layer 3 outputs only; it must not generate new insights.
- V1 delivery selection: `1 primary` + optional `1 secondary`.
- V1 surfaces in scope: `home`, `progress`, `notifications`.
- Suppression/cooldown must be adaptive by priority and deterministic.
- Notifications are allowed for high and medium priority insights only when confidence threshold is met.
- Layer 4 must avoid interrupting active task/timer focus flow.
- Before-sleep reflection routing is explicitly out of scope for this V1.

## Tasks

- [x] 1.0 Define Layer 4 delivery contracts and schema versioning
  - [x] 1.1 Define canonical `DeliveryDecision` model (`selectedPrimaryInsightId`, optional secondary ID, target surface, shouldNotify, reason codes, evaluatedAtMs, schemaVersion).
  - [x] 1.2 Define enums/constants for `DeliverySurface`, `DeliveryReasonCode`, and interruption/suppression statuses.
  - [x] 1.3 Define `DeliveryHistoryEntry`/history contract used for cooldown suppression.
  - [x] 1.4 Add schema version constants + compatibility parsing defaults for Layer 4 models.

- [x] 2.0 Implement centralized delivery policy/config
  - [x] 2.1 Create one centralized config object for thresholds/timing windows/notification gates (no scattered magic values).
  - [x] 2.2 Define deterministic ranking policy using Layer 3 priority/confidence and stable tie-breaks.
  - [x] 2.3 Define adaptive cooldown policy by priority (high/medium/low).
  - [x] 2.4 Define low-confidence suppression thresholds and notify confidence thresholds.
  - [x] 2.5 Define timing-profile rules for morning/evening/post-completion delivery preference.

- [x] 3.0 Implement deterministic candidate selection engine
  - [x] 3.1 Build candidate evaluation from Layer 3 insights for a decision cycle.
  - [x] 3.2 Select exactly 1 primary and optional 1 secondary candidate.
  - [x] 3.3 Ensure deterministic fallback to "no delivery" with explicit reason when no candidate passes policy.
  - [x] 3.4 Include deterministic decision reason codes for accepted/rejected candidates.

- [x] 4.0 Implement suppression and interruption safety pipeline
  - [x] 4.1 Add repeated-insight suppression using adaptive cooldown windows and delivery history.
  - [x] 4.2 Add low-confidence suppression.
  - [x] 4.3 Add interruption safety gate to block delivery during active focus/timer flow.
  - [x] 4.4 Emit diagnostics counters for suppressed/blocked candidates by reason.

- [x] 5.0 Implement surface routing and notification decisioning
  - [x] 5.1 Implement deterministic surface routing for Home and Progress outputs.
  - [x] 5.2 Implement notification eligibility logic (high/medium + confidence gate).
  - [x] 5.3 Add routing behavior for "silent" outcomes where no surface should be interrupted.
  - [x] 5.4 Ensure routing decisions remain deterministic for same input/context/history.

- [x] 6.0 Implement Layer 4 orchestration and local persistence
  - [x] 6.1 Build Layer 4 orchestrator entrypoints that accept Layer 3 inputs + runtime context + history.
  - [x] 6.2 Add batch/refresh support for periodic delivery reevaluation.
  - [x] 6.3 Add dedicated Isar persistence for delivery history and latest decision snapshots.
  - [x] 6.4 Add migration-safe compatibility reads for future schema mismatches.

- [x] 7.0 Expose Layer 4 providers/APIs
  - [x] 7.1 Add provider/API for current Home delivery decision.
  - [x] 7.2 Add provider/API for current Progress delivery decision.
  - [x] 7.3 Add provider/API for notification decision/eligibility.
  - [x] 7.4 Add provider/API for delivery run metadata/history and ensure reactive updates after decision recompute.

- [x] 8.0 Integrate Layer 4 outputs into app surfaces
  - [x] 8.1 Wire Home to consume Layer 4 selected primary/secondary decision.
  - [x] 8.2 Wire Progress to consume Layer 4 routed insight decision.
  - [x] 8.3 Wire notification scheduling trigger for eligible delivery decisions.
  - [x] 8.4 Ensure deterministic fallback UI state when Layer 4 returns "no delivery".

- [x] 9.0 Testing and deterministic validation
  - [x] 9.1 Unit tests for ranking/selection policy (primary+secondary + tie-breaks).
  - [x] 9.2 Unit tests for adaptive cooldown suppression by priority.
  - [x] 9.3 Unit tests for low-confidence suppression and interruption safety gates.
  - [x] 9.4 Integration tests for full delivery decision output across Home/Progress/notification routes.
  - [x] 9.5 Persistence tests for Layer 4 decision/history upsert/read/schema compatibility.
  - [x] 9.6 Provider/orchestration tests for update propagation from Layer 3 to Layer 4 decisions.
  - [x] 9.7 Run `flutter analyze` and resolve newly introduced diagnostics.
  - [x] 9.8 Run focused Layer 4 tests, then full `flutter test`.

- [x] 10.0 Manual QA and acceptance gates
  - [x] 10.1 Verify same input + same context + same history always yields identical delivery decision.
  - [x] 10.2 Verify Home/Progress routes show expected selected insight(s) per policy.
  - [x] 10.3 Verify notifications fire only for eligible high/medium insights above confidence gate.
  - [x] 10.4 Verify repeated-insight suppression and active-focus interruption safety in realistic flows.
  - [x] 10.5 Verify no regressions across Layer 1-3 analytics/insight surfaces after Layer 4 wiring.
