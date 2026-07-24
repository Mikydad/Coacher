import 'intention.dart';
import 'opportunity_slot.dart';

/// The coarse plan projection the server rescue-net reads (humanizing
/// Phase 5, PRD §8). ONE tiny synced doc per intention that answers the
/// single question the server cannot answer on its own: *does a client
/// already have a slot covering this closing window, and when?*
///
/// The local `IsarOpportunityPlan` (scored slots + prerendered copy) is
/// deliberately never synced — replicating it would churn Firestore and
/// leak delivery internals. This projection carries only `covered` +
/// `nextSlotMs`, written **only on material change** (compared-before-
/// write via [signature]) so replans never touch the user-edited
/// intention record.
class IntentionProjection {
  const IntentionProjection({
    required this.intentionId,
    required this.covered,
    required this.nextSlotMs,
    required this.windowEndMs,
    required this.updatedAtMs,
  });

  final String intentionId;

  /// True when the client has at least one future slot scheduled — the
  /// sweep leaves covered intentions alone.
  final bool covered;

  /// Earliest future slot delivery time, or null when uncovered.
  final int? nextSlotMs;

  /// The intention's deadline (mirrored so the sweep's "window closing"
  /// rule needs no extra read; the intention doc carries the truth for LWW).
  final int windowEndMs;

  final int updatedAtMs;

  /// Coverage signature for compare-before-write. Excludes [updatedAtMs] and
  /// [windowEndMs] deliberately: a re-stamp with the same coverage must NOT
  /// trigger a mirror write. Window changes flow through the synced
  /// intention doc, which the sweep reads directly.
  String get signature => '${covered ? 1 : 0}|${nextSlotMs ?? -1}';

  Map<String, dynamic> toMap() => {
    'intentionId': intentionId,
    'covered': covered,
    'nextSlotMs': nextSlotMs,
    'windowEndMs': windowEndMs,
    'updatedAtMs': updatedAtMs,
  };

  /// Derives the projection from an intention and its scheduled ladder.
  /// [nowMs] filters already-past slots so a fired-but-not-cleared slot
  /// never masks a genuinely uncovered promise.
  static IntentionProjection fromPlan({
    required Intention intention,
    required List<OpportunitySlot> slots,
    required int nowMs,
  }) {
    final future = slots
        .map((s) => s.deliverAtMs)
        .where((ms) => ms > nowMs)
        .toList(growable: false)
      ..sort();
    final nextSlotMs = future.isEmpty ? null : future.first;
    return IntentionProjection(
      intentionId: intention.id,
      covered: nextSlotMs != null,
      nextSlotMs: nextSlotMs,
      windowEndMs: intention.windowEndMs,
      updatedAtMs: nowMs,
    );
  }
}
