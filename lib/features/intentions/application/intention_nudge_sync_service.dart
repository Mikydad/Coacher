import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_budget.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/scheduling/free_window_calculator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/data/feature_cache_repository.dart';
import '../../context_override/domain/models/interruption_level.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../reminders/application/attention_orchestrator_service.dart';
import '../../reminders/application/notification_route_resolver.dart';
import '../../reminders/domain/models/reminder_intent.dart';
import '../data/intentions_repository.dart';
import '../data/opportunity_plan_repository.dart';
import '../domain/models/intention.dart';
import '../domain/models/opportunity_slot.dart';
import 'opportunity_planner.dart';

/// Same `{title, startTime, endTime}` conversion the payload assembler
/// uses — only tasks with a scheduled time occupy the day. Shared by the
/// nudge planner and the seize-the-moment card.
List<Map<String, dynamic>> scheduleMapsFromPlannedRows(
  List<PlannedTaskRow> rows,
) {
  final scheduled = rows.where((r) {
    final iso = r.task.reminderTimeIso;
    return iso != null && iso.isNotEmpty;
  });
  return scheduled.map((row) {
    final t = row.task;
    final dt = DateTime.tryParse(t.reminderTimeIso!)?.toLocal();
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    final endDt = dt != null && t.durationMinutes >= 1
        ? dt.add(Duration(minutes: t.durationMinutes))
        : null;
    return <String, dynamic>{
      'title': t.title,
      'startTime': dt != null ? fmt(dt) : '?',
      'endTime': endDt != null ? fmt(endDt) : '?',
    };
  }).toList(growable: false);
}

/// Drives the [OpportunityPlanner] for every plannable intention and turns
/// its slot ladder into `ReminderIntent(entityKind: 'intention')` proposals
/// through the [AttentionOrchestratorService].
///
/// All reads are local (Isar) — planning and scheduling are airplane-safe.
/// Replans compare an inputs hash against the cached plan so unchanged
/// intentions don't churn the OS notification queue on every recompute.
class IntentionNudgeSyncService {
  IntentionNudgeSyncService({
    required IntentionsRepository intentions,
    required OpportunityPlanRepository plans,
    required PlanningRepository planningRepository,
    required FeatureCacheRepository featureCache,
    required NotificationLedgerRepository ledger,
    required AttentionOrchestratorService orchestrator,
    NotificationBudget? budget,
    DateTime Function()? now,
  }) : _intentions = intentions,
       _plans = plans,
       _planning = planningRepository,
       _featureCache = featureCache,
       _ledger = ledger,
       _orchestrator = orchestrator,
       _budget = budget,
       _now = now ?? DateTime.now;

  final IntentionsRepository _intentions;
  final OpportunityPlanRepository _plans;
  final PlanningRepository _planning;
  final FeatureCacheRepository _featureCache;
  final NotificationLedgerRepository _ledger;
  final AttentionOrchestratorService _orchestrator;
  final NotificationBudget? _budget;
  final DateTime Function() _now;

  /// Throttle for [rearmIfStale] (same rhythm as goal reminders).
  static const Duration kRearmMinInterval = Duration(minutes: 5);
  int _lastRearmMs = 0;

  /// How many days ahead the planner scans for free windows.
  static const int kMaxScanDays = 7;

  /// A ledger hour is "quiet" when the user ignored at least this many
  /// nudges there and ignores outnumber positive interactions 2:1.
  static const int kQuietHourMinIgnores = 3;

  /// Replan every plannable intention. Terminal/dormant intentions get
  /// their pending slots cancelled and plan cache dropped.
  Future<void> applyAll() async {
    final all = await _intentions.fetchIntentionsOnce();
    final quietHours = await _quietHoursFromLedger();
    final bestBlock = await _dominantBestTimeBlock();
    for (final intention in all) {
      await _applyForIntention(
        intention,
        quietHours: quietHours,
        bestTimeBlock: bestBlock,
      );
    }
  }

  /// Replan a single intention right away (capture, edit, Done, snooze).
  Future<void> applyForIntention(Intention intention) async {
    await _applyForIntention(
      intention,
      quietHours: await _quietHoursFromLedger(),
      bestTimeBlock: await _dominantBestTimeBlock(),
    );
  }

  /// Roll-forward hook for the recompute graph's notification step and app
  /// resume. Throttled — replans only need to catch fired slots and day
  /// changes, not every 400 ms debounce flush.
  Future<void> rearmIfStale() async {
    final nowMs = _now().millisecondsSinceEpoch;
    if (nowMs - _lastRearmMs < kRearmMinInterval.inMilliseconds) return;
    _lastRearmMs = nowMs;
    await applyAll();
  }

  /// Cancels the ladder + drops the cached plan (Done / dismissed / undo).
  Future<void> cancelForIntention(String intentionId) async {
    await _orchestrator.cancelIntentionSlots(intentionId);
    await _plans.deleteByIntentionId(intentionId);
  }

  @visibleForTesting
  void debugResetRearmThrottle() => _lastRearmMs = 0;

  // ── Internals ──────────────────────────────────────────────────────────

