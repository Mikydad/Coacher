import 'dart:convert';
import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_generated_insight.dart';
import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/features/analytics/data/insight_cache_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

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

  test('upsert and query by scope/date window', () async {
    final repo = IsarInsightCacheRepository();
    await repo.upsertInsights(<GeneratedInsight>[
      _insight(
        id: 'entity-risk',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        type: InsightType.streakRiskWarning,
        endDateKey: '2026-05-07',
      ),
      _insight(
        id: 'global-risk',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        type: InsightType.goalAtRisk,
        endDateKey: '2026-05-07',
      ),
    ]);

    final entityRows = await repo.listByScope(
      scopeType: InsightScopeType.entity,
      scopeId: 'task-1',
    );
    expect(entityRows, hasLength(1));
    expect(entityRows.single.insightId, 'entity-risk');

    final scoped = await repo.listByScopeAndDateWindow(
      scopeType: InsightScopeType.global,
      scopeId: '2026-05-07',
      startDateKey: '2026-05-01',
      endDateKey: '2026-05-31',
    );
    expect(scoped, hasLength(1));
    expect(scoped.single.insightType, InsightType.goalAtRisk);

    final all = await repo.listAll();
    expect(all, hasLength(2));
  });

  test('reads newer schema rows with compatibility fallback', () async {
    final localIsar = isar!;
    await localIsar.writeTxn(() async {
      await localIsar.isarGeneratedInsights.put(
        IsarGeneratedInsight()
          ..insightId = 'future-insight'
          ..scopeType = InsightScopeType.entity.name
          ..scopeId = 'task-1'
          ..sourceWindowEndDateKey = '2026-05-07'
          ..updatedAtMs = 123
          ..insightType = InsightType.latePattern.name
          ..insightBucket = InsightBucket.neutral.name
          ..priority = InsightPriority.medium.name
          ..payloadJson = jsonEncode(<String, dynamic>{
            'insightId': 'future-insight',
            'scopeType': InsightScopeType.entity.name,
            'scopeId': 'task-1',
            'insightType': InsightType.latePattern.name,
            'insightBucket': InsightBucket.neutral.name,
            'priority': InsightPriority.medium.name,
            'messageKey': 'late_pattern_1',
            'message': 'fallback',
            'action': InsightAction.reschedule.name,
            'linkedPatternCodes': <String>['late_behavior'],
            'confidence': 0.6,
            'detectedAtMs': 123,
            'sourceWindowStartDateKey': '2026-05-01',
            'sourceWindowEndDateKey': '2026-05-07',
            'schemaVersion': 99,
          })
          ..createdAtMs = 123
          ..schemaVersion = 99,
      );
    });

    final repo = IsarInsightCacheRepository();
    final rows = await repo.listByScope(
      scopeType: InsightScopeType.entity,
      scopeId: 'task-1',
    );
    expect(rows, hasLength(1));
    expect(rows.single.insightId, 'future-insight');
    expect(rows.single.schemaVersion, kGeneratedInsightSchemaVersion);
  });

  test('replaceScopeInsights clears stale rows in same scope', () async {
    final repo = IsarInsightCacheRepository();
    await repo.upsertInsights(<GeneratedInsight>[
      _insight(
        id: 'old-a',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        type: InsightType.streakRiskWarning,
        endDateKey: '2026-05-07',
      ),
      _insight(
        id: 'old-b',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        type: InsightType.goalAtRisk,
        endDateKey: '2026-05-07',
      ),
    ]);

    await repo.replaceScopeInsights(
      scopeType: InsightScopeType.global,
      scopeId: '2026-05-07',
      insights: <GeneratedInsight>[
        _insight(
          id: 'new-only',
          scopeType: InsightScopeType.global,
          scopeId: '2026-05-07',
          type: InsightType.goalProgressSuccess,
          endDateKey: '2026-05-07',
        ),
      ],
    );

    final rows = await repo.listByScope(
      scopeType: InsightScopeType.global,
      scopeId: '2026-05-07',
    );
    expect(rows, hasLength(1));
    expect(rows.single.insightId, 'new-only');
  });
}

GeneratedInsight _insight({
  required String id,
  required InsightScopeType scopeType,
  required String scopeId,
  required InsightType type,
  required String endDateKey,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: scopeType,
    scopeId: scopeId,
    insightType: type,
    insightBucket: InsightBucket.risk,
    priority: InsightPriority.high,
    messageKey: '${type.name}_1',
    message: 'fallback message',
    action: InsightAction.focus,
    linkedPatternCodes: const <String>['streak_risk'],
    confidence: 0.9,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: endDateKey,
  );
}
