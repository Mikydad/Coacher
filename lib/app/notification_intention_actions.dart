import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/intentions/application/intentions_providers.dart';
import '../features/intentions/domain/models/intention.dart';
import '../features/memory/application/memory_providers.dart';

/// Notification-action handlers for intention opportunity nudges
/// (humanizing Phase 1). All writes are local-first (Isar + outbox) —
/// airplane-mode safe; the suggestion response is the confirmation signal
/// (PRD §4.4 confirm-at-the-end).
///
/// Learning loop (P1-05): every response proves the nudge REACHED the
/// user, so it bumps `nudgeCount` and moves an `open` intention to
/// `nudged` (live surfaces treat the two identically — see
/// [Intention.isLive]). "Wrong time" additionally counts strikes in
/// `aiHintsJson`; two strikes retire the AI's `preferredTimeBlock` and
/// contradict the memory facts it was based on, so the system stops
/// betting on a moment the user rejected twice.

/// Strikes needed before a reflected time hint is retired.
const int kWrongTimeStrikesToRetireHint = 2;

/// Pure strike accounting for "Wrong time" (P1-05): increments
/// `wrongTimeStrikes`; at [kWrongTimeStrikesToRetireHint] the reflected
/// `preferredTimeBlock` is removed and the hint's `basedOn` ids are
/// returned for contradiction. Does not mutate [current].
({Map<String, dynamic> hints, List<String> contradictedFactIds})
applyWrongTimeStrike(Map<String, dynamic> current) {
  final hints = Map<String, dynamic>.from(current);
  final strikes = ((hints['wrongTimeStrikes'] as num?)?.toInt() ?? 0) + 1;
  hints['wrongTimeStrikes'] = strikes;
  var contradicted = const <String>[];
  if (strikes >= kWrongTimeStrikesToRetireHint &&
      hints.containsKey('preferredTimeBlock')) {
    hints.remove('preferredTimeBlock');
    contradicted = (hints['basedOn'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
  }
  return (hints: hints, contradictedFactIds: contradicted);
}

/// "Done" — the user kept the promise. Terminal state; the ladder's
/// remaining slots are cancelled so siblings never fire after completion.
Future<bool> completeIntentionFromNotification(
  String intentionId,
  ProviderContainer container,
) async {
  try {
    final repo = container.read(intentionsRepositoryProvider);
    final updated = await repo.updateStatus(
      intentionId,
      IntentionStatus.done,
      completedAtMs: DateTime.now().millisecondsSinceEpoch,
      bumpNudgeCount: true, // the nudge reached the user AND worked
    );
    if (updated == null) return false;
    await container
        .read(intentionNudgeSyncServiceProvider)
        .cancelForIntention(intentionId);
    return true;
  } catch (e) {
    debugPrint('[NotifTap] intention done failed: $e');
    return false;
  }
}

/// "Later" — not now, but the promise stands. Bumps both counts (the
/// nudge reached the user; the moment was deferred) and replans: the
/// fired slot is in the past, so the planner picks the next good moment.
Future<void> snoozeIntentionFromNotification(
  String intentionId,
  ProviderContainer container,
) async {
  try {
    final repo = container.read(intentionsRepositoryProvider);
    final updated = await repo.updateStatus(
      intentionId,
      IntentionStatus.nudged,
      bumpSnoozeCount: true,
      bumpNudgeCount: true,
    );
    if (updated == null) return;
    await container
        .read(intentionNudgeSyncServiceProvider)
        .applyForIntention(updated);
  } catch (e) {
    debugPrint('[NotifTap] intention snooze failed: $e');
  }
}

/// "Wrong time" — the moment was badly chosen. The ledger dismissal
/// (recorded by the caller) feeds the planner's quiet-hours signal;
/// replanning moves the remaining slots away from the rejected moment.
///
/// Strike accounting (P1-05): the strike count lives in `aiHintsJson`.
/// At [kWrongTimeStrikesToRetireHint] strikes the reflected
/// `preferredTimeBlock` is removed (the planner stops favoring it) and
/// any `basedOn` memory facts get a contradiction — the same §5.2 decay
/// path a spoken correction would take.
Future<void> wrongTimeIntentionFromNotification(
  String intentionId,
  ProviderContainer container,
) async {
  try {
    final repo = container.read(intentionsRepositoryProvider);
    final intention = await repo.getIntention(intentionId);
    if (intention == null || !intention.isPlannable) return;

    final struck = applyWrongTimeStrike(_decodeHints(intention.aiHintsJson));
    final facts = container.read(memoryFactsRepositoryProvider);
    for (final factId in struck.contradictedFactIds) {
      try {
        // No-op for ids that aren't memory facts (people/intentions).
        await facts.registerContradiction(factId);
      } catch (e) {
        debugPrint('[NotifTap] hint contradiction failed for $factId: $e');
      }
    }

    final updated = intention.copyWith(
      status: IntentionStatus.nudged,
      nudgeCount: intention.nudgeCount + 1,
      aiHintsJson: jsonEncode(struck.hints),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await repo.upsertIntention(updated);
    await container
        .read(intentionNudgeSyncServiceProvider)
        .applyForIntention(updated);
  } catch (e) {
    debugPrint('[NotifTap] intention wrong-time failed: $e');
  }
}

Map<String, dynamic> _decodeHints(String? raw) {
  if (raw == null || raw.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}
