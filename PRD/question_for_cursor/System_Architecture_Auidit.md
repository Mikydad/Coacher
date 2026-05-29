## System Architecture Audit — Current Runtime Flow

I need a deep architectural audit of how the current runtime systems interact in production conditions.

Please explain the current behavior and execution order for these scenarios in detail:

### 1. Unified Runtime Decision Flow

When ALL of these happen together:

* overlapping tasks exist
* context override is active
* AI assistant modifies schedule
* reminders are already scheduled
* streak computation runs
* CurrentCoachingFocus recomputes
* proactive suggestion engine recomputes

What is the exact runtime order of operations?

Which services trigger first?
Which systems are authoritative?
Which systems can mutate schedule state?
Which systems only observe state?

Please provide:

* actual execution sequence
* dependency graph
* authoritative data owners
* possible race conditions
* stale state risks

---

### 2. Schedule Authority

Right now, which system is the source of truth for time ownership?

Examples:

* TimeBlock system
* ReminderConfig
* Task scheduledAt
* Goal schedules
* overlap engine cache
* AI assistant mutation layer

If two systems disagree, which one wins?

---

### 3. Mutation Pipeline Audit

For these actions:

* manual task edit
* AI assistant edit
* drag/drop reschedule
* overlap resolution
* reminder snooze escalation
* context override activation

Please trace:

* what services fire
* what repositories mutate
* what recomputes
* what gets persisted locally
* what syncs remotely
* what notifications reschedule

Need exact pipeline diagrams.

---

### 4. Current Reactive Graph

Which providers/services currently trigger recomputation for:

* coaching summaries
* proactive suggestions
* streaks
* reminders
* overlap detection
* focus scoring

Need:

* Riverpod dependency graph
* recompute frequency
* debounce/coalescing protections
* duplicate recompute risks

---

### 5. Notification Authority Audit

Right now:

* who decides if a notification should fire?
* who can cancel it?
* who can delay it?
* who owns suppression?
* who owns collision resolution?
* who owns escalation?

Need exact ownership map.

---

### 6. AI Assistant Safety Audit

When the AI assistant executes actions:

* what validation exists?
* what rollback exists?
* what transactional guarantees exist?
* can partial writes happen?
* can reminder/task state diverge?
* can overlaps bypass validation?

Please identify unsafe paths.

---

### 7. Sync & Offline Integrity Audit

Need analysis of:

* offline edits during recompute
* sync conflicts
* stale TimeBlocks
* stale reminders
* local vs remote precedence
* duplicate schedule generation risks

Which systems are eventually consistent vs strongly consistent?

---

### 8. Biggest Architectural Risks

Please identify:

* systems likely to become unstable at scale
* race condition risks
* duplicated authority
* over-coupled modules
* recompute storms
* notification spam risks
* AI mutation risks
* performance bottlenecks

Rank by severity.

---

### 9. Missing Core Infrastructure

Based on the current implementation, what foundational infrastructure is still missing before scaling to:

* subscriptions
* community/groups
* multi-device usage
* heavier AI automation
* large reminder volumes

Focus on architecture gaps, not feature ideas.

---

### 10. Final Assessment

What phase is the app architecture currently in?

Examples:

* feature prototype
* stable MVP
* scalable foundation
* pre-scale refactor stage
* orchestration consolidation phase

And what should the NEXT major engineering focus be?
