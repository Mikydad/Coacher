import 'dart:convert';

import 'package:isar_community/isar.dart';

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
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {
    final trimmed = assistantSummary?.trim();
    // 1200, not 500: suggest-plan messages carry the concrete times the next
    // turn needs ("as you suggested"); truncating them caused re-ask loops.
    final capped = trimmed != null && trimmed.isNotEmpty
        ? (trimmed.length > 1200 ? '${trimmed.substring(0, 1197)}…' : trimmed)
        : null;

    final entry = IsarAiInteractionHistory()
      ..sessionId = sessionId
      ..userInput = userInput
      ..parsedActionsJson = jsonEncode(
        parsedActions.map((a) => a.toJson()).toList(),
      )
      ..confirmed = false
      ..executed = false
      ..resolvedCategory = resolvedCategory
      ..assistantSummary = capped
      ..responseType = responseType
      ..timestampMs = DateTime.now().millisecondsSinceEpoch;

    await _isar.writeTxn(() async {
      await _isar.isarAiInteractionHistorys.put(entry);
    });
  }

  /// Stores the assistant's execution summary for the most recent entry
  /// in [sessionId]. Used to build full conversationHistory for multi-turn context.
  Future<void> saveAssistantSummary(String sessionId, String summary) async {
    final entries = await _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampMsDesc()
        .limit(1)
        .findAll();
    if (entries.isEmpty) return;
    await _isar.writeTxn(() async {
      entries.first.assistantSummary = summary;
      await _isar.isarAiInteractionHistorys.put(entries.first);
    });
  }

  /// Updates the [resolvedCategory] for all entries in [sessionId].
  /// Called by [AiAssistantService] after successful plan execution.
  Future<void> updateResolvedCategory(String sessionId, String category) async {
    final entries = await _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    if (entries.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final e in entries) {
        e.resolvedCategory = category;
        await _isar.isarAiInteractionHistorys.put(e);
      }
    });
  }

  /// Marks the NEWEST entry of [sessionId] confirmed — the entry whose
  /// plan the user just confirmed. Marking the whole session (the old
  /// behavior) flagged declined suggestions and informational turns too,
  /// which then fed the model "Already applied this session (do NOT
  /// repeat)" for things that never happened (§8 M1 / GPT-5.6 G8).
  Future<void> markConfirmed(String sessionId) =>
      _markLatest(sessionId, (e) => e.confirmed = true);

  /// Marks the NEWEST entry of [sessionId] executed — see [markConfirmed].
  Future<void> markExecuted(String sessionId) =>
      _markLatest(sessionId, (e) => e.executed = true);

  Future<void> _markLatest(
    String sessionId,
    void Function(IsarAiInteractionHistory) mutate,
  ) async {
    final latest = await _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampMsDesc()
        .findFirst();
    if (latest == null) return;
    await _isar.writeTxn(() async {
      mutate(latest);
      await _isar.isarAiInteractionHistorys.put(latest);
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

  /// Returns the most recent unconfirmed interaction that is within
  /// [withinMinutes] of now. Returns null if none found.
  ///
  /// Used by the "Pick up where you left off" banner in [AiAssistantScreen].
  Future<IsarAiInteractionHistory?> getMostRecentUnconfirmed({
    int withinMinutes = 30,
  }) async {
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: withinMinutes))
        .millisecondsSinceEpoch;
    return _isar.isarAiInteractionHistorys
        .filter()
        .confirmedEqualTo(false)
        .timestampMsGreaterThan(cutoff)
        .sortByTimestampMsDesc()
        .findFirst();
  }

  /// Full transcript order for one session (oldest first) — what the
  /// memory extraction pipeline reads.
  Future<List<IsarAiInteractionHistory>> getAllForSession(
    String sessionId,
  ) async {
    return _isar.isarAiInteractionHistorys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampMs()
        .findAll();
  }

  /// All entries older than [cutoffMs] — summarize-then-purge groups these
  /// by session to decide what still needs extraction. Bounded: rows never
  /// outlive the 7-day deferral ceiling.
  Future<List<IsarAiInteractionHistory>> getOlderThan(int cutoffMs) async {
    return _isar.isarAiInteractionHistorys
        .filter()
        .timestampMsLessThan(cutoffMs)
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

  /// Deletes ALL raw turns of the given sessions — called by
  /// summarize-then-purge only after a session is extracted or truncated,
  /// never blindly by age.
  Future<void> purgeSessions(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final sessionId in sessionIds) {
        await _isar.isarAiInteractionHistorys
            .filter()
            .sessionIdEqualTo(sessionId)
            .deleteAll();
      }
    });
  }
}
