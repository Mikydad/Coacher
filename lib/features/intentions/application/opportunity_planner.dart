import 'dart:convert';

import '../../../core/scheduling/free_window_calculator.dart';
import '../domain/models/intention.dart';
import '../domain/models/opportunity_slot.dart';

/// Pure, deterministic slot scoring for intentions (PRD §4.3).
///
/// No I/O, no clock reads, no LLM calls — every input arrives as an
/// argument, so planning is reproducible, auditable, and identical in
/// airplane mode. AI opinions participate only as persisted hints
/// ([Intention.aiHintsJson]) with advisory weight: a hint can tilt a
/// decision between real candidates, never fabricate a slot the
/// deterministic signals don't support.
class OpportunityPlanner {
  const OpportunityPlanner._();

  // Scoring weights (w1..w7 in the PRD formula). Compile-time for Phase 1;
  // promote to Remote Config only if tuning demands it.
  static const double wFreeWindowFit = 3;
  static const double wDurationFit = 2;
  static const double wActivityCompatibility = 1;
  static const double wBestTimeBlockAffinity = 2;
  static const double wLedgerResponsiveness = 2;
  static const double wDeadlinePressure = 1;
  static const double wAiHintAffinity = 1;

  /// Minimum lead time before a candidate may fire.
  static const Duration minLeadTime = Duration(minutes: 5);

  /// Minimum spacing between ladder slots.
  static const Duration minSlotSpacing = Duration(hours: 2);

