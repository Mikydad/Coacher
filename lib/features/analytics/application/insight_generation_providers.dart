import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_generated_insight.dart';
import '../../../core/utils/date_keys.dart';
import '../data/insight_cache_repository.dart';
import '../domain/models/generated_insight.dart';
import 'insight_generation_policy.dart';

/// True when [insight]'s source window overlaps [dateKey] (YYYY-MM-DD).
bool layer3InsightActiveOnDateKey(GeneratedInsight insight, String dateKey) {
  final day = dateKey.trim();
  if (day.isEmpty) return false;
  final start = insight.sourceWindowStartDateKey.trim();
  final end = insight.sourceWindowEndDateKey.trim();
  if (start.isEmpty || end.isEmpty) return true;
  return start.compareTo(day) <= 0 && end.compareTo(day) >= 0;
}

Future<List<GeneratedInsight>> loadLayer3DeliveryInsightsForDay(
  InsightCacheRepository repo,
  String dateKey,
) async {
  final trimmed = dateKey.trim();
  if (trimmed.isEmpty) return const <GeneratedInsight>[];
  final global = await repo.listByScope(
    scopeType: InsightScopeType.global,
    scopeId: trimmed,
  );
  final all = await repo.listAll();
  final entity = <GeneratedInsight>[];
  for (final insight in all) {
    if (insight.scopeType != InsightScopeType.entity) continue;
    if (!layer3InsightActiveOnDateKey(insight, trimmed)) continue;
    entity.add(insight);
  }
  final merged = <GeneratedInsight>[...global, ...entity];
  merged.sort(compareInsightOrdering);
  return merged;
}

class Layer3RunMetadata {
  const Layer3RunMetadata({
    required this.scopeType,
    required this.scopeId,
    required this.lastRunAtMs,
    required this.schemaVersion,
    required this.insightsEmitted,
  });

  final InsightScopeType scopeType;
  final String scopeId;
  final int lastRunAtMs;
  final int schemaVersion;
  final int insightsEmitted;
}

class HomeLayer3InsightViewModel {
  const HomeLayer3InsightViewModel({
    required this.primary,
    required this.topInsights,
  });

  final GeneratedInsight? primary;
  final List<GeneratedInsight> topInsights;
}

Stream<T> _watchLayer3Insights<T>(
  Ref ref, {
  required Future<T> Function() loader,
}) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.fromFuture(loader());
  }

  final controller = StreamController<T>.broadcast();

  Future<void> emit() async {
    try {
      final value = await loader();
      if (!controller.isClosed) controller.add(value);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());
  final sub = isar.isarGeneratedInsights
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
}

final layer3EntityInsightsProvider =
    StreamProvider.family<List<GeneratedInsight>, String>((ref, entityId) {
      final key = entityId.trim();
      if (key.isEmpty) return Stream.value(const <GeneratedInsight>[]);
      return _watchLayer3Insights(
        ref,
        loader: () {
          return ref
              .read(insightCacheRepositoryProvider)
              .listByScope(scopeType: InsightScopeType.entity, scopeId: key);
        },
      );
    });

final layer3GlobalDayInsightsProvider =
    StreamProvider.family<List<GeneratedInsight>, String>((ref, dateKey) {
      final key = dateKey.trim();
      if (key.isEmpty) return Stream.value(const <GeneratedInsight>[]);
      return _watchLayer3Insights(
        ref,
        loader: () {
          return ref
              .read(insightCacheRepositoryProvider)
              .listByScope(scopeType: InsightScopeType.global, scopeId: key);
        },
      );
    });

final layer3RunMetadataProvider =
    StreamProvider.family<
      Layer3RunMetadata,
      ({InsightScopeType scopeType, String scopeId})
    >((ref, query) {
      final scopeId = query.scopeId.trim();
      if (scopeId.isEmpty) {
        return Stream.value(
          Layer3RunMetadata(
            scopeType: query.scopeType,
            scopeId: scopeId,
            lastRunAtMs: 0,
            schemaVersion: kGeneratedInsightSchemaVersion,
            insightsEmitted: 0,
          ),
        );
      }
      return _watchLayer3Insights(
        ref,
        loader: () async {
          final insights = await ref
              .read(insightCacheRepositoryProvider)
              .listByScope(scopeType: query.scopeType, scopeId: scopeId);
          var lastRunAtMs = 0;
          var schemaVersion = kGeneratedInsightSchemaVersion;
          for (final insight in insights) {
            if (insight.detectedAtMs > lastRunAtMs) {
              lastRunAtMs = insight.detectedAtMs;
            }
            if (insight.schemaVersion > schemaVersion) {
              schemaVersion = insight.schemaVersion;
            }
          }
          return Layer3RunMetadata(
            scopeType: query.scopeType,
            scopeId: scopeId,
            lastRunAtMs: lastRunAtMs,
            schemaVersion: schemaVersion,
            insightsEmitted: insights.length,
          );
        },
      );
    });

/// Layer 3 mapping rules are entity-scoped; global rows are often empty. Home,
/// Progress, and Layer 4 need merged global-day + entity insights whose source
/// window still covers [dateKey].
final layer3DeliveryDayInsightsProvider =
    StreamProvider.family<List<GeneratedInsight>, String>((ref, dateKey) {
      final key = dateKey.trim();
      if (key.isEmpty) return Stream.value(const <GeneratedInsight>[]);
      return _watchLayer3Insights(
        ref,
        loader: () => loadLayer3DeliveryInsightsForDay(
          ref.read(insightCacheRepositoryProvider),
          key,
        ),
      );
    });

final layer3TodayGlobalInsightsProvider =
    Provider<AsyncValue<List<GeneratedInsight>>>((ref) {
      final today = DateKeys.todayKey();
      return ref.watch(layer3GlobalDayInsightsProvider(today));
    });

final layer3TodayDeliveryInsightsProvider =
    Provider<AsyncValue<List<GeneratedInsight>>>((ref) {
      final today = DateKeys.todayKey();
      return ref.watch(layer3DeliveryDayInsightsProvider(today));
    });

final layer3TodayRunMetadataProvider = Provider<AsyncValue<Layer3RunMetadata>>((
  ref,
) {
  final today = DateKeys.todayKey();
  final insightsAsync = ref.watch(layer3DeliveryDayInsightsProvider(today));
  return insightsAsync.when(
    data: (insights) {
      var lastRunAtMs = 0;
      var schemaVersion = kGeneratedInsightSchemaVersion;
      for (final insight in insights) {
        if (insight.detectedAtMs > lastRunAtMs) {
          lastRunAtMs = insight.detectedAtMs;
        }
        if (insight.schemaVersion > schemaVersion) {
          schemaVersion = insight.schemaVersion;
        }
      }
      return AsyncValue.data(
        Layer3RunMetadata(
          scopeType: InsightScopeType.global,
          scopeId: today,
          lastRunAtMs: lastRunAtMs,
          schemaVersion: schemaVersion,
          insightsEmitted: insights.length,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (Object e, StackTrace st) =>
        AsyncValue<Layer3RunMetadata>.error(e, st),
  );
});

final homeLayer3InsightsProvider =
    Provider<AsyncValue<HomeLayer3InsightViewModel>>((ref) {
      final todayInsightsAsync = ref.watch(layer3TodayDeliveryInsightsProvider);
      return todayInsightsAsync.whenData((insights) {
        final sorted = List<GeneratedInsight>.from(insights)
          ..sort(compareInsightOrdering);
        final top = sorted.take(3).toList(growable: false);
        return HomeLayer3InsightViewModel(
          primary: top.isEmpty ? null : top.first,
          topInsights: top,
        );
      });
    });
