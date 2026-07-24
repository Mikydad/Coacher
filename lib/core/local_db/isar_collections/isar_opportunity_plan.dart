import 'package:isar_community/isar.dart';

part 'isar_opportunity_plan.g.dart';

/// LOCAL-ONLY planner output cache: scored slots + prerendered nudge copy for
/// one intention. Never synced — replans must never bump the synced
/// intention's `updatedAtMs`, or whole-record LWW could clobber a genuine
/// user edit from another device (PRD §4.1).
@collection
class IsarOpportunityPlan {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String intentionId;

  /// JSON list of planned slots:
  /// `[{"slot":0,"deliverAtMs":...,"reasonKind":"...","reasonText":"...","body":"..."}]`
  /// slot 0 = primary, 1 = deadline-eve safety, 2 = optional fallback.
  late String slotsJson;

  /// Hash of the planner inputs that produced this plan — replans compare
  /// before rescheduling so unchanged plans don't churn the OS queue.
  late String inputsHash;

  late int computedAtMs;

  /// Signature (`covered|nextSlotMs`) of the coarse projection last mirrored
  /// to Firestore for the server rescue-net (Phase 5). Local-only bookkeeping
  /// so the projection is written ONLY on material change (compared-before-
  /// write), never on every copy tweak. Empty = never mirrored.
  String projectionSig = '';
}
