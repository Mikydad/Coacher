import 'package:flutter/foundation.dart';

import '../../../core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/notifications/notification_ledger_state.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../context_override/domain/models/interruption_level.dart';
import '../data/reminder_occurrence_repository.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import '../domain/models/reminder_type.dart';
import 'attention_orchestrator_service.dart';
import 'ladder_compiler.dart';
import 'notification_route_resolver.dart';
import 'recovery_gap_finder.dart';
import 'recovery_view.dart';
import 'reminder_copy_bank.dart';

/// Schedules the aggregated recovery summary (FR-R-53 / D6).
///
/// The recovery system is deliberately quiet: overdue work surfaces on the
/// Home card and at timer-end, both of which require the user to already be
/// looking. This is its ONE push — and it is one push, not one per overdue
/// item. Five missed tasks produce a single "5 tasks are still open", because
/// the alternative is precisely the 🔔🔔🔔🔔 the whole design exists to avoid.
///
/// Capped at two per day, enforced against the ledger rather than memory, so
/// a restart cannot reset the count.
class RecoveryNotificationScheduler {
  RecoveryNotificationScheduler({
    required ReminderOccurrenceRepository occurrences,
    required AttentionOrchestratorService orchestrator,
    required NotificationLedgerRepository ledger,
    required Future<List<DateTime>> Function(DateTime day) loadUpcomingStarts,
    Future<List<ShieldWindow>> Function(DateTime day)? loadShields,
    DateTime Function()? now,
  }) : _occurrences = occurrences,
       _orchestrator = orchestrator,
       _ledger = ledger,
       _loadUpcomingStarts = loadUpcomingStarts,
       _loadShields = loadShields,
       _now = now ?? DateTime.now;

  final ReminderOccurrenceRepository _occurrences;
  final AttentionOrchestratorService _orchestrator;
  final NotificationLedgerRepository _ledger;
  final Future<List<DateTime>> Function(DateTime day) _loadUpcomingStarts;
  final Future<List<ShieldWindow>> Function(DateTime day)? _loadShields;
  final DateTime Function() _now;

  /// D6. Two is a deliberate ceiling, not a tuning knob: a third summary in
  /// one day would be nagging by another name.
  static const int maxPerDay = 2;

  /// When the day is considered over for scheduling purposes.
  static const int dayEndHour = 21;

  Future<bool> scheduleIfNeeded() async {
    final now = _now();
    try {
      final open = await _occurrences.listUnresolved();
      final todayKey = DateKeys.todayKey(now);

      // Only genuinely overdue, non-routine items count. Routine misses get
      // the digest line and nothing else (§3.2), and an item the user waved
      // off today has already been answered.
      final actionable = open.where((o) {
        if (!o.isOverdue) return false;
        if (o.taxonomy == ReminderTaxonomy.routine) return false;
        if (o.isDismissedOn(todayKey)) return false;
        return true;
      }).toList();

      if (actionable.isEmpty) return false;

      final todayRows = await _todayRows(now);
      // AUDIT A6: one summary AT A TIME, not merely two a day. The recompute
      // graph runs on every open/resume/mutation, so without this guard sweep
      // #2 armed summary #2 minutes after #1 — the "cap" became the routine.
      final stillArmed = todayRows.any(
        (r) => r.state == NotificationLedgerState.scheduled.name,
      );
      if (stillArmed) return false;

      final alreadySent = todayRows.length;
      if (alreadySent >= maxPerDay) {
        debugPrint('[RecoveryNotification] day cap reached ($alreadySent)');
        return false;
      }

      final dayEnd = DateTime(now.year, now.month, now.day, dayEndHour);
      final at = RecoveryGapFinder.find(
        now: now,
        dayEnd: dayEnd,
        upcomingStarts: await _loadUpcomingStarts(now),
        shields: await (_loadShields?.call(now) ?? Future.value(const [])),
      );
      if (at == null) {
        debugPrint('[RecoveryNotification] no free gap left today');
        return false;
      }

      final copy = ReminderCopyBank.recoverySummary(actionable.length);
      await _orchestrator.evaluate(
        ReminderIntent(
          id: StableId.generate('ri_recovery'),
          // The day key as the entity: naturally unique per day, and it makes
          // the slot ids stable so re-running cannot stack duplicates.
          entityId: todayKey,
          entityKind: ReminderEntityKinds.recovery,
          entityTitle: copy.title,
          proposedAt: at,
          importance: 40,
          // Deliberately gentle. This is a summary of things already missed;
          // nothing about it is urgent, and making it loud would punish the
          // user for a bad day.
          interruptionLevel: InterruptionLevel.low,
          enforcementMode: 'flexible',
          reminderType: ReminderType.scheduled,
          sourceReason: 'recovery_summary',
          bodyOverride: copy.body,
          slot: alreadySent,
          createdAtMs: now.millisecondsSinceEpoch,
        ),
      );
      debugPrint(
        '[RecoveryNotification] scheduled summary for $at '
        '(${actionable.length} open, ${alreadySent + 1}/$maxPerDay)',
      );
      return true;
    } catch (e, st) {
      debugPrint('[RecoveryNotification] failed: $e\n$st');
      return false;
    }
  }

  /// This local day's summary rows — armed and delivered alike.
  ///
  /// Read from the ledger, not from memory: the cap has to survive a restart,
  /// or force-quitting the app would hand the user an unlimited supply.
  Future<List<IsarNotificationLedgerEntry>> _todayRows(DateTime now) async {
    final dayStart = DateTime(now.year, now.month, now.day);
    return _ledger.getDeliveryClaimsByKindInRange(
      entityKind: ReminderEntityKinds.recovery,
      startMs: dayStart.millisecondsSinceEpoch,
      endMs: dayStart.add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
  }
}

/// Exposed for the Home tap route: the payload prefix a summary carries.
const String kRecoveryPayloadPrefix = 'recovery:';

/// Convenience for tests and callers that already have the view.
int actionableCount(RecoveryView view) => view.rows.length;
