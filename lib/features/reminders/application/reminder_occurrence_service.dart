import 'package:flutter/foundation.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../data/reminder_occurrence_repository.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import 'adaptive_reminder_policy.dart';
import 'notification_route_resolver.dart';
import 'reminder_state_machine.dart';

/// What one [L-ALIVE] sweep did — returned so callers can log it and tests
/// can assert on it without reaching into the repository.
class ReminderSweepResult {
  const ReminderSweepResult({
    this.advanced = 0,
    this.created = 0,
    this.nowOverdue = 0,
  });

  /// Occurrences whose state moved.
  final int advanced;

  /// Occurrences created by the backfill.
  final int created;

  /// Of [advanced], how many became overdue — the number the Recovery Card
  /// is about to show.
  final int nowOverdue;

  bool get didWork => advanced > 0 || created > 0;

  @override
  String toString() =>
      'ReminderSweepResult(advanced: $advanced, created: $created, '
      'nowOverdue: $nowOverdue)';
}

/// Keeps [ReminderOccurrence] rows in step with reality (FR-R-12 / FR-R-13).
///
/// This is the [L-ALIVE] layer: it runs when the app is alive — open, resume,
/// timer end, check-in, day change — and does two things.
///
/// 1. **Advance.** Every unresolved occurrence is re-evaluated against the
///    clock. Because [ReminderStateMachine] is retroactive, the app does not
///    need to have been running when a window closed; a sweep at 6 PM
///    correctly concludes what happened at 3:10 PM.
/// 2. **Backfill.** Every enabled [ReminderConfig] gets an occurrence for the
///    day it is scheduled on, so rows that predate V2 join the machine
///    (PRD §9) and a newly saved reminder is immediately represented.
///
/// Every read and write is local. Nothing here awaits the network.
class ReminderOccurrenceService {
  ReminderOccurrenceService({
    required ReminderOccurrenceRepository occurrences,
    required ReminderRepository reminders,
    DateTime Function()? now,
  }) : _occurrences = occurrences,
       _reminders = reminders,
       _now = now ?? DateTime.now;

  final ReminderOccurrenceRepository _occurrences;
  final ReminderRepository _reminders;
  final DateTime Function() _now;

  /// Backfill horizon. A config scheduled before the start of today does NOT
  /// get an occurrence conjured for it.
  ///
  /// Without this bound, the first sweep after upgrading would mint an
  /// occurrence for every stale config in the database and immediately mark
  /// them overdue — greeting the user with a wall of months-old misses they
  /// can do nothing about. V2's promise is "nothing is lost from here on",
  /// not "here is everything you ever missed".
  static DateTime _backfillFloor(DateTime now) =>
      DateTime(now.year, now.month, now.day);

  /// One [L-ALIVE] pass.
  Future<ReminderSweepResult> sweep() async {
    final now = _now();
    try {
      final created = await _backfill(now);
      final advanced = await _advance(now);
      final result = ReminderSweepResult(
        advanced: advanced.length,
        created: created,
        nowOverdue: advanced
            .where((o) => o.state == ReminderOccurrenceState.overdue)
            .length,
      );
      if (result.didWork) {
        debugPrint('[ReminderOccurrence] sweep: $result');
      }
      return result;
    } catch (e, st) {
      debugPrint('[ReminderOccurrence] sweep failed: $e\n$st');
      return const ReminderSweepResult();
    }
  }

  Future<List<ReminderOccurrence>> _advance(DateTime now) async {
    final open = await _occurrences.listUnresolved();
    if (open.isEmpty) return const [];
    final changed = ReminderStateMachine.advanceAll(open, now: now);
    if (changed.isEmpty) return const [];
    await _occurrences.upsertAll(changed);
    return changed;
  }