  /// Plans the slot ladder for [intention].
  ///
  /// [freeWindowsByDateKey] maps `DateKeys.yyyymmdd` day keys (already
  /// restricted to the intention's deadline window) to that day's free
  /// windows. [bestTimeBlock] is the user's dominant Layer-1 block
  /// ('morning' | 'afternoon' | 'evening'), [quietHours] are hours the
  /// notification ledger says the user ignores.
  ///
  /// Returns up to three slots: 0 = primary (best score), 1 = deadline-eve
  /// safety, 2 = fallback (caller includes it only when the notification
  /// budget allows). Pinned intentions get exactly one slot at their pinned
  /// time — never second-guessed.
  static List<OpportunitySlot> plan({
    required Intention intention,
    required DateTime now,
    required Map<String, List<FreeWindow>> freeWindowsByDateKey,
    String? bestTimeBlock,
    Set<int> quietHours = const {},
  }) {
    final windowEnd = DateTime.fromMillisecondsSinceEpoch(
      intention.windowEndMs,
    );

    // Pinned time opts out of smart timing entirely (settled: Q4).
    final pinnedAtMs = intention.pinnedAtMs;
    if (pinnedAtMs != null) {
      final pinnedAt = DateTime.fromMillisecondsSinceEpoch(pinnedAtMs);
      if (!pinnedAt.isAfter(now.add(minLeadTime))) return const [];
      return [
        OpportunitySlot(
          slot: 0,
          deliverAtMs: pinnedAtMs,
          reasonKind: OpportunityReasonKind.pinned,
          reasonText: 'The time you picked',
          body: _pinnedBody(intention.title),
        ),
      ];
    }

    final earliest = now.add(minLeadTime);
    final candidates = _scoredCandidates(
      intention: intention,
      earliest: earliest,
      windowEnd: windowEnd,
      freeWindowsByDateKey: freeWindowsByDateKey,
      bestTimeBlock: bestTimeBlock,
      quietHours: quietHours,
    );
    if (candidates.isEmpty) {
      // No free window at all inside the deadline window: fall back to a
      // single safety slot so the promise is never silently dropped.
      final safety = _deadlineEveTime(earliest, windowEnd);
      if (safety == null) return const [];
      return [
        OpportunitySlot(
          slot: 0,
          deliverAtMs: safety.millisecondsSinceEpoch,
          reasonKind: OpportunityReasonKind.deadlinePressure,
          reasonText: 'Your window is closing',
          body: _deadlineBody(intention.title),
        ),
      ];
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final primary = candidates.first;
    final slots = <OpportunitySlot>[
      OpportunitySlot(
        slot: 0,
        deliverAtMs: primary.deliverAt.millisecondsSinceEpoch,
        reasonKind: primary.reasonKind,
        reasonText: primary.reasonText,
        body: _primaryBody(intention.title, primary),
      ),
    ];

    // Deadline-eve safety: a late slot so a missed primary still gets one
    // polite save before the window closes.
    final safety = _deadlineEveTime(earliest, windowEnd);
    if (safety != null &&
        safety.difference(primary.deliverAt) >= minSlotSpacing) {
      slots.add(
        OpportunitySlot(
          slot: 1,
          deliverAtMs: safety.millisecondsSinceEpoch,
          reasonKind: OpportunityReasonKind.deadlinePressure,
          reasonText: 'Your window is closing',
          body: _deadlineBody(intention.title),
        ),
      );
    }

    // Optional fallback: next-best candidate spaced away from both.
    for (final c in candidates.skip(1)) {
      final farFromAll = slots.every(
        (s) =>
            (c.deliverAt.millisecondsSinceEpoch - s.deliverAtMs).abs() >=
            minSlotSpacing.inMilliseconds,
      );
      if (farFromAll) {
        slots.add(
          OpportunitySlot(
            slot: 2,
            deliverAtMs: c.deliverAt.millisecondsSinceEpoch,
            reasonKind: c.reasonKind,
            reasonText: c.reasonText,
            body: _primaryBody(intention.title, c),
          ),
        );
        break;
      }
    }
    return slots;
  }

  // ── Candidate generation & scoring ─────────────────────────────────────

  static List<_ScoredCandidate> _scoredCandidates({
    required Intention intention,
    required DateTime earliest,
    required DateTime windowEnd,
    required Map<String, List<FreeWindow>> freeWindowsByDateKey,
    required String? bestTimeBlock,
    required Set<int> quietHours,
  }) {
    final aiPreferredBlock = _aiPreferredBlock(intention.aiHintsJson);
    final totalSpanMs =
        windowEnd.millisecondsSinceEpoch - earliest.millisecondsSinceEpoch;
    final candidates = <_ScoredCandidate>[];

    freeWindowsByDateKey.forEach((dateKey, windows) {
      final day = _parseDateKey(dateKey);
      if (day == null) return;
      for (final w in windows) {
        final deliverAt = DateTime(
          day.year,
          day.month,
          day.day,
          w.startMinute ~/ 60,
          w.startMinute % 60,
        );
        if (deliverAt.isBefore(earliest)) continue;
        if (deliverAt.isAfter(windowEnd)) continue;

        final freeWindowFit = (w.durationMinutes / 60).clamp(0.0, 1.0);
        final durationFit = intention.estimatedMinutes <= 0
            ? 1.0
            : (w.durationMinutes / intention.estimatedMinutes).clamp(0.0, 1.0);
        final activity = _activityCompatibility(intention.activityTags, w);
        final block = _timeBlockOf(deliverAt.hour);
        final blockAffinity =
            bestTimeBlock != null && block == bestTimeBlock ? 1.0 : 0.0;
        final responsive = quietHours.contains(deliverAt.hour) ? 0.0 : 1.0;
        // Earlier candidates score higher: a promise shouldn't drift toward
        // its deadline when a good moment exists sooner.
        final position = totalSpanMs <= 0
            ? 0.0
            : ((deliverAt.millisecondsSinceEpoch -
                        earliest.millisecondsSinceEpoch) /
                    totalSpanMs)
                .clamp(0.0, 1.0);
        final earliness = 1.0 - position;
        final hintAffinity =
            aiPreferredBlock != null && block == aiPreferredBlock ? 1.0 : 0.0;

        final score = wFreeWindowFit * freeWindowFit +
            wDurationFit * durationFit +
            wActivityCompatibility * activity +
            wBestTimeBlockAffinity * blockAffinity +
            wLedgerResponsiveness * responsive +
            wDeadlinePressure * earliness +
            wAiHintAffinity * hintAffinity;

        candidates.add(
          _ScoredCandidate(
            deliverAt: deliverAt,
            score: score,
            window: w,
            reasonKind: blockAffinity == 1.0 && w.beforeTitle == null
                ? OpportunityReasonKind.bestTimeBlock
                : OpportunityReasonKind.freeWindow,
            reasonText: _reasonTextFor(w),
          ),
        );
      }
    });
    return candidates;
  }

  static double _activityCompatibility(List<String> tags, FreeWindow w) {
    if (tags.isEmpty) return 0.5; // neutral
    final isWaitingGap = w.beforeTitle != null; // gap before a block
    final isWindDown = w.beforeTitle == null; // runs to end of day
    final quickKinds = {'call', 'message', 'errand', 'quick'};
    final calmKinds = {'call', 'read', 'plan', 'windDown'};
    if (isWaitingGap && tags.any(quickKinds.contains)) return 1.0;
    if (isWindDown && tags.any(calmKinds.contains)) return 1.0;
    return 0.5;
  }

  static String _timeBlockOf(int hour) {
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 17) return 'afternoon';
    return 'evening';
  }

