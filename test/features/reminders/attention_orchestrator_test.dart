import 'package:coach_for_life/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:coach_for_life/features/context_override/domain/models/context_override.dart';
import 'package:coach_for_life/features/context_override/domain/models/interruption_level.dart';
import 'package:coach_for_life/features/context_override/domain/models/user_attention_state.dart';
import 'package:coach_for_life/features/reminders/application/attention_orchestrator.dart';
import 'package:coach_for_life/features/reminders/domain/models/attention_outcome.dart';
import 'package:coach_for_life/features/reminders/domain/models/recent_delivery.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_intent.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_type.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 5, 18, 10, 0);

ReminderIntent _intent({
  String id = 'i1',
  String entityId = 'task_1',
  InterruptionLevel level = InterruptionLevel.medium,
  String enforcementMode = 'disciplined',
  int escalationLevel = 0,
  DateTime? proposedAt,
}) => ReminderIntent(
  id: id,
  entityId: entityId,
  entityKind: 'task',
  entityTitle: 'Test Task',
  proposedAt: proposedAt ?? _now.add(const Duration(minutes: 5)),
  importance: 50,
  interruptionLevel: level,
  enforcementMode: enforcementMode,
  escalationLevel: escalationLevel,
  reminderType: ReminderType.scheduled,
  sourceReason: 'test',
  createdAtMs: _now.millisecondsSinceEpoch,
);

UserAttentionState _attentionState({
  ContextOverride override = ContextOverride.none,
  DateTime? expiresAt,
}) => UserAttentionState(
  id: 'user_attention_state',
  activeOverride: override,
  manuallyMuted: false,
  overrideExpiresAt: expiresAt,
  updatedAtMs: _now.millisecondsSinceEpoch,
);

