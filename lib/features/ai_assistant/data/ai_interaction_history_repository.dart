import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../core/local_db/isar_collections/isar_ai_interaction_history.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/ai_action.dart';

/// Persists [IsarAiInteractionHistory] records for Coach AI interactions.
///
/// Responsibilities:
/// - Save a new interaction on every `sendMessage` call.
/// - Return the most recent N interactions for a session (used to build
///   the `sessionHistory` field of the AI prompt payload).
/// - Purge entries older than a given cutoff (called on app open for 48h TTL).
/// - Mark entries as confirmed / executed after user approval.
class AiInteractionHistoryRepository {
  const AiInteractionHistoryRepository(this._store);

  final OfflineStore _store;

  Isar get _isar => _store.isar!;

  // ─── Write ────────────────────────────────────────────────────────────────

  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
  }) async {
    final entry = IsarAiInteractionHistory()
      ..sessionId = sessionId
      ..userInput = userInput
      ..parsedActionsJson = jsonEncode(parsedActions.map((a) => a.toJson()).toList())
      ..confirmed = false
      ..executed = false
      ..timestampMs = DateTime.now().millisecondsSinceEpoch;

    await _isar.writeTxn(() async {
      await _isar.isarAiInteractionHistorys.put(entry);
    });
  }

  Future<void> markConfirmed(String sessionId) async {
    final entries = await _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    if (entries.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final e in entries) {
        e.confirmed = true;
        await _isar.isarAiInteractionHistorys.put(e);
      }
    });
  }

  Future<void> markExecuted(String sessionId) async {
    final entries = await _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    if (entries.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final e in entries) {
        e.executed = true;
        await _isar.isarAiInteractionHistorys.put(e);
      }
    });
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns the most recent [limit] interactions, newest first.
  Future<List<IsarAiInteractionHistory>> getRecent({int limit = 10}) async {
    return _isar.isarAiInteractionHistorys
        .where()
        .sortByTimestampMsDesc()
        .limit(limit)
        .findAll();
  }

  /// Returns the most recent [limit] interactions for a specific session.
  Future<List<IsarAiInteractionHistory>> getRecentForSession(
    String sessionId, {
    int limit = 10,
  }) async {
    return _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampMsDesc()
        .limit(limit)
        .findAll();
  }

  // ─── TTL purge ────────────────────────────────────────────────────────────

  /// Deletes all entries with [timestampMs] < [cutoff] milliseconds since epoch.
  Future<void> purgeBefore(DateTime cutoff) async {
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    await _isar.writeTxn(() async {
      await _isar.isarAiInteractionHistorys
          .filter()
          .timestampMsLessThan(cutoffMs)
          .deleteAll();
    });
  }
}