  Future<void> _applyForIntention(
    Intention intention, {
    required Set<int> quietHours,
    required String? bestTimeBlock,
  }) async {
    final now = _now();

    // Expired window → honest terminal state, no zombie notifications.
    // The expired record stays queryable ("what have I been avoiding?").
    if (intention.isPlannable &&
        intention.windowEndMs < now.millisecondsSinceEpoch) {
      await _intentions.updateStatus(intention.id, IntentionStatus.expired);
      await cancelForIntention(intention.id);
      return;
    }

    if (!intention.isPlannable) {
      await cancelForIntention(intention.id);
      return;
    }

    final freeWindows = await _freeWindowsForWindow(intention, now);
    final slots = OpportunityPlanner.plan(
      intention: intention,
      now: now,
      freeWindowsByDateKey: freeWindows,
      bestTimeBlock: bestTimeBlock,
      quietHours: quietHours,
    );

    if (slots.isEmpty) {
      await cancelForIntention(intention.id);
      return;
    }

    // Slot ladder budget (PRD §4.3): two slots by default, the third only
    // when the 64-cap headroom allows all three.
    var ladder = slots;
    if (slots.length > 2) {
      final roomForAll =
          await (_budget?.canSchedule(needed: slots.length) ??
              Future.value(true));
      if (!roomForAll) ladder = slots.take(2).toList(growable: false);
    }

    final hash = _inputsHash(intention, ladder);
    final cached = await _plans.getByIntentionId(intention.id);
    if (cached != null && cached.inputsHash == hash) return; // unchanged

    await _orchestrator.cancelIntentionSlots(intention.id);
    for (final slot in ladder) {
      final intent = ReminderIntent(
        id: StableId.generate('ri_intention'),
        entityId: intention.id,
        entityKind: ReminderEntityKinds.intention,
        entityTitle: intention.title,
        proposedAt: DateTime.fromMillisecondsSinceEpoch(slot.deliverAtMs),
        importance: switch (intention.importance) {
          IntentionImportance.high => 70,
          IntentionImportance.normal => 50,
          IntentionImportance.low => 35,
        },
        interruptionLevel: InterruptionLevel.medium,
        enforcementMode: 'flexible',
        sourceReason: 'opportunity_nudge:${slot.reasonKind.name}',
        bodyOverride: slot.body,
        slot: slot.slot,
        createdAtMs: now.millisecondsSinceEpoch,
      );
      try {
        await _orchestrator.evaluate(intent);
      } catch (e, st) {
        debugPrint('Intention nudge schedule failed: $e $st');
      }
    }

    await _plans.upsertPlan(
      OpportunityPlan(
        intentionId: intention.id,
        slots: ladder,
        inputsHash: hash,
        computedAtMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  /// Free windows per day across the intention's deadline window
  /// (capped at [kMaxScanDays] from now). Busy blocks come from the planned
  /// schedule — the same source the Coach prompt uses.
  Future<Map<String, List<FreeWindow>>> _freeWindowsForWindow(
    Intention intention,
    DateTime now,
  ) async {
    final windowStart = DateTime.fromMillisecondsSinceEpoch(
      intention.windowStartMs,
    );
    final windowEnd = DateTime.fromMillisecondsSinceEpoch(
      intention.windowEndMs,
    );
    final firstDay = windowStart.isAfter(now) ? windowStart : now;
    final result = <String, List<FreeWindow>>{};
    for (var offset = 0; offset < kMaxScanDays; offset++) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day)
          .add(Duration(days: offset));
      if (day.isAfter(windowEnd)) break;
      final dateKey = DateKeys.yyyymmdd(day);
      List<Map<String, dynamic>> busyMaps;
      try {
        final rows = await collectTasksForDateKey(_planning, dateKey);
        busyMaps = scheduleMapsFromPlannedRows(rows);
      } catch (_) {
        busyMaps = const [];
      }
      final isToday = DateKeys.yyyymmdd(now) == dateKey;
      result[dateKey] = FreeWindowCalculator.computeWindows(
        busyMaps,
        fromMinuteOfDay: isToday ? now.hour * 60 + now.minute : 0,
      );
    }
    return result;
  }

  /// Hours where the ledger shows the user ignores nudges (w5 input).
  Future<Set<int>> _quietHoursFromLedger() async {
    try {
      final entries = await _ledger.getAllEntries();
      final ignoresByHour = <int, int>{};
      final positivesByHour = <int, int>{};
      for (final e in entries) {
        final deliveredMs = e.deliveredAtMs ?? e.scheduledForMs;
        if (deliveredMs == null) continue;
        final hour =
            DateTime.fromMillisecondsSinceEpoch(deliveredMs).hour;
        final interaction = e.interactionType;
        if (interaction == 'opened' || interaction == 'snoozed') {
          positivesByHour[hour] = (positivesByHour[hour] ?? 0) + 1;
        }
        if (e.ignoredCount > 0) {
          ignoresByHour[hour] = (ignoresByHour[hour] ?? 0) + 1;
        }
      }
      final quiet = <int>{};
      ignoresByHour.forEach((hour, ignores) {
        final positives = positivesByHour[hour] ?? 0;
        if (ignores >= kQuietHourMinIgnores && ignores > positives * 2) {
          quiet.add(hour);
        }
      });
      return quiet;
    } catch (_) {
      return const {};
    }
  }

  /// The user's dominant Layer-1 best time block across all cached
  /// behavior features — new intentions have no history of their own.
  Future<String?> _dominantBestTimeBlock() async {
    try {
      final features = await _featureCache.listAll();
      if (features.isEmpty) return null;
      final counts = <String, int>{};
      for (final f in features) {
        final block = f.contextFeatures.bestTimeBlock;
        counts[block] = (counts[block] ?? 0) + 1;
      }
      String? best;
      var bestCount = 0;
      counts.forEach((block, count) {
        if (count > bestCount) {
          best = block;
          bestCount = count;
        }
      });
      return best;
    } catch (_) {
      return null;
    }
  }

  static String _inputsHash(Intention intention, List<OpportunitySlot> slots) {
    final slotSig = slots
        .map((s) => '${s.slot}:${s.deliverAtMs}:${s.body.hashCode}')
        .join('|');
    return '${intention.updatedAtMs}|$slotSig';
  }
}
