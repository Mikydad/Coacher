import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_ai_summary.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/ai_summary_response.dart';

const int kAiSummaryHistoryMaxEntries = 50;

abstract class AiSummaryRepository {
  /// Persist or update a summary keyed by [AiSummaryResponse.focusId].
  Future<void> upsertSummary(AiSummaryResponse summary);

  /// Retrieve the latest summary for a given focus ID, or null if absent.
  Future<AiSummaryResponse?> getSummaryForFocus(String focusId);

  /// Retrieve the most recent summary regardless of focus ID.
  Future<AiSummaryResponse?> getLatestSummary();

  /// Returns true when a fresh (non-stale) summary exists for [focusId].
  Future<bool> hasFreshSummary({
    required String focusId,
    required int ttlMs,
    required int nowMs,
  });

  /// Delete summaries older than [beforeMs] to keep storage bounded.
  Future<void> pruneOldSummaries({required int beforeMs});
}

class IsarAiSummaryRepository implements AiSummaryRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertSummary(AiSummaryResponse summary) async {
    if (summary.focusId.trim().isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.isarAiSummarys.putByFocusId(
        IsarAiSummary.fromDomain(summary),
      );
    });
    await _trimHistory();
  }

  @override
  Future<AiSummaryResponse?> getSummaryForFocus(String focusId) async {
    final row = await _isar.isarAiSummarys
        .filter()
        .focusIdEqualTo(focusId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<AiSummaryResponse?> getLatestSummary() async {
    final row = await _isar.isarAiSummarys
        .where()
        .sortByGeneratedAtMsDesc()
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<bool> hasFreshSummary({
    required String focusId,
    required int ttlMs,
    required int nowMs,
  }) async {
    final summary = await getSummaryForFocus(focusId);
    if (summary == null) return false;
    return (nowMs - summary.generatedAtMs) < ttlMs;
  }

  @override
  Future<void> pruneOldSummaries({required int beforeMs}) async {
    await _isar.writeTxn(() async {
      await _isar.isarAiSummarys
          .filter()
          .generatedAtMsLessThan(beforeMs)
          .deleteAll();
    });
  }

  Future<void> _trimHistory() async {
    final count = await _isar.isarAiSummarys.count();
    if (count <= kAiSummaryHistoryMaxEntries) return;
    final excess = count - kAiSummaryHistoryMaxEntries;
    await _isar.writeTxn(() async {
      final oldest = await _isar.isarAiSummarys
          .where()
          .sortByGeneratedAtMs()
          .limit(excess)
          .findAll();
      final ids = oldest.map((r) => r.id).toList();
      await _isar.isarAiSummarys.deleteAll(ids);
    });
  }
}