  /// Advisory AI hint: `{"preferredTimeBlock": "evening"}`. Unknown shapes
  /// are ignored — a malformed hint must never break planning.
  static String? _aiPreferredBlock(String? aiHintsJson) {
    if (aiHintsJson == null || aiHintsJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(aiHintsJson);
      if (decoded is! Map<String, dynamic>) return null;
      final block = decoded['preferredTimeBlock'];
      if (block is String &&
          const {'morning', 'afternoon', 'evening'}.contains(block)) {
        return block;
      }
    } catch (_) {}
    return null;
  }

  /// The deadline-eve safety time: ~2h before the window closes, clamped
  /// into polite hours (08:00–21:00). Null when even that is in the past.
  static DateTime? _deadlineEveTime(DateTime earliest, DateTime windowEnd) {
    var t = windowEnd.subtract(const Duration(hours: 2));
    if (t.hour >= 21) t = DateTime(t.year, t.month, t.day, 20, 30);
    if (t.hour < 8) {
      t = DateTime(t.year, t.month, t.day - 1, 20, 30);
    }
    if (t.isBefore(earliest)) return null;
    if (t.isAfter(windowEnd)) return null;
    return t;
  }

  static DateTime? _parseDateKey(String dateKey) {
    // DateKeys.yyyymmdd format: yyyy-MM-dd.
    final parts = dateKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  // ── Copy (deterministic question-form templates, PRD §4.4) ─────────────
  //
  // Every nudge is a suggestion phrased as a question, never a command.
  // Rendered at planning time so delivery is 100% network- and token-free.

  static String _reasonTextFor(FreeWindow w) {
    final span = FreeWindowCalculator.formatSpan(w.durationMinutes);
    final before = w.beforeTitle;
    return before == null ? '$span free' : '$span free before $before';
  }

  static String _primaryBody(String title, _ScoredCandidate c) {
    final action = _asAction(title);
    final before = c.window.beforeTitle;
    final minutes = c.window.durationMinutes;
    if (before != null) {
      return "You've got about $minutes free minutes before $before — "
          "I think now's a good time to $action. What do you think?";
    }
    return "You've got about $minutes free minutes — I think now could be "
        'a good moment to $action. What do you think?';
  }

  static String _deadlineBody(String title) {
    final action = _asAction(title);
    return "Your window to $action is closing — is now a good moment?";
  }

  static String _pinnedBody(String title) {
    final action = _asAction(title);
    return 'You picked this time to $action — ready?';
  }

  /// "Call cousin Sara" → "call cousin Sara" for mid-sentence use.
  /// Titles that look like acronyms/proper one-word names are left alone.
  static String _asAction(String title) {
    if (title.length < 2) return title;
    final first = title[0];
    final second = title[1];
    if (first.toUpperCase() == first && second.toLowerCase() == second) {
      return first.toLowerCase() + title.substring(1);
    }
    return title;
  }
}

class _ScoredCandidate {
  const _ScoredCandidate({
    required this.deliverAt,
    required this.score,
    required this.window,
    required this.reasonKind,
    required this.reasonText,
  });

  final DateTime deliverAt;
  final double score;
  final FreeWindow window;
  final OpportunityReasonKind reasonKind;
  final String reasonText;
}
