Executive verdict
Section 8’s central diagnosis holds: the pipeline around the model is solid, but confirmed mutations often lie. Five advertised verbs are no-op stubs that return success strings; editTask creates a duplicate; undo/rollback cannot revert creates; the undo-warning Cancel is cosmetic; and the global Undo chip does not refresh after confirm. Section 8’s “None were refuted” headline is accurate for the scoped E/H/R/U claims checked here — none of those were overturned. A few refinements and one additional concrete gap are noted below.

Section 8 claim verification
E* — Execution integrity
ID	Section 8 claim	Verdict	Evidence
E1
Five mutation kinds are no-op stubs reporting success
CONFIRMED CRITICAL
_moveTask 965:969, _deleteTask 972:976, _modifyGoal 1021:1024, _deleteGoal 1027:1030, _removeReminder 1065:1068 — all return success strings with // Full implementation comments. Tools advertised in ai_operating_layer_client.dart:304-323, capabilities in ai_capability_registry.dart:13-17, chips in quick_directives_provider.dart:20-38.
E2
editTask creates duplicate with fresh id
CONFIRMED HIGH
912:963 — comment “Simplified: upsert a new task”, StableId.generate('task'), priority 3, orderIndex 0, no modeRefId/tier guard.
E3
Undo cannot revert creations
CONFIRMED HIGH
_captureSnapshot 312:360 snapshots existing task rows only; _rollbackBatch 366:413 re-upserts snapshot only. Pre-assign exists for intentions/memory (147:172, _rollbackCreatedIntentions 418:437) but not for createTask/createGoal (872, 1003).
E4
Undo-warning Cancel is fake — rollback already ran
CONFIRMED HIGH
_undoBatch 298:301 calls _rollbackBatch before returning UndoWarningTasksCompleted; dialog 1706:1747 with comment 1737; Cancel path (1723:1724) does not re-apply or invalidate.
E5
Undo chip stale after confirm; non-watch providers
CONFIRMED HIGH
lastAiBatchProvider/canUndoLastAiBatchProvider 159:175 — FutureProvider, only authUidProvider watch. Invalidations only in undo handlers 1702-1704, 1744-1746, 1873-1874. confirmPlan never invalidates (719:831).
E6
Decorative action poisons batch; successes discarded
CONFIRMED HIGH
suggestFreeTimeBlock/moveConflictingTasks throw 641:646; partial failure rolls back and returns empty successes 246:249 with misleading copy 248.
E7
Rollback leaves OS notifications
CONFIRMED MED
_rollbackBatch restores tasks only; _upsertReminderForTask 1230:1276 schedules sync; no cancel/delete on rollback.
E8
Crash mid-batch → executing forever
CONFIRMED MED
State transition 202; _undoBatch refuses non-completed 277:284; idempotency guard dead 175-182 (fresh batchId per call 144).
E9
Unvalidated dates → phantom days / today fallback
CONFIRMED MED
_resolveDate 1287:1295 passes raw strings; _parseReminderDateTime catch → DateTime.now() 1160:1164.
E10
Deduplicator date-blind (today-only set)
CONFIRMED MED
AiPlanDeduplicator doc 3:6; fed payload.activeTasks from _buildActiveTasks() → today only 354:357; filter 271:284.
E11
Preview card omits edit deltas
CONFIRMED MED
describePlannedAction 212:213, 229:230 — title only; reminders show time 235:238.
E12
Voice confirm skips conflict/hard-block warnings
CONFIRMED MED
formatPlanForSpeech 11:27 — actions only; _handlePendingPlanShortReply 1049:1060 → confirmPlan() with no isBlockedByContext check. Screen card disables/warns planned_changes_card.dart:384-403; voice bypasses.
E13–E17
Assumption copy, forget disambiguation, collision quirks, tier bypass, unknown→createTask
CONFIRMED at cited lines (not re-litigated in depth).
H* — Honesty & failure story
ID	Verdict	Evidence
H1
CONFIRMED MED (downgrade appropriate)
No isError on AiChatMessage (ai_chat_message.dart:15-29); input cleared before send 1019:1023; parser maps failures to followUpQuestion 184:198; auto-commit comment “Telegram-style” 645 but no retry UI 664:679.
H2
CONFIRMED MED
confirmPlan 752:787 — _setLoading(true), await execute(), await markConfirmed/markExecuted, no try/catch/finally. Auto-commit path has try/catch 652:656.
H3
CONFIRMED MED
ai_proxy_client.dart:33-34 — deadline-exceeded → isNetwork; propagated ai_operating_layer_client.dart:426-431 → offline copy ai_intent_parser.dart:187-189.
H7
CONFIRMED HIGH
_estimateGoalProgress hardcodes 0 431:437; behindPct = gap * 100 298-307.
H8
CONFIRMED MED
Every turn saves confirmed=false 47; getMostRecentUnconfirmed filters only confirmed+time 147:158, not parsedActions.
H10
CONFIRMED LOW
Network errors returned as followUpQuestion 193, rendered as normal bubble 292-303.
R* — Races & state lifecycle
ID	Verdict	Evidence
R1
CONFIRMED HIGH
Sheet whenComplete → startNewSession() 105:113; service clears thread 916:929; _parseAndRespond has no turn-generation guard 198:427. Late reply mutates new session + persists history 406-412.
R2
CONFIRMED MED
Confirm onConfirm: () => service.confirmPlan(...) 1476; disabled only via isLoading at build 403; confirmPlan no reentrancy guard 719+; idempotency guard ineffective 144, 175-182.
R3
CONFIRMED MED
sendMessage no in-flight guard 117+; _isLoading bool 73; auto-send from build path 485-489 can overlap with user send.
R5
CONFIRMED MED
userInput persisted uncapped 43; only assistantSummary capped 37-38.
(R4, R6–R9 not in scope list; spot-check: R6 comment/provider mismatch at ai_assistant_providers.dart:217-218 still present.)

