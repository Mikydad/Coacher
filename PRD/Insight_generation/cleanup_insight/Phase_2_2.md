PHASE 2 — CANONICALIZATION + MIGRATION PLAN
Decision

Phase 2 becomes the canonical Layer 2 behavioral surface.

New canonical models:

DetectedBehaviorPattern
GlobalBehaviorPatternSnapshot

Legacy Layer 2 models remain temporarily for migration compatibility only.

Migration Strategy

Use dual-write + compatibility adapters during transition.

DO NOT hard-switch immediately.

Requirements
1. Canonical Layer 2

Refactor orchestrator/providers so:

Layer 1
→ Phase 2 canonical detection
→ canonical persistence
→ compatibility mapping (temporary)
→ existing Layer 3 consumers
2. Persistence

Add canonical repositories + Isar persistence for:

DetectedBehaviorPattern
GlobalBehaviorPatternSnapshot

Requirements:

schema versioned
deterministic upserts
source window tracking
timestamps preserved
3. Compatibility Layer

Create temporary adapters:

DetectedBehaviorPattern
→ legacy DetectedPattern

Only for:

existing Layer 3
existing delivery pipeline
backward compatibility

Goal:
Allow Layer 3 migration incrementally.

4. Pipeline Integration

Extend recompute pipeline:

Layer 1 recompute
→ canonical Layer 2 detection
→ canonical persistence
→ compatibility persistence (temporary)

Ensure:

no duplicate recomputation
deterministic outputs
no semantic divergence
5. Layer 3 Preparation

Add TODO hooks for future migration:

insight_generation_policy
insight mapping engine
new pattern families

Do NOT fully migrate Layer 3 yet.

6. New Pattern Codes

Add support preparation for:

goalProgressDrift
scheduleRhythmVolatile

Do NOT activate user-facing insights yet unless explicitly enabled.

For now:

detectable
persistable
inspectable
testable
7. Debug + Observability

Update debug tooling to display:

canonical patterns
evidence metrics
severity/confidence
compatibility mapping
8. Tests

Add migration safety tests:

canonical ↔ compatibility parity
deterministic recompute parity
persistence reload correctness
no duplicate pattern emissions
backward compatibility stability
Important Architectural Rule

Phase 2 canonical models are now:

the single source of behavioral interpretation truth

Legacy Layer 2 models are:

temporary compatibility artifacts only.

---

# 🧠 About the new codes

Cursor asked:

> should insights fire for new codes now?

My answer:

# ❌ NOT YET

Specifically:
- goalProgressDrift
- scheduleRhythmVolatile

should NOT become major user-facing insights yet.

---

# Why?

Because:
- they are semantically subtle
- easy to overfire
- not yet behaviorally validated
- could create noisy coaching

---

# Better approach

For now:
- detect
- persist
- inspect internally
- collect examples
- validate usefulness

Then later:
- selectively promote to insights

---

# 🧠 VERY IMPORTANT PRODUCT ADVICE

You’re now at the point where:
> every new pattern increases coaching complexity exponentially.

So:
- fewer high-quality patterns > many clever patterns

You do NOT want:
- “analytics soup”
- over-diagnosis
- coaching noise

---

# 🔥 My honest engineering opinion

Your system is now evolving correctly:

Phase 1:
> behavioral truth

Phase 2:
> behavioral interpretation

And choosing A (canonicalization) is the right move because:
- Focus Engine later will rely heavily on these canonical patterns
- AI reasoning later will consume these patterns
- recommendation ranking later depends on stable pattern semantics

So this is the correct foundation to lock in now.