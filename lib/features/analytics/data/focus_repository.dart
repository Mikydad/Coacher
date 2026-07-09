import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_coaching_focus.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/current_coaching_focus.dart';

const int kFocusHistoryMaxEntries = 150;

abstract class FocusRepository {
  Future<void> upsertFocus(CurrentCoachingFocus focus);

  Future<CurrentCoachingFocus?> getActiveFocus();

  Future<List<CurrentCoachingFocus>> getRecentFocusHistory({
    int limit = kFocusHistoryMaxEntries,
  });

  /// Transition an existing focus to a new lifecycle state.
  /// Preserves all other fields.
  Future<void> transitionFocus({
    required String focusId,
    required FocusLifecycleState newState,
    int? resolvedAtMs,
    FocusReplacementReason? replacementReason,
  });

  /// Archive (set to [FocusLifecycleState.archived]) all live focus records
  /// whose [activeUntilMs] has passed and are not already terminal.
  Future<void> archiveStaleFocus({required int nowMs});
}

class IsarFocusRepository implements FocusRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertFocus(CurrentCoachingFocus focus) async {
    if (focus.focusId.trim().isEmpty) return;
    focus.validate();
    await _isar.writeTxn(() async {
      await _isar.isarCoachingFocus.putByFocusId(
        IsarCoachingFocus.fromDomain(focus),
      );
    });
    // Trim history to cap.
    await _trimHistory();
  }

  @override
  Future<CurrentCoachingFocus?> getActiveFocus() async {
    final liveStates = [
      FocusLifecycleState.active.name,
      FocusLifecycleState.reinforced.name,
      FocusLifecycleState.candidate.name,
    ];
    final rows = await _isar.isarCoachingFocus
        .filter()
        .anyOf(liveStates, (q, state) => q.lifecycleStateEqualTo(state))
        .sortByDetectedAtMsDesc()
        .findAll();
    if (rows.isEmpty) return null;
    return rows.first.toDomain();
  }

  @override
  Future<List<CurrentCoachingFocus>> getRecentFocusHistory({
    int limit = kFocusHistoryMaxEntries,
  }) async {
    final rows = await _isar.isarCoachingFocus
        .where()
        .sortByDetectedAtMsDesc()
        .limit(limit)
        .findAll();
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  @override
  Future<void> transitionFocus({
    required String focusId,
    required FocusLifecycleState newState,
    int? resolvedAtMs,
    FocusReplacementReason? replacementReason,
  }) async {
    final trimmed = focusId.trim();
    if (trimmed.isEmpty) return;
    await _isar.writeTxn(() async {
      final existing = await _isar.isarCoachingFocus
          .filter()
          .focusIdEqualTo(trimmed)
          .findFirst();
      if (existing == null) return;
      final updated = existing.toDomain();
      final transitioned = CurrentCoachingFocus(
        focusId: updated.focusId,
        primaryInsightId: updated.primaryInsightId,
        secondaryInsightId: updated.secondaryInsightId,
        lifecycleState: newState,
        focusReason: updated.focusReason,
        focusScore: updated.focusScore,
        focusConfidence: updated.focusConfidence,
        scoreBreakdown: updated.scoreBreakdown,
        contextSnapshot: updated.contextSnapshot,
        evaluationTrace: updated.evaluationTrace,
        suppressedCandidates: updated.suppressedCandidates,
        sourceInsightTypes: updated.sourceInsightTypes,
        detectedAtMs: updated.detectedAtMs,
        activeUntilMs: updated.activeUntilMs,
        resolvedAtMs: resolvedAtMs ?? updated.resolvedAtMs,
        replacementReason: replacementReason ?? updated.replacementReason,
        metadata: updated.metadata,
        schemaVersion: updated.schemaVersion,
      );
      await _isar.isarCoachingFocus.putByFocusId(
        IsarCoachingFocus.fromDomain(transitioned),
      );
    });
  }

  @override
  Future<void> archiveStaleFocus({required int nowMs}) async {
    final liveStates = [
      FocusLifecycleState.active.name,
      FocusLifecycleState.reinforced.name,
      FocusLifecycleState.candidate.name,
    ];
    final candidates = await _isar.isarCoachingFocus
        .filter()
        .anyOf(liveStates, (q, state) => q.lifecycleStateEqualTo(state))
        .activeUntilMsLessThan(nowMs)
        .findAll();

    if (candidates.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final row in candidates) {
        final focus = row.toDomain();
        final archived = CurrentCoachingFocus(
          focusId: focus.focusId,
          primaryInsightId: focus.primaryInsightId,
          secondaryInsightId: focus.secondaryInsightId,
          lifecycleState: FocusLifecycleState.stale,
          focusReason: focus.focusReason,
          focusScore: focus.focusScore,
          focusConfidence: focus.focusConfidence,
          scoreBreakdown: focus.scoreBreakdown,
          contextSnapshot: focus.contextSnapshot,
          evaluationTrace: focus.evaluationTrace,
          suppressedCandidates: focus.suppressedCandidates,
          sourceInsightTypes: focus.sourceInsightTypes,
          detectedAtMs: focus.detectedAtMs,
          activeUntilMs: focus.activeUntilMs,
          resolvedAtMs: nowMs,
          replacementReason: FocusReplacementReason.minDurationExpired,
          metadata: focus.metadata,
          schemaVersion: focus.schemaVersion,
        );
        await _isar.isarCoachingFocus.putByFocusId(
          IsarCoachingFocus.fromDomain(archived),
        );
      }
    });
  }

  Future<void> _trimHistory() async {
    final count = await _isar.isarCoachingFocus.count();
    if (count <= kFocusHistoryMaxEntries) return;
    final toDelete = count - kFocusHistoryMaxEntries;
    final oldest = await _isar.isarCoachingFocus
        .where()
        .sortByDetectedAtMs()
        .limit(toDelete)
        .findAll();
    if (oldest.isEmpty) return;
    final ids = oldest.map((r) => r.id).toList();
    await _isar.writeTxn(() async {
      await _isar.isarCoachingFocus.deleteAll(ids);
    });
  }
}
