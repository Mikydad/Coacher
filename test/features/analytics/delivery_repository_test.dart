import 'dart:convert';
import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_delivery_decision_snapshot.dart';
import 'package:coach_for_life/core/local_db/isar_collections/isar_delivery_history_entry.dart';
import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/features/analytics/data/delivery_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/delivery_decision.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('persists and reads latest decision snapshot by scope/surface', () async {
    final repo = IsarDeliveryRepository();
    final decision = DeliveryDecision(
      selectedPrimaryInsightId: 'i-1',
      selectedSecondaryInsightId: 'i-2',
      targetSurface: DeliverySurface.home,
      shouldNotify: false,
      decisionReasonCodes: const <DeliveryReasonCode>[
        DeliveryReasonCode.selectedPrimary,
      ],
      evaluatedAtMs: 100,
    );
    await repo.upsertDecision(
      scopeId: '2026-05-07',
      surface: DeliverySurface.home,
      decision: decision,
    );

    final loaded = await repo.readDecision(
      scopeId: '2026-05-07',
      surface: DeliverySurface.home,
    );
    expect(loaded, isNotNull);
    expect(loaded!.selectedPrimaryInsightId, 'i-1');
    expect(loaded.selectedSecondaryInsightId, 'i-2');
    expect(loaded.targetSurface, DeliverySurface.home);
  });

  test('logs scope history and filters by surface', () async {
    final repo = IsarDeliveryRepository();
    await repo.logHistory(
      DeliveryHistoryEntry(
        insightId: 'home-1',
        surface: DeliverySurface.home,
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        deliveredAtMs: 300,
        priority: InsightPriority.high,
        confidence: 0.8,
        suppressionStatus: DeliverySuppressionStatus.none,
        cooldownUntilMs: 600,
      ),
    );
    await repo.logHistory(
      DeliveryHistoryEntry(
        insightId: 'progress-1',
        surface: DeliverySurface.progress,
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        deliveredAtMs: 400,
        priority: InsightPriority.medium,
        confidence: 0.7,
        suppressionStatus: DeliverySuppressionStatus.none,
        cooldownUntilMs: 700,
      ),
    );

    final all = await repo.listHistoryForScope(scopeId: '2026-05-07');
    expect(all, hasLength(2));
    expect(all.first.deliveredAtMs, 400);

    final onlyHome = await repo.listHistoryForScope(
      scopeId: '2026-05-07',
      surface: DeliverySurface.home,
    );
    expect(onlyHome, hasLength(1));
    expect(onlyHome.single.insightId, 'home-1');
  });

  test('reads newer schema rows with compatibility fallback', () async {
    final localIsar = isar!;
    await localIsar.writeTxn(() async {
      await localIsar.isarDeliveryDecisionSnapshots.put(
        IsarDeliveryDecisionSnapshot()
          ..snapshotId = 'delivery::decision::home::2026-05-07'
          ..scopeId = '2026-05-07'
          ..surface = DeliverySurface.home.name
          ..updatedAtMs = 500
          ..payloadJson = jsonEncode(<String, dynamic>{
            'selectedPrimaryInsightId': 'future',
            'selectedSecondaryInsightId': null,
            'targetSurface': DeliverySurface.home.name,
            'shouldNotify': false,
            'decisionReasonCodes': <String>[DeliveryReasonCode.selectedPrimary.name],
            'evaluatedAtMs': 500,
            'schemaVersion': 99,
          })
          ..createdAtMs = 500
          ..schemaVersion = 99,
      );
      await localIsar.isarDeliveryHistoryEntrys.put(
        IsarDeliveryHistoryEntry()
          ..historyId = 'delivery::history::2026-05-07::future::500'
          ..insightId = 'future'
          ..scopeId = '2026-05-07'
          ..surface = DeliverySurface.home.name
          ..deliveredAtMs = 500
          ..payloadJson = jsonEncode(<String, dynamic>{
            'insightId': 'future',
            'surface': DeliverySurface.home.name,
            'scopeType': InsightScopeType.global.name,
            'scopeId': '2026-05-07',
            'deliveredAtMs': 500,
            'priority': InsightPriority.high.name,
            'confidence': 0.95,
            'suppressionStatus': DeliverySuppressionStatus.none.name,
            'cooldownUntilMs': 1000,
            'schemaVersion': 99,
          })
          ..createdAtMs = 500
          ..schemaVersion = 99,
      );
    });

    final repo = IsarDeliveryRepository();
    final decision = await repo.readDecision(
      scopeId: '2026-05-07',
      surface: DeliverySurface.home,
    );
    final history = await repo.listHistoryForScope(scopeId: '2026-05-07');
    expect(decision, isNotNull);
    expect(decision!.schemaVersion, kDeliveryDecisionSchemaVersion);
    expect(history, hasLength(1));
    expect(history.single.schemaVersion, kDeliveryHistorySchemaVersion);
  });
}
