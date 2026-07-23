import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_opportunity_plan.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/opportunity_slot.dart';

/// LOCAL-ONLY cache of planner output. No outbox, no pull phase — derived
/// data stays on-device so replans never churn the synced intention record.
class OpportunityPlanRepository {
  OpportunityPlanRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  Future<OpportunityPlan?> getByIntentionId(String intentionId) async {
    final row = await _isar.isarOpportunityPlans
        .filter()
        .intentionIdEqualTo(intentionId)
        .findFirst();
    if (row == null) return null;
    return OpportunityPlan.fromRow(row);
  }

  Stream<List<OpportunityPlan>> watchPlans() {
    return _isar.isarOpportunityPlans
        .where()
        .watch(fireImmediately: true)
        .map(
          (rows) =>
              rows.map(OpportunityPlan.fromRow).toList(growable: false),
        );
  }

  Future<void> upsertPlan(OpportunityPlan plan) async {
    final row = IsarOpportunityPlan()
      ..intentionId = plan.intentionId
      ..slotsJson = jsonEncode(
        plan.slots.map((s) => s.toMap()).toList(growable: false),
      )
      ..inputsHash = plan.inputsHash
      ..computedAtMs = plan.computedAtMs;
    await _isar.writeTxn(() async {
      await _isar.isarOpportunityPlans.putByIntentionId(row);
    });
  }

  Future<void> deleteByIntentionId(String intentionId) async {
    await _isar.writeTxn(() async {
      await _isar.isarOpportunityPlans
          .filter()
          .intentionIdEqualTo(intentionId)
          .deleteAll();
    });
  }
}

/// In-memory view of one cached plan.
class OpportunityPlan {
  const OpportunityPlan({
    required this.intentionId,
    required this.slots,
    required this.inputsHash,
    required this.computedAtMs,
  });

  final String intentionId;
  final List<OpportunitySlot> slots;
  final String inputsHash;
  final int computedAtMs;

  static OpportunityPlan fromRow(IsarOpportunityPlan row) {
    List<OpportunitySlot> slots = const [];
    try {
      final decoded = jsonDecode(row.slotsJson) as List;
      slots = decoded
          .map((e) => OpportunitySlot.fromMap(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Corrupt cache rows are treated as no plan — the planner rebuilds.
    }
    return OpportunityPlan(
      intentionId: row.intentionId,
      slots: slots,
      inputsHash: row.inputsHash,
      computedAtMs: row.computedAtMs,
    );
  }
}