CurrentCoachingFocus _focus({
  String primaryInsightId = 'task_1',
  double confidence = 0.9,
}) => CurrentCoachingFocus(
  focusId: 'f1',
  primaryInsightId: primaryInsightId,
  lifecycleState: FocusLifecycleState.active,
  focusReason: FocusReason.highestMomentumLeverage,
  focusScore: 0.8,
  focusConfidence: confidence,
  scoreBreakdown: FocusScoreBreakdown(
    urgencyScore: 0.8,
    momentumScore: 0.8,
    feasibilityScore: 0.8,
    riskScore: 0.5,
    recoveryScore: 0.5,
    focusScore: 0.8,
  ),
  contextSnapshot: const FocusContextSnapshot(
    insightTypes: [],
    keyPatternCodes: [],
    topEvidence: {},
    selectedRationale: 'test',
    timingProfile: 'morning',
  ),
  evaluationTrace: const [],
  suppressedCandidates: const [],
  sourceInsightTypes: const [],
  detectedAtMs: _now.millisecondsSinceEpoch,
  activeUntilMs: _now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AttentionOrchestrator', () {
    // ── Approval ──────────────────────────────────────────────────────────────

    test('approves intent when no override and no collision', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(),
        attentionState: _attentionState(),
        now: _now,
      );

      expect(decision.outcome, AttentionOutcome.approved);
      expect(decision.silent, isFalse);
      expect(decision.priorityBoosted, isFalse);
    });

    // ── Override suppression ─────────────────────────────────────────────────

    test('suppresses low intent during meeting override', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.low),
        attentionState: _attentionState(override: ContextOverride.meeting),
        now: _now,
      );

      expect(decision.outcome, AttentionOutcome.suppressed);
      expect(decision.retryAllowed, isTrue);
      expect(decision.suppressedReason, contains('Meeting'));
    });

    test('suppresses medium intent during focus override', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.medium),
        attentionState: _attentionState(override: ContextOverride.focus),
        now: _now,
      );
      expect(decision.outcome, AttentionOutcome.suppressed);
    });

    test('passes high intent through meeting override (not suppressed)', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.high),
        attentionState: _attentionState(override: ContextOverride.meeting),
        now: _now,
      );
      expect(decision.outcome, AttentionOutcome.approved);
    });

    test('suppresses high intent during sleep override', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.high),
        attentionState: _attentionState(override: ContextOverride.sleep),
        now: _now,
      );
      expect(decision.outcome, AttentionOutcome.suppressed);
    });

    test('passes critical intent through sleep override', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.critical),
        attentionState: _attentionState(override: ContextOverride.sleep),
        now: _now,
      );
      expect(decision.outcome, AttentionOutcome.approved);
    });

    test('suppresses everything during doNotDisturb override', () {
      for (final level in InterruptionLevel.values) {
        final decision = AttentionOrchestrator.evaluate(
          intent: _intent(level: level),
          attentionState:
              _attentionState(override: ContextOverride.doNotDisturb),
          now: _now,
        );
        expect(
          decision.outcome,
          AttentionOutcome.suppressed,
          reason: 'level=$level should be suppressed by doNotDisturb',
        );
      }
    });

    // ── Focus boost ───────────────────────────────────────────────────────────

    test('boosts priority when intent matches focus entity', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(entityId: 'task_1', level: InterruptionLevel.medium),
        attentionState: _attentionState(),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1'),
      );

      expect(decision.priorityBoosted, isTrue);
      expect(decision.outcome, AttentionOutcome.approved);
    });

    test('focus boost upgrades level so meeting suppression is bypassed', () {
      // medium → boosted to high → high passes through meeting (only low/medium suppressed)
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(entityId: 'task_1', level: InterruptionLevel.medium),
        attentionState: _attentionState(override: ContextOverride.meeting),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1'),
      );

      expect(decision.priorityBoosted, isTrue);
      expect(decision.outcome, AttentionOutcome.approved);
    });

    test('focus boost does not bypass sleep override for high level', () {
      // medium → boosted to high → sleep still suppresses high
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(entityId: 'task_1', level: InterruptionLevel.medium),
        attentionState: _attentionState(override: ContextOverride.sleep),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1'),
      );

      expect(decision.outcome, AttentionOutcome.suppressed);
    });

    // ── Focus silence ─────────────────────────────────────────────────────────

    test('silences low-level non-focus intent when confidence >= 0.75', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          entityId: 'other_task',
          level: InterruptionLevel.low,
        ),
        attentionState: _attentionState(),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1', confidence: 0.8),
      );

      expect(decision.outcome, AttentionOutcome.approved);
      expect(decision.silent, isTrue);
    });

    test('does not silence when focus confidence < 0.75', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          entityId: 'other_task',
          level: InterruptionLevel.low,
        ),
        attentionState: _attentionState(),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1', confidence: 0.6),
      );

      expect(decision.silent, isFalse);
    });

    test('does not silence medium-level non-focus intent', () {
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          entityId: 'other_task',
          level: InterruptionLevel.medium,
        ),
        attentionState: _attentionState(),
        now: _now,
        focus: _focus(primaryInsightId: 'task_1', confidence: 0.9),
      );

      expect(decision.silent, isFalse);
    });

    // ── Collision gap ─────────────────────────────────────────────────────────

    test('delays intent when within 3-minute gap of recent delivery', () {
      final recentAt = _now.subtract(const Duration(minutes: 1));
      final recentDelivery = RecentDelivery(
        entityId: 'other_entity',
        deliveredAtMs: recentAt.millisecondsSinceEpoch,
        interruptionLevel: InterruptionLevel.medium,
      );

      final proposedAt = _now; // within gap window (1 min after delivery)
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(proposedAt: proposedAt),
        attentionState: _attentionState(),
        now: _now,
        recentDeliveries: [recentDelivery],
      );

      expect(decision.outcome, AttentionOutcome.delayed);
      expect(
        decision.deliverAt!.isAfter(proposedAt),
        isTrue,
        reason: 'deliverAt should be pushed beyond the gap',
      );
    });

    test('does not delay when outside 3-minute gap', () {
      final recentAt = _now.subtract(const Duration(minutes: 5));
      final recentDelivery = RecentDelivery(
        entityId: 'other_entity',
        deliveredAtMs: recentAt.millisecondsSinceEpoch,
        interruptionLevel: InterruptionLevel.medium,
      );

      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(proposedAt: _now.add(const Duration(minutes: 1))),
        attentionState: _attentionState(),
        now: _now,
        recentDeliveries: [recentDelivery],
      );

      expect(decision.outcome, AttentionOutcome.approved);
    });

    // ── Semantic batching ─────────────────────────────────────────────────────

    test('batches two low-level non-extreme intents within 5 minutes', () {
      final partner = _intent(
        id: 'i2',
        entityId: 'task_2',
        level: InterruptionLevel.low,
        enforcementMode: 'flexible',
        proposedAt: _now.add(const Duration(minutes: 3)),
      );

      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          level: InterruptionLevel.low,
          enforcementMode: 'flexible',
          proposedAt: _now.add(const Duration(minutes: 5)),
        ),
        attentionState: _attentionState(),
        now: _now,
        pendingIntents: [partner],
      );

      expect(decision.outcome, AttentionOutcome.batched);
      expect(decision.batchedWith, contains('i2'));
    });

    test('does not batch extreme-mode intent', () {
      final partner = _intent(
        id: 'i2',
        entityId: 'task_2',
        level: InterruptionLevel.high,
        enforcementMode: 'extreme',
        proposedAt: _now.add(const Duration(minutes: 1)),
      );

      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          level: InterruptionLevel.high,
          enforcementMode: 'extreme',
          proposedAt: _now.add(const Duration(minutes: 2)),
        ),
        attentionState: _attentionState(),
        now: _now,
        pendingIntents: [partner],
      );

      expect(decision.outcome, isNot(AttentionOutcome.batched));
    });

    test('does not batch intents more than 5 minutes apart', () {
      final partner = _intent(
        id: 'i2',
        entityId: 'task_2',
        level: InterruptionLevel.low,
        enforcementMode: 'flexible',
        proposedAt: _now,
      );

      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(
          level: InterruptionLevel.low,
          enforcementMode: 'flexible',
          proposedAt: _now.add(const Duration(minutes: 10)),
        ),
        attentionState: _attentionState(),
        now: _now,
        pendingIntents: [partner],
      );

      expect(decision.outcome, isNot(AttentionOutcome.batched));
    });

    // ── Expired override ─────────────────────────────────────────────────────

    test('treats expired override as none — intent approved', () {
      // expiresAt is in the past → effectiveOverride returns none
      final decision = AttentionOrchestrator.evaluate(
        intent: _intent(level: InterruptionLevel.low),
        attentionState: _attentionState(
          override: ContextOverride.meeting,
          expiresAt: _now.subtract(const Duration(minutes: 5)),
        ),
        now: _now,
      );

      expect(decision.outcome, AttentionOutcome.approved);
    });
  });
}
