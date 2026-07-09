import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_generated_insight.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/generated_insight.dart';

abstract class InsightCacheRepository {
  Future<void> upsertInsight(GeneratedInsight insight);
  Future<void> upsertInsights(List<GeneratedInsight> insights);
  Future<void> replaceScopeInsights({
    required InsightScopeType scopeType,
    required String scopeId,
    required List<GeneratedInsight> insights,
  });
  Future<List<GeneratedInsight>> listByScope({
    required InsightScopeType scopeType,
    required String scopeId,
  });
  Future<List<GeneratedInsight>> listByScopeAndDateWindow({
    required InsightScopeType scopeType,
    required String scopeId,
    String? startDateKey,
    String? endDateKey,
  });
  Future<List<GeneratedInsight>> listAll();
}

class IsarInsightCacheRepository implements InsightCacheRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertInsight(GeneratedInsight insight) async {
    insight.validate();
    await _isar.writeTxn(() async {
      await _isar.isarGeneratedInsights.putByInsightId(
        IsarGeneratedInsight.fromDomain(insight),
      );
    });
  }

  @override
  Future<void> upsertInsights(List<GeneratedInsight> insights) async {
    if (insights.isEmpty) return;
    for (final insight in insights) {
      insight.validate();
    }
    await _isar.writeTxn(() async {
      final rows = insights.map(IsarGeneratedInsight.fromDomain).toList();
      await _isar.isarGeneratedInsights.putAllByInsightId(rows);
    });
  }

  @override
  Future<void> replaceScopeInsights({
    required InsightScopeType scopeType,
    required String scopeId,
    required List<GeneratedInsight> insights,
  }) async {
    final key = scopeId.trim();
    if (key.isEmpty) return;
    for (final insight in insights) {
      insight.validate();
      if (insight.scopeType != scopeType || insight.scopeId.trim() != key) {
        throw ArgumentError(
          'replaceScopeInsights received insight outside target scope',
        );
      }
    }
    await _isar.writeTxn(() async {
      final existing = await _isar.isarGeneratedInsights
          .where()
          .scopeTypeScopeIdEqualTo(scopeType.name, key)
          .findAll();
      if (existing.isNotEmpty) {
        final ids = existing.map((row) => row.id).toList(growable: false);
        await _isar.isarGeneratedInsights.deleteAll(ids);
      }
      if (insights.isNotEmpty) {
        final rows = insights.map(IsarGeneratedInsight.fromDomain).toList();
        await _isar.isarGeneratedInsights.putAllByInsightId(rows);
      }
    });
  }

  @override
  Future<List<GeneratedInsight>> listByScope({
    required InsightScopeType scopeType,
    required String scopeId,
  }) async {
    final key = scopeId.trim();
    if (key.isEmpty) return const <GeneratedInsight>[];
    final rows = await _isar.isarGeneratedInsights
        .where()
        .scopeTypeScopeIdEqualTo(scopeType.name, key)
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<List<GeneratedInsight>> listByScopeAndDateWindow({
    required InsightScopeType scopeType,
    required String scopeId,
    String? startDateKey,
    String? endDateKey,
  }) async {
    final byScope = await listByScope(scopeType: scopeType, scopeId: scopeId);
    return byScope
        .where((insight) {
          final start = startDateKey?.trim();
          final end = endDateKey?.trim();
          if (start != null &&
              start.isNotEmpty &&
              insight.sourceWindowEndDateKey.compareTo(start) < 0) {
            return false;
          }
          if (end != null &&
              end.isNotEmpty &&
              insight.sourceWindowStartDateKey.compareTo(end) > 0) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<List<GeneratedInsight>> listAll() async {
    final rows = await _isar.isarGeneratedInsights
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }
}
