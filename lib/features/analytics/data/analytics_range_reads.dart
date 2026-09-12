import '../domain/models/analytics_stats_cache.dart';
import 'analytics_repository.dart';

/// Optional fast path for date-range reads of the daily snapshot cache.
///
/// Kept off [AnalyticsRepository] on purpose: that interface has ten
/// `implements` fakes in tests, and a range read is only ever needed by the
/// Progress period browser. [IsarAnalyticsRepository] implements it with a
/// single filtered query; every other repository goes through the
/// [readStatsCacheRange] fallback, which filters the existing list call.
abstract interface class AnalyticsStatsRangeReads {
  /// Rows of [scopeType] / scope `global` with `fromDateKey <= dateKey <=
  /// toDateKey` (`yyyy-MM-dd`), any order.
  Future<List<AnalyticsStatsCache>> listStatsCacheRange({
    required String scopeType,
    required String fromDateKey,
    required String toDateKey,
  });

  /// The smallest cached `dateKey` for [scopeType] / scope `global`, or
  /// null when nothing is cached yet. The first cached day is the user's
  /// first day of use: nothing before it can be backfilled.
  Future<String?> earliestStatsDateKey({required String scopeType});
}

/// Global daily snapshots share this scope id (see `_upsertDailySnapshot`).
const String kGlobalStatsScopeId = 'global';

Future<List<AnalyticsStatsCache>> readStatsCacheRange(
  AnalyticsRepository repo, {
  required String scopeType,
  required String fromDateKey,
  required String toDateKey,
}) async {
  if (repo is AnalyticsStatsRangeReads) {
    return (repo as AnalyticsStatsRangeReads).listStatsCacheRange(
      scopeType: scopeType,
      fromDateKey: fromDateKey,
      toDateKey: toDateKey,
    );
  }
  final rows = await repo.listStatsCache(
    scopeType: scopeType,
    scopeId: kGlobalStatsScopeId,
  );
  return rows
      .where(
        (s) =>
            s.dateKey.compareTo(fromDateKey) >= 0 &&
            s.dateKey.compareTo(toDateKey) <= 0,
      )
      .toList();
}

Future<String?> readEarliestStatsDateKey(
  AnalyticsRepository repo, {
  required String scopeType,
}) async {
  if (repo is AnalyticsStatsRangeReads) {
    return (repo as AnalyticsStatsRangeReads).earliestStatsDateKey(
      scopeType: scopeType,
    );
  }
  final rows = await repo.listStatsCache(
    scopeType: scopeType,
    scopeId: kGlobalStatsScopeId,
  );
  String? earliest;
  for (final r in rows) {
    if (r.dateKey.isEmpty) continue;
    if (earliest == null || r.dateKey.compareTo(earliest) < 0) {
      earliest = r.dateKey;
    }
  }
  return earliest;
}
