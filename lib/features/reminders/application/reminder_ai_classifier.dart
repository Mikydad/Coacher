import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import 'reminder_classifier.dart';
import 'reminder_occurrence_service.dart';

/// The AI classifier's build number, stored on rows it upgrades so a later
/// prompt revision can re-target exactly what an older one decided.
const int kAiClassifierVersion = 1;

/// One task's classification inputs, as sent to the proxy.
typedef ClassifyInput = ({
  String id,
  String title,
  int? durationMinutes,
  String? category,
  bool isHabitAnchor,
});

/// The background classification upgrade (FR-R-22) — advisory by design.
///
/// The heuristic classifier already answered at save time, synchronously and
/// offline; this refines that answer in the background when the network and
/// the budget allow. Every rule about who wins is enforced in CODE, not in
/// the prompt (FR-R-65):
///
/// - a `user` classification is never touched (`withClassification` refuses);
/// - criticality is clamped to **2** — the AI is not allowed to grant the one
///   level that pierces sleep, same as the heuristic (settled 2026-08-30);
/// - `enabled` and the scheduled time are structurally out of reach
///   (FR-R-23: classification selects ladder shape, never existence);
/// - any invalid, partial or failed response is discarded silently and the
///   heuristic stands (FR-R-71). There is no user-visible error state.
///
/// Follows the `reflect` pattern: system-class purpose through the existing
/// `aiChat` proxy, client-held prompt, bounded by the server's silent-skip
/// daily budget. One attempt per config version per session — "retry only on
/// material edit" (an edit rebuilds the config, changing `updatedAtMs`).
class ReminderAiClassifier {
  ReminderAiClassifier({
    required ReminderRepository reminders,
    required ReminderOccurrenceService occurrences,

    /// The proxy call, injected as a function so tests never touch Firebase:
    /// (messages) → assistant content string.
    required Future<String> Function(List<Map<String, dynamic>> messages) chat,

    /// FR-R-60 tier gate: AI classification is Pro. Injected so this service
    /// stays free of Riverpod.
    required bool Function() isAiTierEnabled,

    /// Re-arms ladders after an upgrade changed taxonomy/criticality — the
    /// ladder shape and boundary piercing may both have changed.
    Future<void> Function()? rearmLadders,
  }) : _reminders = reminders,
       _occurrences = occurrences,
       _chat = chat,
       _isAiTierEnabled = isAiTierEnabled,
       _rearmLadders = rearmLadders;

  final ReminderRepository _reminders;
  final ReminderOccurrenceService _occurrences;
  final Future<String> Function(List<Map<String, dynamic>> messages) _chat;
  final bool Function() _isAiTierEnabled;
  final Future<void> Function()? _rearmLadders;

  /// `configId:updatedAtMs` pairs already attempted this session. Session-
  /// scoped on purpose: a failed or slow response must not retry on every
  /// save (FR-R-22), while an app restart or a material edit — which changes
  /// `updatedAtMs` — makes the row eligible again.
  final Set<String> _attempted = {};

