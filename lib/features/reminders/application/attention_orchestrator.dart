import '../../analytics/domain/models/current_coaching_focus.dart';
import '../../coaching/application/coaching_style_delivery_policy.dart';
import '../../coaching/domain/models/coaching_style.dart';
import '../../context_override/application/override_attention_policy.dart';
import '../../context_override/application/sleep_window_util.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../context_override/domain/models/interruption_level.dart';
import '../../context_override/domain/models/user_attention_state.dart';
import '../domain/models/attention_decision.dart';
import '../domain/models/recent_delivery.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_type.dart';

/// Minimum gap (in minutes) enforced between any two delivered notifications.
const int kMinNotificationGapMinutes = 3;

/// Time (in minutes) after a notification fires with no user interaction
/// before it is treated as ignored and a follow-up intent is produced.
const int kIgnoredTimeoutMinutes = 15;

/// Pure Dart class — no I/O, no Riverpod, no Flutter imports.
/// Every public method is static; same inputs always produce the same output.
///
/// Decision pipeline (FR-C-07):
///   1. Context override suppression  (FR-C-10 / FR-C-11)
///   2. Coaching focus boost           (FR-C-12)
///   2b. Coaching focus silence        (FR-C-13)
///   3. Collision gap management       (FR-C-14)
///   3b. Semantic batching             (FR-C-15 / FR-C-16)
///   4. Default approval
abstract final class AttentionOrchestrator {
  /// Evaluate [intent] and return an [AttentionDecision].
  ///
  /// Parameters:
  /// - [intent] — the notification request to evaluate.
  /// - [attentionState] — persisted attention/override state from Phase B.
  /// - [now] — current time (injected for determinism in tests).
  /// - [focus] — active coaching focus, or null if none.
  /// - [recentDeliveries] — deliveries within the last 30 minutes.
  /// - [pendingIntents] — intents in the queue eligible for batching.
  /// - [coachingStyle] — global user coaching style; controls persistence
  ///   philosophy (back-off trigger). Defaults to [CoachingStyle.balanced].
  /// - [consecutiveIgnoredCount] — how many consecutive notifications for
  ///   this entity were ignored without interaction (used by back-off check).
  static AttentionDecision evaluate({
    required ReminderIntent intent,
    required UserAttentionState attentionState,
    required DateTime now,
    CurrentCoachingFocus? focus,
    List<RecentDelivery> recentDeliveries = const [],
    List<ReminderIntent> pendingIntents = const [],
    CoachingStyle coachingStyle = CoachingStyle.balanced,
    int consecutiveIgnoredCount = 0,
  }) {
    // ── Step 1: Context override suppression ─────────────────────────────────
    final activeOverride = effectiveOverride(attentionState, now);
    var level = intent.interruptionLevel;

    // ── Step 1b: CoachingStyle back-off check (FR-D-15 / FR-D-16) ────────────
    // Only applies to follow-up / escalation intents — not the first delivery.
    // Checked before boost so supportive back-off cannot be overridden by
    // focus alignment.
    if (intent.reminderType != ReminderType.scheduled &&
        CoachingStyleDeliveryPolicy.shouldBackOff(
          coachingStyle,
          consecutiveIgnoredCount,
        )) {
      return AttentionDecision.suppressed(
        intentId: intent.id,
        reason: 'CoachingStyle back-off: '
            '${coachingStyle.name} after $consecutiveIgnoredCount ignored',
        retryAllowed: false,
      );
    }

    // ── Step 2: Coaching focus boost ─────────────────────────────────────────
    var priorityBoosted = false;
    if (focus != null && _isFocusAligned(intent, focus)) {
      priorityBoosted = true;
      level = _upgradeLevel(level);
    }

    // ── Suppression check (after potential boost) ─────────────────────────────
    if (OverrideAttentionPolicy.shouldSuppress(level, activeOverride)) {
      return AttentionDecision.suppressed(
        intentId: intent.id,
        reason: 'Active override: ${activeOverride.displayName}',
        retryAllowed: true,
      );
    }

    // ── Step 2b: Focus silence for non-focus low-level intents ───────────────
    if (_shouldSilence(intent, focus, level)) {
      return AttentionDecision.approved(
        intentId: intent.id,
        deliverAt: intent.proposedAt,
        silent: true,
        priorityBoosted: false,
      );
    }

    // ── Step 3: Collision gap management ─────────────────────────────────────
    final collisionDelay = _computeCollisionDelay(
      intent: intent,
      recentDeliveries: recentDeliveries,
      now: now,
    );
    if (collisionDelay != null) {
      return AttentionDecision.delayed(
        intentId: intent.id,
        deliverAt: collisionDelay,
        priorityBoosted: priorityBoosted,
      );
    }

    // ── Step 3b: Semantic batching ────────────────────────────────────────────
    final batchPartner = _findBatchPartner(intent, pendingIntents);
    if (batchPartner != null) {
      return AttentionDecision.batched(
        intentId: intent.id,
        deliverAt: intent.proposedAt,
        batchedWith: [batchPartner.id],
        priorityBoosted: priorityBoosted,
      );
    }

    // ── Step 4: Approve ───────────────────────────────────────────────────────
    return AttentionDecision.approved(
      intentId: intent.id,
      deliverAt: intent.proposedAt,
      silent: false,
      priorityBoosted: priorityBoosted,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns true when [intent] is aligned with the active coaching focus.
  /// Alignment = entityId matches the primary insight OR the entity is
  /// referenced in the context snapshot's insight types.
  static bool _isFocusAligned(
    ReminderIntent intent,
    CurrentCoachingFocus focus,
  ) {
    if (intent.entityId == focus.primaryInsightId) return true;
    if (focus.contextSnapshot.insightTypes.contains(intent.entityId)) {
      return true;
    }
    return false;
  }

  /// Upgrades [level] by one tier. Critical stays critical.
  static InterruptionLevel _upgradeLevel(InterruptionLevel level) {
    switch (level) {
      case InterruptionLevel.low:
        return InterruptionLevel.medium;
      case InterruptionLevel.medium:
        return InterruptionLevel.high;
      case InterruptionLevel.high:
      case InterruptionLevel.critical:
        return InterruptionLevel.critical;
    }
  }

  /// Returns true when the intent should be delivered silently (step 2b):
  /// - Active coaching focus with confidence ≥ 0.75
  /// - Intent is NOT for the focus entity
  /// - Intent is `low` interruption level
  static bool _shouldSilence(
    ReminderIntent intent,
    CurrentCoachingFocus? focus,
    InterruptionLevel resolvedLevel,
  ) {
    if (focus == null) return false;
    if (focus.focusConfidence < 0.75) return false;
    if (_isFocusAligned(intent, focus)) return false;
    return resolvedLevel == InterruptionLevel.low;
  }

  /// Returns the adjusted [deliverAt] if a collision gap violation is found,
  /// or null if delivery can proceed at [intent.proposedAt].
  ///
  /// The lower-importance intent is delayed; the higher-importance (higher
  /// [ReminderIntent.importance]) is delivered first.
  static DateTime? _computeCollisionDelay({
    required ReminderIntent intent,
    required List<RecentDelivery> recentDeliveries,
    required DateTime now,
  }) {
    final gapDuration = Duration(minutes: kMinNotificationGapMinutes);

    DateTime? latestConflictEnd;
    for (final delivery in recentDeliveries) {
      final deliveredAt = delivery.deliveredAt;
      final gapEnd = deliveredAt.add(gapDuration);
      if (intent.proposedAt.isBefore(gapEnd)) {
        // Collision — our proposed time falls within the gap window.
        if (latestConflictEnd == null || gapEnd.isAfter(latestConflictEnd)) {
          latestConflictEnd = gapEnd;
        }
      }
    }
    return latestConflictEnd;
  }

  /// Returns a pending intent that can be batched with [intent], or null.
  ///
  /// Batching criteria (FR-C-16):
  /// - Both levels are low or medium
  /// - Neither is extreme enforcement mode
  /// - proposedAt delta ≤ 5 minutes
  static ReminderIntent? _findBatchPartner(
    ReminderIntent intent,
    List<ReminderIntent> pendingIntents,
  ) {
    if (!_canBeBatched(intent)) return null;
    const batchWindow = Duration(minutes: 5);

    for (final candidate in pendingIntents) {
      if (candidate.id == intent.id) continue;
      if (!_canBeBatched(candidate)) continue;
      final delta = intent.proposedAt.difference(candidate.proposedAt).abs();
      if (delta <= batchWindow) return candidate;
    }
    return null;
  }

  /// Returns true if [intent] is eligible to be batched with another intent.
  static bool _canBeBatched(ReminderIntent intent) {
    final level = intent.interruptionLevel;
    final isLowOrMedium =
        level == InterruptionLevel.low || level == InterruptionLevel.medium;
    final isNotExtreme =
        intent.enforcementMode.trim().toLowerCase() != 'extreme';
    return isLowOrMedium && isNotExtreme;
  }
}
