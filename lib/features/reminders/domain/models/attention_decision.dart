import 'attention_outcome.dart';

/// The output produced by [AttentionOrchestrator.evaluate].
/// Describes exactly what should happen with a [ReminderIntent].
class AttentionDecision {
  const AttentionDecision({
    required this.intentId,
    required this.outcome,
    this.deliverAt,
    this.silent = false,
    this.batchedWith = const [],
    this.suppressedReason,
    this.retryAllowed = false,
    this.priorityBoosted = false,
  });

  /// The [ReminderIntent.id] this decision applies to.
  final String intentId;

  final AttentionOutcome outcome;

  /// When to actually fire. May differ from [ReminderIntent.proposedAt]
  /// when delayed or batched. Null for suppressed outcomes.
  final DateTime? deliverAt;

  /// Deliver without sound/vibration (silent in-app notification center).
  final bool silent;

  /// IDs of other intents merged into this notification (batched outcome only).
  final List<String> batchedWith;

  /// Human-readable suppression reason for debug/trace. Null for non-suppressed.
  final String? suppressedReason;

  /// Whether this intent should be re-evaluated when context changes.
  final bool retryAllowed;

  /// True when delivery priority was boosted due to coaching focus alignment.
  final bool priorityBoosted;

  // ── Named constructors ────────────────────────────────────────────────────

  factory AttentionDecision.approved({
    required String intentId,
    required DateTime deliverAt,
    bool silent = false,
    bool priorityBoosted = false,
  }) => AttentionDecision(
    intentId: intentId,
    outcome: AttentionOutcome.approved,
    deliverAt: deliverAt,
    silent: silent,
    priorityBoosted: priorityBoosted,
  );

  factory AttentionDecision.suppressed({
    required String intentId,
    required String reason,
    bool retryAllowed = true,
  }) => AttentionDecision(
    intentId: intentId,
    outcome: AttentionOutcome.suppressed,
    suppressedReason: reason,
    retryAllowed: retryAllowed,
  );

  factory AttentionDecision.delayed({
    required String intentId,
    required DateTime deliverAt,
    bool priorityBoosted = false,
  }) => AttentionDecision(
    intentId: intentId,
    outcome: AttentionOutcome.delayed,
    deliverAt: deliverAt,
    priorityBoosted: priorityBoosted,
  );

  factory AttentionDecision.batched({
    required String intentId,
    required DateTime deliverAt,
    required List<String> batchedWith,
    bool priorityBoosted = false,
  }) => AttentionDecision(
    intentId: intentId,
    outcome: AttentionOutcome.batched,
    deliverAt: deliverAt,
    batchedWith: batchedWith,
    priorityBoosted: priorityBoosted,
  );

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'intentId': intentId,
    'outcome': outcome.toStorage(),
    if (deliverAt != null) 'deliverAt': deliverAt!.toIso8601String(),
    'silent': silent,
    'batchedWith': batchedWith,
    if (suppressedReason != null) 'suppressedReason': suppressedReason,
    'retryAllowed': retryAllowed,
    'priorityBoosted': priorityBoosted,
  };

  static AttentionDecision fromMap(Map<String, dynamic> map) {
    final rawDeliverAt = map['deliverAt'] as String?;
    final rawBatched = map['batchedWith'];
    final batchedWith = rawBatched is List
        ? rawBatched.whereType<String>().toList(growable: false)
        : const <String>[];
    return AttentionDecision(
      intentId: map['intentId'] as String,
      outcome: AttentionOutcome.fromStorage(map['outcome'] as String?),
      deliverAt: rawDeliverAt != null ? DateTime.parse(rawDeliverAt) : null,
      silent: map['silent'] as bool? ?? false,
      batchedWith: batchedWith,
      suppressedReason: map['suppressedReason'] as String?,
      retryAllowed: map['retryAllowed'] as bool? ?? false,
      priorityBoosted: map['priorityBoosted'] as bool? ?? false,
    );
  }
}
