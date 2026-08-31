import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_keys.dart';
import 'recovery_view.dart';

/// What one triage call produced: a warm one-liner and a ranking.
class RecoveryTriage {
  const RecoveryTriage({required this.headline, required this.order});

  /// "Start with Study — the rest can move." Max one sentence.
  final String headline;

  /// Entity ids, most-worth-doing-first. Ids the AI failed to mention keep
  /// their deterministic position after these.
  final List<String> order;
}

/// The recovery-moment triage call (FR-R-62) — an ENHANCEMENT, never a gate.
///
/// The Recovery Card renders its deterministic order immediately, always.
/// When ≥3 items are unresolved and the budget allows, ONE bounded call may
/// rank them and add a headline; if it never answers, nothing happens and
/// nothing waited. Capped at two calls per local day, persisted so a restart
/// cannot re-open the budget.
class RecoveryTriageService {
  RecoveryTriageService({
    required Future<String> Function(List<Map<String, dynamic>> messages) chat,
    required bool Function() isAiTierEnabled,
    DateTime Function()? now,
  }) : _chat = chat,
       _isAiTierEnabled = isAiTierEnabled,
       _now = now ?? DateTime.now;

  final Future<String> Function(List<Map<String, dynamic>> messages) _chat;
  final bool Function() _isAiTierEnabled;
  final DateTime Function() _now;

  static const int minItems = 3;
  static const int maxPerDay = 2;
  static const _kCountPrefsKey = 'recovery_triage_count_v1';

  /// In-session memo: one answer per card composition. Keyed by the sorted
  /// id set, so the same overdue pool never pays twice.
  final Map<String, RecoveryTriage?> _memo = {};

  Future<RecoveryTriage?> triage(RecoveryView view) async {
    try {
      if (!_isAiTierEnabled()) return null;
      final rows = view.rows;
      if (rows.length < minItems) return null;

      final key = (rows.map((r) => r.occurrence.entityId).toList()..sort())
          .join(',');
      if (_memo.containsKey(key)) return _memo[key];

      if (!await _tryClaimDailySlot()) return null;

      final content = await _chat(buildMessages(rows));
      final result = parseResponse(
        content,
        validIds: {for (final r in rows) r.occurrence.entityId},
      );
      _memo[key] = result;
      return result;
    } catch (e) {
      // FR-R-71: offline or failed → the deterministic order stands, silently.
      debugPrint('[RecoveryTriage] skipped: $e');
      return null;
    }
  }

  /// Claims one of today's two slots; persisted so force-quit cannot reset it.
  Future<bool> _tryClaimDailySlot() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateKeys.todayKey(_now());
    final raw = prefs.getString(_kCountPrefsKey);
    var count = 0;
    if (raw != null) {
      final parts = raw.split('|');
      if (parts.length == 2 && parts[0] == today) {
        count = int.tryParse(parts[1]) ?? 0;
      }
    }
    if (count >= maxPerDay) return false;
    await prefs.setString(_kCountPrefsKey, '$today|${count + 1}');
    return true;
  }

  // ── Pure halves ───────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> buildMessages(List<RecoveryRow> rows) => [
    {
      'role': 'system',
      'content':
          'A user has several overdue personal tasks. Rank them by what is '
          'most worth doing RIGHT NOW (urgency, mode strictness, how long '
          'each has waited), and write one warm, non-judgmental sentence '
          'suggesting where to start. Reply ONLY with JSON: '
          '{"headline":"...","order":["id1","id2"]}. Headline max 90 chars, '
          'every id copied verbatim from the input.',
    },
    {
      'role': 'user',
      'content': jsonEncode([
        for (final r in rows)
          {
            'id': r.occurrence.entityId,
            'title': r.title,
            'mode': r.occurrence.modeRefId ?? 'flexible',
            'criticality': r.occurrence.criticality,
            'overdueSinceMs': r.occurrence.overdueSinceMs,
          },
      ]),
    },
  ];

  static RecoveryTriage? parseResponse(
    String content, {
    required Set<String> validIds,
  }) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      final headline = decoded['headline'];
      final rawOrder = decoded['order'];
      if (headline is! String || rawOrder is! List) return null;
      final trimmed = headline.trim();
      if (trimmed.isEmpty || trimmed.length > 120) return null;
      final seen = <String>{};
      final order = [
        for (final id in rawOrder)
          if (id is String && validIds.contains(id) && seen.add(id)) id,
      ];
      if (order.isEmpty) return null;
      return RecoveryTriage(headline: trimmed, order: order);
    } catch (_) {
      return null;
    }
  }

  /// The AI's ranking applied without ever losing a row: ranked ids first,
  /// then everything it failed to mention in their deterministic order.
  static List<RecoveryRow> applyOrder(
    List<RecoveryRow> rows,
    RecoveryTriage triage,
  ) {
    final byId = {for (final r in rows) r.occurrence.entityId: r};
    final ranked = <RecoveryRow>[
      for (final id in triage.order)
        if (byId.remove(id) case final r?) r,
    ];
    return [...ranked, ...rows.where((r) => byId.containsValue(r))];
  }
}
