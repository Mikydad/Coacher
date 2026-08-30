import '../../planning/domain/models/routine_mode.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import 'notification_route_resolver.dart';

/// The title and body a slot will deliver, written in advance.
class ReminderCopy {
  const ReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// Every string a reminder can say (FR-R-63, deterministic half).
///
/// ## Why a bank at all
///
/// Two disconnected copy paths existed. `ReminderSyncService.bodyForReminder`
/// held the real escalation voice — "start now or submit a logical reason",
/// "Please open SidePal" — and had **no caller on the delivery path**, while
/// `_buildNotificationBody` rendered "Time to start: X" for every mode, every
/// escalation step and every taxonomy (AUDIT §10 M2). The modes could not
/// sound different because only one sentence was ever reachable.
///
/// This is also what makes FR-R-34 possible: a slot compiled at 9 a.m. for
/// 9 p.m. carries its finished string, so delivery composes nothing and the
/// network is never on the path.
///
/// ## Voice
///
/// Warm, specific, short (PRD §8). Escalation raises *directness*, not
/// volume: a fourth Extreme nudge is blunter than the first, never louder or
/// more punishing. The bank is content — reviewed as writing, not improvised
/// in a switch buried in a service.
abstract final class ReminderCopyBank {
  /// Total by construction: every combination resolves to a non-empty body.
  static ReminderCopy forSlot({
    required String entityTitle,
    String entityKind = ReminderEntityKinds.task,
    String? modeRefId,
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
    int ladderPosition = 0,
    int criticality = 1,
  }) {
    final title = _titleFor(entityTitle, entityKind);
    final name = _name(entityTitle);

    // Criticality 3 outranks everything. It is the only class allowed through
    // sleep and focus, so its copy says what it is rather than nagging.
    if (criticality >= 3) {
      return ReminderCopy(
        title: title,
        body: ladderPosition == 0
            ? 'Time for $name.'
            : "$name hasn't been marked done.",
      );
    }

    // Routine misses never escalate (§3.2), so a routine slot only ever
    // speaks once, and lightly.
    if (taxonomy == ReminderTaxonomy.routine) {
      return ReminderCopy(title: title, body: 'Time for $name.');
    }

    final expiring = taxonomy == ReminderTaxonomy.timeSensitive;
    final body = switch (_mode(modeRefId)) {
      RoutineMode.flexible => _flexible(name, ladderPosition, expiring),
      RoutineMode.disciplined => _disciplined(name, ladderPosition, expiring),
      RoutineMode.extreme => _extreme(name, ladderPosition, expiring),
    };
    return ReminderCopy(title: title, body: body);
  }

  // ── Per-mode ladders ──────────────────────────────────────────────────────

  static String _flexible(String name, int step, bool expiring) {
    if (step == 0) return 'Time for $name.';
    return expiring
        ? "$name won't keep — now's the moment."
        : 'Still up for $name?';
  }

  static String _disciplined(String name, int step, bool expiring) {
    switch (step) {
      case 0:
        return 'Time for $name.';
      case 1:
        return expiring
            ? "$name is closing — start it now."
            : '$name is waiting on you.';
      default:
        return expiring
            ? 'Last chance for $name.'
            : 'Last call for $name — do it, or move it.';
    }
  }

  static String _extreme(String name, int step, bool expiring) {
    switch (step) {
      case 0:
        return 'Time for $name.';
      case 1:
        return 'Start $name now.';
      case 2:
        return expiring
            ? '$name is about to be gone. Start it or let it go on purpose.'
            : '$name is slipping. Start it, or reschedule with a reason.';
      default:
        return expiring
            ? 'Final call for $name.'
            : "Final call for $name. Do it now, or say why you're not.";
    }
  }

  // ── Recovery surfaces ─────────────────────────────────────────────────────

  /// The aggregated recovery notification (FR-R-53), when one is scheduled.
  static ReminderCopy recoverySummary(int openCount) {
    final body = openCount == 1
        ? 'One task is still open. Want to close it out?'
        : '$openCount tasks are still open. Want to pick one off?';
    return ReminderCopy(title: 'Still on your plate', body: body);
  }

  /// Body for a batch delivery (fixes AUDIT §10 M4).
  ///
  /// The old path joined `decision.batchedWith`, which carries intent ids
  /// (`ri_…` StableIds) rather than titles — so the one artifact batching
  /// could produce was a notification showing internal ids to the user.
  /// Partner titles are not reachable at this point, so it counts instead of
  /// naming, which is honest and never leaks an id.
  static String batchedBody(String entityTitle, int partnerCount) {
    final name = _name(entityTitle);
    if (partnerCount <= 0) return 'Time for $name.';
    return partnerCount == 1
        ? 'Time for $name, plus one more.'
        : 'Time for $name, plus $partnerCount more.';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _titleFor(String entityTitle, String entityKind) {
    final trimmed = entityTitle.trim();
    if (trimmed.isEmpty) {
      return entityKind == ReminderEntityKinds.goal ? 'Your goal' : 'SidePal';
    }
    return trimmed;
  }

  /// A task called "Study" reads better inline as "Study" than as "your
  /// task"; a blank one has to fall back to something sayable.
  static String _name(String entityTitle) {
    final trimmed = entityTitle.trim();
    return trimmed.isEmpty ? 'your task' : trimmed;
  }

  static RoutineMode _mode(String? modeRefId) =>
      switch ((modeRefId ?? '').trim().toLowerCase()) {
        'disciplined' => RoutineMode.disciplined,
        'extreme' => RoutineMode.extreme,
        _ => RoutineMode.flexible,
      };
}
