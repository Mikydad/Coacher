import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/intentions/application/intentions_providers.dart';
import '../features/intentions/domain/models/intention.dart';

/// Notification-action handlers for intention opportunity nudges
/// (humanizing Phase 1). All writes are local-first (Isar + outbox) —
/// airplane-mode safe; the suggestion response is the confirmation signal
/// (PRD §4.4 confirm-at-the-end).

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

/// "Later" — not now, but the promise stands. Bumps the snooze count
/// (avoidance truth) and replans: the fired slot is in the past, so the
/// planner picks the next good moment.
Future<void> snoozeIntentionFromNotification(
  String intentionId,
  ProviderContainer container,
) async {
  try {
    final repo = container.read(intentionsRepositoryProvider);
    final updated = await repo.updateStatus(
      intentionId,
      IntentionStatus.open,
      bumpSnoozeCount: true,
    );
    if (updated == null) return;
    await container
        .read(intentionNudgeSyncServiceProvider)
        .applyForIntention(updated);
  } catch (e) {
    debugPrint('[NotifTap] intention snooze failed: $e');
  }
}

/// "Wrong time" — the moment was badly chosen. The ledger dismissal (recorded
/// by the caller) feeds the planner's quiet-hours signal; replanning moves
/// the remaining slots away from the rejected moment.
Future<void> wrongTimeIntentionFromNotification(
  String intentionId,
  ProviderContainer container,
) async {
  try {
    final repo = container.read(intentionsRepositoryProvider);
    final intention = await repo.getIntention(intentionId);
    if (intention == null || !intention.isPlannable) return;
    await container
        .read(intentionNudgeSyncServiceProvider)
        .applyForIntention(intention);
  } catch (e) {
    debugPrint('[NotifTap] intention wrong-time failed: $e');
  }
}