  /// Upgrade every eligible config in ONE batched call (FR-R-22's
  /// "N tasks, 1 call"). Fire-and-forget from the save path and from
  /// Plan-Tomorrow; never awaited by anything user-facing.
  Future<int> sweep() async {
    try {
      if (!_isAiTierEnabled()) return 0;

      final all = await _reminders.listAllReminders();
      final eligible = all.where((r) {
        if (!r.enabled) return false;
        // Only rows the machine decided. `user` is authoritative and `ai`
        // is already upgraded; both are skipped here AND refused at write
        // time — defense in depth.
        if (r.classificationSource != ClassificationSource.heuristic &&
            r.classificationSource != ClassificationSource.migration) {
          return false;
        }
        final title = r.taskTitle?.trim();
        if (title == null || title.isEmpty) return false;
        return !_attempted.contains('${r.id}:${r.updatedAtMs}');
      }).toList(growable: false);

      if (eligible.isEmpty) return 0;
      for (final r in eligible) {
        _attempted.add('${r.id}:${r.updatedAtMs}');
      }

      final content = await _chat(
        buildMessages([
          for (final r in eligible)
            (
              id: r.id,
              title: r.taskTitle!.trim(),
              durationMinutes: null,
              category: null,
              isHabitAnchor: false,
            ),
        ]),
      );

      final results = parseResponse(
        content,
        validIds: {for (final r in eligible) r.id},
      );
      if (results.isEmpty) return 0;

      var applied = 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final r in eligible) {
        final result = results[r.id];
        if (result == null) continue;
        if (result.taxonomy == r.taxonomy &&
            result.criticality == r.criticality &&
            result.body == null) {
          continue; // The heuristic already had it right — no write, no churn.
        }
        var upgraded = r.withClassification(
          taxonomy: result.taxonomy,
          criticality: result.criticality,
          source: ClassificationSource.ai,
          classifierVersion: kAiClassifierVersion,
          updatedAtMs: nowMs,
        );
        if (result.body != null) {
          upgraded = upgraded.copyWith(aiBody: result.body, updatedAtMs: nowMs);
        }
        // withClassification returns `this` unchanged for user rows —
        // identical means refused, and we must not upsert a no-op.
        if (identical(upgraded, r)) continue;
        await _reminders.upsertReminder(upgraded);
        // The occurrence snapshots classification at arming time; a changed
        // class must reach today's row too, or the card and the ladder would
        // disagree with the config until tomorrow.
        await _occurrences.ensureForConfig(upgraded);
        applied++;
      }

      if (applied > 0) {
        await _rearmLadders?.call();
        debugPrint('[AiClassifier] upgraded $applied of ${eligible.length}');
      }
      return applied;
    } catch (e) {
      // FR-R-71: AI endpoint down → the heuristic stands, silently.
      debugPrint('[AiClassifier] sweep failed (heuristic stands): $e');
      return 0;
    }
  }

  // ── Pure halves, exposed for tests ────────────────────────────────────────

  /// The proxy payload. The system message pins the same semantics the
  /// heuristic implements, so the AI is a refinement of one rulebook rather
  /// than a second rulebook.
  static List<Map<String, dynamic>> buildMessages(List<ClassifyInput> items) {
    final lines = [
      for (final item in items)
        jsonEncode({
          'id': item.id,
          'title': item.title,
          if (item.durationMinutes != null) 'minutes': item.durationMinutes,
          if (item.category != null) 'category': item.category,
          if (item.isHabitAnchor) 'habit': true,
        }),
    ];
    return [
      {
        'role': 'system',
        'content':
            'You classify personal task reminders. For each input task, decide '
            'what missing it means:\n'
            '- "timesensitive": pointless or much less useful later (meetings, '
            'calls, appointments, medication, transport, deadlines).\n'
            '- "flexible": still worth doing later the same day or after.\n'
            '- "routine": a recurring low-stakes habit where one miss is '
            'trivial (hydration, tidying, stretching).\n'
            'criticality: 0 trivial, 1 normal, 2 important (medication, '
            'legal/medical appointments). Never exceed 2.\n'
            'Optionally add "body": one warm, specific reminder line for the '
            'task, max 70 chars, no exclamation marks, no guilt.\n'
            'Reply with ONLY a JSON object: {"items":[{"id":"...",'
            '"class":"timesensitive|flexible|routine","criticality":0,'
            '"body":"..."}]}. '
            'Include every input id exactly once. No other keys, no prose.',
      },
      {'role': 'user', 'content': lines.join('\n')},
    ];
  }

  /// Strict parse + validation. Anything malformed is dropped PER ITEM, so
  /// one bad row cannot poison the batch; a wholly malformed body yields
  /// nothing rather than throwing.
  static Map<String,
      ({ReminderTaxonomy taxonomy, int criticality, String? body})>
  parseResponse(String content, {required Set<String> validIds}) {
    final out =
        <String, ({ReminderTaxonomy taxonomy, int criticality, String? body})>{};
    try {
      final decoded = jsonDecode(content);
      final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
      if (items is! List) return out;
      for (final raw in items) {
        if (raw is! Map) continue;
        final id = raw['id'];
        if (id is! String || !validIds.contains(id)) continue;
        final rawClass = raw['class'];
        if (rawClass is! String) continue;
        final taxonomy = switch (rawClass.trim().toLowerCase()) {
          'timesensitive' => ReminderTaxonomy.timeSensitive,
          'flexible' => ReminderTaxonomy.flexible,
          'routine' => ReminderTaxonomy.routine,
          _ => null,
        };
        if (taxonomy == null) continue;
        final rawCrit = raw['criticality'];
        // FR-R-65: the AI never grants criticality 3 — clamped, not trusted.
        final criticality = rawCrit is num ? rawCrit.toInt().clamp(0, 2) : 1;
        // FR-R-63's variant: sanitized here, not trusted. Length-capped,
        // newline-stripped; empty or oversized means "no variant".
        final rawBody = raw['body'];
        String? body;
        if (rawBody is String) {
          final cleaned = rawBody.replaceAll('\n', ' ').trim();
          if (cleaned.isNotEmpty && cleaned.length <= 90) body = cleaned;
        }
        out[id] = (taxonomy: taxonomy, criticality: criticality, body: body);
      }
    } catch (_) {
      // Malformed JSON → empty map → heuristic stands.
    }
    return out;
  }
}

/// Keeps `ReminderClassifier` (the floor) and this upgrade path reviewable as
/// one rulebook: if the heuristic's version bumps, prompts should be re-read.
const int kHeuristicClassifierVersion = ReminderClassifier.version;
