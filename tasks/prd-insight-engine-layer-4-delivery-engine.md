# PRD: Insight Engine Layer 4 - Delivery Engine

## 1) Introduction/Overview

This PRD defines Layer 4 of the AI Coach Insight Engine: the **Delivery Engine**.

Layer 4 decides which generated insight to show, when to show it, and where to route it across app surfaces.

This layer does not compute features (Layer 1), detect patterns (Layer 2), or generate insight meaning (Layer 3). Instead, it answers:

**"What should be delivered now, to which surface, and should we stay quiet?"**

The problem this solves is delivery quality. Even strong insights can feel noisy or useless if shown at the wrong time, too frequently, or during active focus flow.

## 2) Goals

- Select **1 primary insight** and optional **1 secondary insight** per delivery decision cycle.
- Implement timing-aware delivery behavior by context (for example morning, evening, post-completion).
- Enforce suppression and cooldown controls with adaptive windows by priority.
- Route insight deliveries to V1 in-scope surfaces:
  - Home
  - Progress
  - Notifications.
- Gate notification delivery by priority/confidence to avoid alert fatigue:
  - allow high and medium priority when confidence threshold is met.
- Preserve deterministic, testable behavior for same-input repeated runs.

## 3) User Stories

- As a user, I want the app to show the most relevant insight first so I can act quickly.
- As a user, I want insights at useful moments, not while I am actively focused on a task.
- As a user, I want fewer repeated prompts so coaching feels supportive, not spammy.
- As a user, I want urgent/high-value insights to be eligible for notification when it matters.
- As a developer, I want deterministic routing and suppression logic so behavior is predictable and easy to debug.

## 4) Functional Requirements

1. The system must consume Layer 3 outputs as input contract (generated insights + metadata), plus runtime context signals required for delivery decisions.

2. The system must define a canonical Layer 4 decision output schema with at least:
   - `selectedPrimaryInsightId`
   - `selectedSecondaryInsightId` (nullable)
   - `targetSurface` (`home | progress | notification`)
   - `shouldNotify` (boolean)
   - `decisionReasonCodes`
   - `evaluatedAtMs`
   - `schemaVersion`.

3. The system must rank candidate insights deterministically using Layer 3 priority and confidence as primary signals, then apply deterministic tie-breakers.

4. The system must select at most:
   - 1 primary insight
   - optional 1 secondary insight.

5. The system must implement timing rules by context state (for example morning action bias, evening reflection bias, post-completion reinforcement preference) using deterministic rule config.

6. The system must implement suppression/cooldown rules:
   - block repeated delivery of same insight within cooldown window
   - adaptive cooldown by priority (high/medium/low)
   - suppress low-confidence insights below configured threshold.

7. The system must implement interruption safety:
   - avoid delivery that interrupts active task/timer focus flow.

8. The system must route final decision to allowed surfaces in V1:
   - Home card as primary surface
   - Progress screen as supporting surface
   - Notifications when policy allows.

9. The system must gate notification routing:
   - allow high and medium priority insights when confidence is above configured notification threshold.

10. The system must provide deterministic fallback behavior when no candidate passes policy:
    - return "no delivery" decision (silent mode) with reason code.

11. The system must persist delivery history required for suppression/cooldown checks (local-first storage).

12. The system must expose read APIs/providers for:
    - current selected insight decision for Home
    - selected insight decision for Progress
    - notification eligibility decision
    - recent delivery history and metadata.

13. The system must include structured diagnostics/telemetry for:
    - candidates evaluated
    - candidates suppressed (with reasons)
    - selected primary/secondary IDs
    - surface routing decision
    - notify gate decision
    - elapsed decision time.

14. The system must fail safely:
    - malformed insight inputs do not crash the decision pipeline
    - if rule evaluation fails, return deterministic safe fallback (no notification, no interruption).

15. The system must be deterministic:
    - same insight set + same runtime context + same history state => same output decision.

## 5) Non-Goals (Out of Scope)

- Creating new insights or changing Layer 3 insight semantics.
- AI-generated natural language rewriting of messages.
- End-of-day/night reflection feature in V1 (explicitly deferred).
- Multi-device remote orchestration policy tuning in V1.
- User-configurable personalization controls for delivery policy in V1.

## 6) Design Considerations

- Delivery should feel calm and intentional: "speak when useful, stay quiet otherwise."
- Home should prioritize primary insight clarity and actionability.
- Progress should show routed insight context without duplicating noisy prompts.
- Notification copy remains from Layer 3 message contract; Layer 4 decides **if/when**, not copy generation.

## 7) Technical Considerations

- Reuse existing Layer 3 models/providers/repositories as upstream dependencies.
- Centralize timing/suppression/notification thresholds in one versioned config.
- Add local persistence for delivery history (for adaptive suppression windows).
- Keep decision engine pure where possible, with injected runtime context.
- Ensure integration with existing active execution/timer state to honor "do not interrupt" rules.
- Add schema versioning for decision output and history models to support future migration.

## 8) Success Metrics

1. Determinism:
   - 100% parity for same-input repeated decision tests.

2. Relevance/quality:
   - primary insight is always selected from highest-ranked eligible candidates.
   - suppressed/rejected candidates include explicit reason codes.

3. Noise reduction:
   - repeated insight spam reduced by adaptive cooldown behavior in test scenarios.

4. Safety:
   - no interruptive delivery while active focus flow is running.

5. Routing reliability:
   - Home/Progress/notification decisions match configured policy gates in tests.

6. Regression safety:
   - no regressions in existing Layer 1-3 pipelines and analytics surfaces after Layer 4 integration.

## 9) Open Questions

- What exact adaptive cooldown durations should V1 use for high/medium/low priorities?
- Should Home and Progress share one global primary insight or allow per-surface primaries?
- Should notification confidence threshold differ by priority (for example medium stricter than high)?
- Should user-level quiet hours be introduced in Layer 4 or deferred to later layer/version?