  Future<int> _backfill(DateTime now) async {
    final configs = await _reminders.listAllReminders();
    if (configs.isEmpty) return 0;

    final floorMs = _backfillFloor(now).millisecondsSinceEpoch;
    final toCreate = <ReminderOccurrence>[];

    for (final config in configs) {
      if (!config.enabled) continue;
      final scheduledAt = _scheduledAtOf(config);
      if (scheduledAt == null) continue;
      if (scheduledAt.millisecondsSinceEpoch < floorMs) continue;

      final dateKey = DateKeys.yyyymmdd(scheduledAt);
      final existing = await _occurrences.findByKey(
        entityKind: ReminderEntityKinds.task,
        entityId: config.taskId,
        dateKey: dateKey,
      );
      if (existing != null) continue;

      toCreate.add(
        occurrenceForConfig(config, scheduledAt: scheduledAt, now: now),
      );
    }

    if (toCreate.isEmpty) return 0;
    await _occurrences.upsertAll(toCreate);
    return toCreate.length;
  }

  /// Builds (but does not persist) the occurrence a config implies.
  ///
  /// Classification is SNAPSHOT from the config, not recomputed here: the
  /// config carries the stable answer (and the user's override, which must
  /// survive the day), while each occurrence holds the day's copy that the
  /// state machine and the ladder actually read.
  @visibleForTesting
  static ReminderOccurrence occurrenceForConfig(
    ReminderConfig config, {
    required DateTime scheduledAt,
    required DateTime now,
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    return ReminderOccurrence(
      id: StableId.generate('rocc'),
      entityId: config.taskId,
      entityKind: ReminderEntityKinds.task,
      dateKey: DateKeys.yyyymmdd(scheduledAt),
      scheduledAtMs: scheduledAt.millisecondsSinceEpoch,
      windowMinutes: AdaptiveReminderPolicy.windowMinutesFor(config.modeRefId),
      entityTitle: config.taskTitle,
      modeRefId: config.modeRefId,
      state: ReminderOccurrenceState.upcoming,
      taxonomy: config.taxonomy,
      criticality: config.criticality,
      classificationSource: config.classificationSource,
      classifierVersion: config.classifierVersion,
      aiBody: config.aiBody,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
    );
  }

  /// Ensure the occurrence for a just-saved config exists and matches it.
  ///
  /// Called on the save path so a reminder the user just set is represented
  /// immediately, rather than at the next sweep.
  Future<ReminderOccurrence?> ensureForConfig(ReminderConfig config) async {
    if (!config.enabled) return null;
    final scheduledAt = _scheduledAtOf(config);
    if (scheduledAt == null) return null;

    final now = _now();
    final dateKey = DateKeys.yyyymmdd(scheduledAt);
    final existing = await _occurrences.findByKey(
      entityKind: ReminderEntityKinds.task,
      entityId: config.taskId,
      dateKey: dateKey,
    );

    if (existing != null) {
      // An already-resolved day is not reopened by a config edit; the edit
      // produces the NEXT occurrence instead.
      if (existing.isResolved) return existing;
      final updated = existing.copyWith(
        scheduledAtMs: scheduledAt.millisecondsSinceEpoch,
        windowMinutes: AdaptiveReminderPolicy.windowMinutesFor(
          config.modeRefId,
        ),
        entityTitle: config.taskTitle,
        modeRefId: config.modeRefId,
        taxonomy: config.taxonomy,
        criticality: config.criticality,
        classificationSource: config.classificationSource,
        classifierVersion: config.classifierVersion,
        aiBody: config.aiBody,
        updatedAtMs: now.millisecondsSinceEpoch,
      );
      final advanced = ReminderStateMachine.advance(updated, now: now);
      await _occurrences.upsert(advanced);
      return advanced;
    }

    final created = ReminderStateMachine.advance(
      occurrenceForConfig(config, scheduledAt: scheduledAt, now: now),
      now: now,
    );
    await _occurrences.upsert(created);
    return created;
  }

  /// Register one armed goal occurrence with the state machine (FR-R-14).
  ///
  /// Goals hold no reminder config of their own — `applyForGoal` derives their
  /// fire times from `UserGoal` — so this is their entry point into the same
  /// machine tasks use. Taxonomy follows intensity (settled with Miko
  /// 2026-08-31, closing audit C2): a disciplined/extreme-intensity goal's
  /// missed day is `flexible`-class — it lands on the Recovery Card and
  /// demands what the mode demands — while low-intensity goals stay
  /// `routine`, aggregating into the digest line. Hardcoding all goals to
  /// routine meant a missed STAKED goal day surfaced less than an ordinary
  /// Disciplined task.
  Future<ReminderOccurrence?> ensureForGoalOccurrence({
    required String goalId,
    required String title,
    required DateTime scheduledAt,
    String? modeRefId,
  }) async {
    final now = _now();
    final dateKey = DateKeys.yyyymmdd(scheduledAt);
    final taxonomy = goalTaxonomyForMode(modeRefId);
    final existing = await _occurrences.findByKey(
      entityKind: ReminderEntityKinds.goal,
      entityId: goalId,
      dateKey: dateKey,
    );
    // A day already dealt with is not reopened by a re-arm sweep.
    if (existing != null && existing.isResolved) return existing;

    final base =
        existing ??
        ReminderOccurrence(
          id: StableId.generate('rocc'),
          entityId: goalId,
          entityKind: ReminderEntityKinds.goal,
          dateKey: dateKey,
          scheduledAtMs: scheduledAt.millisecondsSinceEpoch,
          windowMinutes: AdaptiveReminderPolicy.windowMinutesFor(modeRefId),
          entityTitle: title,
          modeRefId: modeRefId,
          taxonomy: taxonomy,
          classificationSource: ClassificationSource.heuristic,
          createdAtMs: now.millisecondsSinceEpoch,
          updatedAtMs: now.millisecondsSinceEpoch,
        );

    final updated = base.copyWith(
      scheduledAtMs: scheduledAt.millisecondsSinceEpoch,
      windowMinutes: AdaptiveReminderPolicy.windowMinutesFor(modeRefId),
      entityTitle: title,
      modeRefId: modeRefId,
      // Intensity edits retune the class on re-arm (a goal raised to
      // disciplined starts surfacing its misses; one lowered stops).
      taxonomy: taxonomy,
      updatedAtMs: now.millisecondsSinceEpoch,
    );
    final advanced = ReminderStateMachine.advance(updated, now: now);
    await _occurrences.upsert(advanced);
    return advanced;
  }

  /// C2's mapping, exposed for tests: disciplined/extreme intensity →
  /// `flexible` (misses surface on the card); everything else → `routine`.
  static ReminderTaxonomy goalTaxonomyForMode(String? modeRefId) =>
      switch ((modeRefId ?? '').trim().toLowerCase()) {
        'disciplined' || 'extreme' => ReminderTaxonomy.flexible,
        _ => ReminderTaxonomy.routine,
      };

  /// Resolve whatever occurrence [entityId] currently has open (FR-R-13).
  ///
  /// Completing, skipping or rescheduling a task is one user gesture: the
  /// local write and the state change happen together, with no network in
  /// between.
  Future<ReminderOccurrence?> resolveForEntity(
    String entityId, {
    required ReminderResolutionKind kind,
    String? reason,
  }) async {
    final open = await _openFor(entityId);
    if (open == null) return null;
    final resolved = ReminderStateMachine.resolve(
      open,
      kind: kind,
      reason: reason,
      now: _now(),
    );
    await _occurrences.upsert(resolved);
    return resolved;
  }

  /// The user started this entity — a timer, a focus session, a check-in.
  Future<ReminderOccurrence?> markActiveForEntity(String entityId) async {
    final open = await _openFor(entityId);
    if (open == null) return null;
    final active = ReminderStateMachine.markActive(open, now: _now());
    if (identical(active, open)) return open;
    await _occurrences.upsert(active);
    return active;
  }

  /// How many times in a row this entity's most recent occurrences were
  /// rescheduled rather than done (D4 / FR-R-42).
  ///
  /// Counted from occurrence history rather than a counter on the config,
  /// because "consecutive" is a property of the sequence: doing the task once
  /// breaks the streak, and a stored counter would need remembering to reset.
  Future<int> consecutiveReschedules(String entityId) async {
    final rows = await _occurrences.listForEntity(entityId);
    var count = 0;
    for (final row in rows) {
      // listForEntity is newest-first; stop at the first occurrence that
      // ended any other way.
      if (row.resolutionKind == ReminderResolutionKind.rescheduled) {
        count++;
        continue;
      }
      if (row.isResolved) break;
      // An unresolved occurrence (today's, still open) does not break the
      // streak — it has not ended yet.
    }
    return count;
  }

  /// The user hit "Wrong time": this moment was wrong, so the window closes
  /// NOW rather than at its scheduled end (FR-R-35 / AUDIT A8).
  ///
  /// Taxonomy decides what that means, exactly as a natural close would:
  /// time-sensitive expires (logged as missed, never mentioned again);
  /// routine expires into the digest; flexible goes straight to Overdue —
  /// stamped to now, because the user just declared the window over.
  Future<ReminderOccurrence?> closeWindowNow(String entityId) async {
    final open = await _openFor(entityId);
    if (open == null) return null;
    final now = _now();
    final ReminderOccurrence closed;
    if (open.taxonomy == ReminderTaxonomy.flexible) {
      closed = open.copyWith(
        state: ReminderOccurrenceState.overdue,
        overdueSinceMs: now.millisecondsSinceEpoch,
        updatedAtMs: now.millisecondsSinceEpoch,
      );
    } else {
      closed = ReminderStateMachine.resolve(
        open,
        kind: ReminderResolutionKind.expired,
        now: now,
      );
    }
    await _occurrences.upsert(closed);
    return closed;
  }

  /// The user hit "Later": record where their snooze re-plans delivery to,
  /// so the compiler stops re-arming the slots it pre-empts (FR-R-35).
  Future<ReminderOccurrence?> recordSnooze(
    String entityId, {
    required DateTime until,
  }) async {
    final open = await _openFor(entityId);
    if (open == null) return null;
    final updated = open.copyWith(
      snoozedUntilMs: until.millisecondsSinceEpoch,
      updatedAtMs: _now().millisecondsSinceEpoch,
    );
    await _occurrences.upsert(updated);
    return updated;
  }

  /// Wave a row off the Recovery Card for today (FR-R-40, Flexible only).
  ///
  /// Deliberately not a resolution: the task is still undone, so the
  /// occurrence keeps its state and its overdue history, and day rollover
  /// carries it into Plan-Tomorrow as a suggestion. It just stops being
  /// mentioned for the rest of today.
  Future<ReminderOccurrence?> dismissForToday(String entityId) async {
    final open = await _openFor(entityId);
    if (open == null) return null;
    final now = _now();
    final dismissed = open.copyWith(
      dismissedForDayKey: DateKeys.todayKey(now),
      updatedAtMs: now.millisecondsSinceEpoch,
    );
    await _occurrences.upsert(dismissed);
    return dismissed;
  }

  /// The entity is gone. Its occurrences go with it — a deleted task must not
  /// keep surfacing on the Recovery Card.
  Future<void> deleteForEntity(String entityId) =>
      _occurrences.deleteForEntity(entityId);

  /// The most recent unresolved occurrence for [entityId], if any.
  Future<ReminderOccurrence?> _openFor(String entityId) async {
    final rows = await _occurrences.listForEntity(entityId);
    for (final row in rows) {
      if (!row.isResolved) return row;
    }
    return null;
  }

  static DateTime? _scheduledAtOf(ReminderConfig config) {
    final iso = config.scheduledAtIso;
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }
}
