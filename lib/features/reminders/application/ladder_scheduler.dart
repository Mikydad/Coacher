import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_budget.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../context_override/domain/models/user_attention_state.dart';
import '../data/reminder_occurrence_repository.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import '../domain/models/reminder_type.dart';
import '../domain/models/slot_spec.dart';
import 'attention_orchestrator_service.dart';
import 'notification_route_resolver.dart';
import 'interruption_level_resolver.dart';
import 'ladder_compiler.dart';

/// Supplies the plan the ladder must respect. Injected as a callback so the
/// scheduler does not depend on the time-blocks feature directly, and so
/// tests can hand it a fixed day.
typedef UpcomingStartsLoader = Future<List<DateTime>> Function(DateTime day);

/// Arms compiled ladders (FR-R-30…34) — the [L-PRE] layer.
///
/// Every notification this schedules was decided by [LadderCompiler] from
/// Isar-resident data, with its strings already written. Nothing here waits on
/// the network, and delivery-time code composes nothing: that is the PRD's one
/// architecture rule, and this is the class most able to break it.
class LadderScheduler {
  LadderScheduler({
    required ReminderOccurrenceRepository occurrences,
    required AttentionOrchestratorService orchestrator,
    required UpcomingStartsLoader loadUpcomingStarts,
    Future<UserAttentionState?> Function()? loadAttentionState,
    NotificationBudget? budget,

    /// Slot-drop record (FR-R-33 / B3). Optional so tests and legacy wiring
    /// keep working; absent, drops are debugPrint-only.
    NotificationLedgerRepository? ledger,
    DateTime Function()? now,
  }) : _occurrences = occurrences,
       _orchestrator = orchestrator,
       _loadUpcomingStarts = loadUpcomingStarts,
       _loadAttentionState = loadAttentionState,
       _budget = budget,
       _ledger = ledger,
       _now = now ?? DateTime.now;

  final ReminderOccurrenceRepository _occurrences;
  final AttentionOrchestratorService _orchestrator;
  final UpcomingStartsLoader _loadUpcomingStarts;
  final Future<UserAttentionState?> Function()? _loadAttentionState;
  final NotificationBudget? _budget;
  final NotificationLedgerRepository? _ledger;
  final DateTime Function() _now;

  /// Deepest ladder any mode defines — how many slots a cancel must sweep.
  static const int maxLadderSlots = 4;

  /// Re-arm every eligible occurrence's ladder.
  ///
  /// Idempotent: slot ids are deterministic, so re-running replaces each slot
  /// in place rather than stacking duplicates.
  Future<LadderSchedulingResult> rearmAll({
    /// Ephemeral shields for THIS pass — the dynamic half of FR-R-32
    /// (audit B2): a timer the user just started shields its whole session,
    /// and the recompile at session end (via the recompute graph's
    /// notifications scope) lifts it again.
    List<ShieldWindow> extraShields = const [],
  }) async {
    final now = _now();
    try {
      final open = await _occurrences.listUnresolved();
      if (open.isEmpty) return const LadderSchedulingResult();

      final upcomingStarts = await _loadUpcomingStarts(now);
      final shields = [...await _shieldsFor(now), ...extraShields];
      var remaining =
          await (_budget?.remainingCapacity() ??
              Future.value(NotificationBudget.kDefaultSafeCap));

      var armed = 0;
      var dropped = 0;
      var unknownModes = 0;

      // Criticality first, then soonest: when the queue runs short, the most
      // important and most imminent ladders are the ones that keep their
      // depth (FR-R-33's ordering).
      final ordered = [...open]..sort((a, b) {
        final byCriticality = b.criticality.compareTo(a.criticality);
        if (byCriticality != 0) return byCriticality;
        return a.scheduledAtMs.compareTo(b.scheduledAtMs);
      });

      const knownModes = {'flexible', 'disciplined', 'extreme'};

      for (final occurrence in ordered) {
        // AUDIT A3: tasks and habits ONLY. Goal occurrences exist for
        // state-machine visibility, but their arming belongs to
        // GoalReminderSyncService — whose slot 1 is TOMORROW'S occurrence
        // under the same `goal:<id>:1` OS id a ladder follow-up would claim.
        // Compiling a ladder here overwrote tomorrow's armed day with a T+10
        // nudge, quietly undoing the C4 fix. Intentions likewise own their
        // own three-slot ladder.
        if (occurrence.entityKind != ReminderEntityKinds.task &&
            occurrence.entityKind != ReminderEntityKinds.habit) {
          continue;
        }

        // M3: every resolver hard-codes the three built-ins and defaults
        // everything else to flexible — so a legacy or typo'd mode id
        // quietly gets the WEAKEST contract, which is the opposite of what a
        // stricter-sounding custom name implies. Degrading is still the right
        // behaviour; doing it silently is not.
        final modeId = (occurrence.modeRefId ?? 'flexible').trim().toLowerCase();
        if (!knownModes.contains(modeId)) {
          debugPrint(
            '[LadderScheduler] unknown mode "$modeId" on '
            '${occurrence.entityId} → degrading to flexible',
          );
          unknownModes++;
        }

        final plan = LadderCompiler.compile(
          occurrence: occurrence,
          context: LadderContext(
            upcomingStarts: upcomingStarts,
            shields: shields,
            budgetRemaining: remaining,
          ),
          now: now,
        );

        for (final drop in plan.drops) {
          dropped++;
          debugPrint(
            '[LadderScheduler] ${occurrence.entityId} dropped $drop',
          );
          // Drops must be EFFECTIVE and RECORDED (B2/B3). Effective: a
          // boundary or shield that appeared after a slot was armed silences
          // the armed leftover now, not at the next cold start. Recorded:
          // FR-R-33's "no silent truncation" — but only for reasons that
          // represent real loss; `past` and `notToday` are the calendar
          // doing its job.
          const effectiveReasons = {
            SlotDropReason.boundary,
            SlotDropReason.shield,
            SlotDropReason.budget,
            SlotDropReason.snoozed,
            SlotDropReason.window,
          };
          if (!effectiveReasons.contains(drop.reason)) continue;
          await _orchestrator.cancelTaskSlot(occurrence.entityId, drop.slot);
          await _ledger?.logDrop(
            notifId:
                ('task:${occurrence.entityId}:${drop.slot}').hashCode.abs() %
                2147483647,
            entityId: occurrence.entityId,
            entityKind: occurrence.entityKind,
            scheduledForMs: occurrence.scheduledAt
                .add(Duration(minutes: drop.offsetMinutes))
                .millisecondsSinceEpoch,
            reason: drop.reason.name,
          );
        }

        for (final slot in plan.slots) {
          await _arm(occurrence, slot, now);
          armed++;
          remaining = remaining > 0 ? remaining - 1 : 0;
        }
      }

      if (armed > 0 || dropped > 0) {
        debugPrint('[LadderScheduler] armed $armed, dropped $dropped');
      }
      return LadderSchedulingResult(
        armed: armed,
        dropped: dropped,
        unknownModes: unknownModes,
      );
    } catch (e, st) {
      debugPrint('[LadderScheduler] rearm failed: $e\n$st');
      return const LadderSchedulingResult();
    }
  }