U* — Chat surface UX
ID	Verdict	Evidence
U1
CONFIRMED HIGH
Composer disabled via isLoading 1018; no Stop/cancel on typed agent path; _parseAndRespond holds loading up to 4×20s rounds.
U2
CONFIRMED HIGH
Suggestions/help/first-time card gated if (!widget.sheetMode) 904-916; sheet always sheetMode: true 243-244; sheet header has no Help 822-844 vs tab AppBar 859.
U3
CONFIRMED MED
_scrollToBottom() on every body build with messages 893-897.
U4
CONFIRMED MED
Loading bubble isLoading: true 204-211; list adds extra ThinkingIndicator when isLoading 1268-1272 + per-message 1461.
U5
CONFIRMED MED
Undo snackbars via root ScaffoldMessenger.of(context) 1696-1752 under modal sheet.
U6
CONFIRMED MED
Fast fling dismiss 797-804 → onSheetDismiss → whenComplete session wipe.
Section 8 claims that are stale, overstated, or need nuance
Claim	Assessment
“None were refuted” (line 424)
Accurate for E/H/R/U items verified here. Does not cover V/S/M server-side items outside this pass.
E5 “first mount after confirm can show chip correctly once”
Accurate nuance, not stale: true only if canUndoLastAiBatchProvider was never watched before confirm; any prior watch caches false indefinitely.
H2 “DB closed on logout trigger”
Correctly narrowed in Section 8; no longer stated as primary trigger. Still valid as latent gap.
H6 mock summary “only test button”
Still accurate: analytics_progress_screen.dart:98-102 “Test AI coaching summary”; kill-switch chat mock buildAiOperatingLayerClient 871-873, MockAiOperatingLayerClient 916-928.
E6 “rolls back everything”
Slightly overstated — rollback restores snapshotted tasks but does not delete succeeded creates (E3 compounding). User impact is worse than “restored”: duplicates/orphans remain.
Branch note feat/ux-fixes-and-stake-surrender (line 415)
Metadata only — findings match current tree regardless of branch name.
Additional concrete defects (not fully covered in Section 8)
Sev	Finding	Evidence	User impact	In §8?
HIGH
_resolvedTaskId is never written — coordinator always gets 'ai-task'
Reads only at ai_action_executor.dart:543,552,560,572,590; no writes anywhere in lib/features/ai_assistant/
Schedule mutation coordinator / notifications use placeholder entity ids after real creates
Partially (E17 coordinator note); root cause not isolated
MED
recentAiBatchesProvider also stale after confirm
Same invalidation gap as E5; count/link “View recent AI changes” wrong until undo
Misleading history affordance
Implied by E5, not explicit
MED
_findTaskRowByTitle is exact lowercase match only
1148:1152
Even when stubs are implemented, “Gym” vs “gym workout” won’t resolve; title hallucinations execute against wrong/missing row
Mentioned in §8.9 roadmap, not as current defect
MED
Undo-warning Cancel: user thinks they cancelled, data already reverted
E4 mechanism + Cancel skips snackbar/invalidate 1723-1747
Completions reverted silently; user believes Cancel preserved state
E4 covers mechanism; silent wrong mental model underemphasized
Meaningful test gaps
Gap	What exists	What’s missing
Executor stub honesty (E1/E2)
ai_action_executor_enforcement_test.dart tests an extracted pure function, not AiActionExecutor
Integration tests asserting _moveTask/_deleteTask/_modifyGoal/_deleteGoal/_removeReminder mutate Isar; test that _editTask preserves task id
Undo/rollback (E3/E4/E7)
ai_action_batch_repository_test.dart — state transitions only
Tests: createTask batch → undo leaves task; partial failure + decorative action; rollback cancels reminders; Cancel on UndoWarning does not restore completions
Undo chip staleness (E5)
None
Widget/provider test: confirm plan → canUndoLastAiBatchProvider becomes true without manual invalidate
confirmPlan robustness (H2/R2)
voice_plan_confirmation_test.dart uses _RecordingExecutor mock
Test: executor throws → loading clears, card still confirmable; double-tap confirm → single batch
Sheet-close race (R1)
None
_parseAndRespond in flight → startNewSession() → no message/history on new session
Voice blocked confirm (E12)
formatPlanForSpeech unit tests
Service test: plan with isBlockedByContext + spoken “confirm” → should refuse or require second affirmation
Failure/retry (H1)
Parser exception tests scattered
End-to-end: network error bubble has retry; no isError field tests because field doesn’t exist
Pick-up banner (H8)
None
Informational turn → getMostRecentUnconfirmed should not surface banner
Proactive behind-pace (H7)
proactive_suggestion_engine_test.dart (rules, not progress)
Test with on-track goal at day 27/30 → must not emit ~90% behind
Well-covered areas (Section 8.8 justified): clarify-loop merge/carryforward, delete guard, agent loop hardening, param normaliser, deduplicator (today-only), conflict detector unit tests, voice plan speech formatting, capability registry.

Pipeline orientation (verified)
sendMessage → guards (guest, yes/no, decline)
  → _parseAndRespond → AiIntentParser.parse
    → assemble payload → agent loop (≤4 rounds, aiChat)
    → guards/normaliser/dedupe/conflicts → preview card
  → confirmPlan → AiActionExecutor.execute → batch persist → markConfirmed/markExecuted
Strong parts confirmed: confirm-gate topology for screen taps; auto-commit undo for intentions/memory with pre-assigned ids; intention/memory rollback paths; unrequested-delete guard; bounded agent loop; local-first execute (no awaited Firestore on confirm path).

Broken last mile: executor dispatch for move/delete/edit/goal/reminder-remove; undo for creates; honest failure/retry on chat; provider-driven undo affordance.

Priority alignment with Section 8.10
Section 8’s ordering remains correct. Highest leverage unchanged:

E1+E2 (or de-advertise broken verbs immediately)
E4 fake Cancel
E3+E5+E6 undo that actually undoes + chip refresh
H1+H2+R1+R2 failure honesty and races
U2 restore suggestions/help in sheet