  Future<void> _arm(
    ReminderOccurrence occurrence,
    SlotSpec slot,
    DateTime now,
  ) async {
    final modeRefId = occurrence.modeRefId ?? 'flexible';
    final intent = ReminderIntent(
      id: StableId.generate('ri_ladder'),
      entityId: occurrence.entityId,
      entityKind: occurrence.entityKind,
      entityTitle: slot.title,
      proposedAt: slot.fireAt,
      importance: (occurrence.criticality * 25).clamp(0, 100),
      interruptionLevel: InterruptionLevelResolver.resolve(
        enforcementMode: modeRefId,
        escalationLevel: slot.slot,
        emergencyBypass: occurrence.criticality >= 3,
      ),
      enforcementMode: modeRefId,
      escalationLevel: slot.slot,
      // Slot 0 IS the reminder; the rest are its follow-ups. The distinction
      // matters: the CoachingStyle back-off may suppress a follow-up, and
      // must never suppress the first delivery.
      reminderType: slot.isFirst
          ? ReminderType.scheduled
          : ReminderType.followUp,
      sourceReason: 'ladder_slot_${slot.slot}',
      // Pre-written (FR-R-34) — _buildNotificationBody honours bodyOverride,
      // so the delivery path composes nothing for a ladder slot.
      bodyOverride: slot.body,
      slot: slot.slot,
      createdAtMs: now.millisecondsSinceEpoch,
    );
    await _orchestrator.evaluate(intent);
  }

  /// Known shield windows: the configured sleep window for today and
  /// tomorrow. Dynamic shields (a timer the user starts) are handled by the
  /// [L-ALIVE] recompile, not here.
  Future<List<ShieldWindow>> _shieldsFor(DateTime now) async {
    final state = await (_loadAttentionState?.call() ?? Future.value(null));
    if (state == null || !state.hasSleepWindow) return const [];
    final start = _todayAt(now, state.sleepWindowStart);
    final end = _todayAt(now, state.sleepWindowEnd);
    if (start == null || end == null) return const [];

    // A window that crosses midnight is two spans, not one.
    if (end.isAfter(start)) {
      return [ShieldWindow(start: start, end: end, reason: 'sleep')];
    }
    return [
      ShieldWindow(
        start: start,
        end: end.add(const Duration(days: 1)),
        reason: 'sleep',
      ),
      ShieldWindow(
        start: start.subtract(const Duration(days: 1)),
        end: end,
        reason: 'sleep',
      ),
    ];
  }

  static DateTime? _todayAt(DateTime now, String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(now.year, now.month, now.day, h, m);
  }

  /// The local day key the scheduler treats as "today".
  static String todayKey(DateTime now) => DateKeys.todayKey(now);
}

class LadderSchedulingResult {
  const LadderSchedulingResult({
    this.armed = 0,
    this.dropped = 0,
    this.unknownModes = 0,
  });

  final int armed;
  final int dropped;

  /// Occurrences whose mode id was not one of the three built-ins and were
  /// degraded to flexible (M3). Surfaced rather than swallowed.
  final int unknownModes;

  bool get didWork => armed > 0 || dropped > 0;

  @override
  String toString() =>
      'LadderSchedulingResult(armed: $armed, dropped: $dropped'
      '${unknownModes > 0 ? ', unknownModes: $unknownModes' : ''})';
}
