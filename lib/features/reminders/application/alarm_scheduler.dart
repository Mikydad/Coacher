import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/notifications/notification_budget.dart';
import '../../../core/utils/date_keys.dart';
import '../data/reminder_occurrence_repository.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import 'notification_route_resolver.dart';
import 'reminder_copy_bank.dart';

/// The OS surface the alarm scheduler needs (test seam).
abstract interface class AlarmNotificationsPort {
  int idFromTaskAlarm(String taskId, {int ring});
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  });
  Future<void> cancel(int id);
}

class LocalAlarmNotificationsPort implements AlarmNotificationsPort {
  LocalAlarmNotificationsPort(this._inner);
  final LocalNotificationsService _inner;

  @override
  int idFromTaskAlarm(String taskId, {int ring = 0}) =>
      _inner.idFromTaskAlarm(taskId, ring: ring);

  @override
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) => _inner.scheduleAlarm(
    id: id,
    title: title,
    body: body,
    when: when,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => _inner.cancel(id);
}

/// Payload prefix for an alarm ring's tap/action route. Distinct from
/// `task:` so the response handler can stop the rings before doing anything
/// else, and so a ring never falls into the focus-timer tap flow.
const String kAlarmPayloadPrefix = 'alarm:';

String alarmPayloadFor(String taskId) =>
    '$kAlarmPayloadPrefix${Uri.encodeComponent(taskId)}';

/// One compiled ring — an exact moment, decided in advance (FR-R-34 applies
/// to alarms exactly as it does to ladders).
class AlarmRing {
  const AlarmRing({
    required this.ring,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  final int ring;
  final DateTime fireAt;
  final String title;
  final String body;

  @override
  String toString() => 'AlarmRing($ring @ $fireAt)';
}

/// What one pass did — returned so callers can log it and tests can assert
/// on it without reaching into the OS.
class AlarmSchedulingResult {
  const AlarmSchedulingResult({this.armed = 0, this.cleared = 0});

  /// Rings scheduled.
  final int armed;

  /// Alarm configs whose rings were cancelled (stopped, resolved, disabled,
  /// or simply over).
  final int cleared;

  bool get didWork => armed > 0 || cleared > 0;

  @override
  String toString() => 'AlarmSchedulingResult(armed: $armed, cleared: $cleared)';
}

/// Arms and retires alarm **ring ladders** (feat/alarm-mode).
///
/// ## Why this is not part of [LadderCompiler]
///
/// The mode ladder is *polite by construction*: it stops at the interruption
/// boundary, inside the Focus Shield and the sleep window, and it is
/// evaluated by the attention orchestrator, which may batch, delay or
/// silence a slot. Every one of those is correct for a reminder and wrong
/// for an alarm — the user chose "alarm" precisely so that nothing decides
/// on their behalf that this moment is inconvenient. So a ring is scheduled
/// straight onto the OS from here, in its own id namespace, and the only
/// things that retire it are the user (Stop / Snooze / Done on a ring), the
/// task being resolved before its start-anchored alarm, the config being
/// switched off, or the ring window simply passing.
///
/// ## Lifecycle rules (settled with Miko 2026-09-13)
///
/// * Rings: `alarmAt + 0, 2, 4, 6, 8 min` — five rings over ten minutes.
/// * `alarmOffsetMinutes == 0` (start-anchored, every non-Sleep task): the
///   alarm is retired when the occurrence resolves, whatever the kind. Done
///   early means no ring.
/// * `alarmOffsetMinutes > 0` (end-anchored, Sleep's wake-up): a `completed`
///   resolution does NOT retire it — marking Sleep done at bedtime must not
///   silence tomorrow's wake-up. Any other resolution (rescheduled, skipped,
///   expired) does: the day moved or was abandoned.
/// * A stop stamp on the occurrence (`alarmStoppedAtMs`) retires it for
///   good; a snooze (`snoozedUntilMs` past the alarm time) re-bases the five
///   rings on the snooze moment.
/// * Rings are not ledgered. The ledger's reconciliation re-arms a lost row
///   under the task-slot id scheme, which would turn a lost ring into a
///   plain reminder; better to let a lost ring stay lost and be re-armed by
///   the next recompute, which runs on every app open.
///
/// Every read and write is local. Nothing here awaits the network.
class AlarmScheduler {
  AlarmScheduler({
    required ReminderRepository reminders,
    required ReminderOccurrenceRepository occurrences,
    required AlarmNotificationsPort notifications,
    NotificationBudget? budget,
    DateTime Function()? now,
  }) : _reminders = reminders,
       _occurrences = occurrences,
       _notifications = notifications,
       _budget = budget,
       _now = now ?? DateTime.now;

  final ReminderRepository _reminders;
  final ReminderOccurrenceRepository _occurrences;
  final AlarmNotificationsPort _notifications;
  final NotificationBudget? _budget;
  final DateTime Function() _now;

  /// Minutes between rings, and how many — "every 2 min for 10 min".
  static const int ringIntervalMinutes = 2;
  static const int ringCount = 5;

  /// How long "Snooze" on a ring quiets it before the five rings restart.
  static const int snoozeMinutes = 5;

  /// Pure: the rings an alarm config implies at [now], given its occurrence.
  /// Empty means "nothing to arm" — the caller cancels whatever is armed.
  @visibleForTesting
  static List<AlarmRing> compile({
    required ReminderConfig config,
    required ReminderOccurrence? occurrence,
    required DateTime now,
  }) {
    if (!config.enabled || !config.isAlarm) return const [];
    final alarmAt = config.alarmAt;
    if (alarmAt == null) return const [];

    if (occurrence != null) {
      if (occurrence.isAlarmStopped) return const [];
      if (occurrence.isResolved) {
        final endAnchored = config.alarmOffsetMinutes > 0;
        final completed =
            occurrence.resolutionKind == ReminderResolutionKind.completed;
        if (!(endAnchored && completed)) return const [];
      }
    }

    // A snooze past the alarm moment re-bases the whole ring ladder.
    var base = alarmAt;
    final snoozedUntilMs = occurrence?.snoozedUntilMs;
    if (snoozedUntilMs != null) {
      final snoozedUntil = DateTime.fromMillisecondsSinceEpoch(snoozedUntilMs);
      if (snoozedUntil.isAfter(base)) base = snoozedUntil;
    }

    final isWakeUp = config.alarmOffsetMinutes > 0;
    final rings = <AlarmRing>[];
    for (var i = 0; i < ringCount; i++) {
      final fireAt = base.add(Duration(minutes: i * ringIntervalMinutes));
      // Already past — the OS cannot ring yesterday. Later rings may still
      // be ahead, so keep looking rather than break.
      if (!fireAt.isAfter(now)) continue;
      final copy = ReminderCopyBank.alarm(
        entityTitle: config.taskTitle ?? '',
        ring: i,
        isWakeUp: isWakeUp,
      );
      rings.add(
        AlarmRing(ring: i, fireAt: fireAt, title: copy.title, body: copy.body),
      );
    }
    return rings;
  }

  /// Re-arm every alarm config's rings. Idempotent: ring ids are
  /// deterministic, so re-running replaces each ring in place, and rings a
  /// config no longer implies are cancelled.
  Future<AlarmSchedulingResult> rearmAll() async {
    final now = _now();
    try {
      final configs = await _reminders.listAllReminders();
      var armed = 0;
      var cleared = 0;
      var remaining = await (_budget?.remainingCapacity() ??
          Future.value(NotificationBudget.kDefaultSafeCap));

      for (final config in configs) {
        // A config that was never an alarm has nothing armed under alarm
        // ids; skip the cancel sweep so a large reminder list stays cheap.
        if (!config.isAlarm) continue;
        final occurrence = await _occurrenceFor(config);
        final rings = compile(config: config, occurrence: occurrence, now: now);

        if (rings.isEmpty) {
          await _cancelRings(config.taskId);
          cleared++;
          continue;
        }

        final armedRings = <int>{};
        for (final ring in rings) {
          if (remaining <= 0) break;
          await _notifications.scheduleAlarm(
            id: _notifications.idFromTaskAlarm(config.taskId, ring: ring.ring),
            title: ring.title,
            body: ring.body,
            when: ring.fireAt,
            payload: alarmPayloadFor(config.taskId),
          );
          armedRings.add(ring.ring);
          armed++;
          remaining--;
        }
        // Rings this pass did not arm (past, or beyond the budget) must not
        // survive from an earlier pass.
        for (var i = 0; i < ringCount; i++) {
          if (armedRings.contains(i)) continue;
          await _cancelRing(config.taskId, i);
        }
      }

      final result = AlarmSchedulingResult(armed: armed, cleared: cleared);
      if (result.didWork) debugPrint('[AlarmScheduler] $result');
      return result;
    } catch (e, st) {
      debugPrint('[AlarmScheduler] rearm failed: $e\n$st');
      return const AlarmSchedulingResult();
    }
  }

  /// The user stopped the alarm (Stop, Done, or a tap on a ring): cancel
  /// every armed ring and stamp the day so no later recompute re-arms it.
  Future<void> stop(String taskId) async {
    await _cancelRings(taskId);
    final occurrence = await _openOccurrenceFor(taskId);
    if (occurrence == null || occurrence.isAlarmStopped) return;
    final nowMs = _now().millisecondsSinceEpoch;
    await _occurrences.upsert(
      occurrence.copyWith(alarmStoppedAtMs: nowMs, updatedAtMs: nowMs),
    );
  }

  /// "Snooze" on a ring: quiet now, five fresh rings from
  /// [snoozeMinutes] later. Recorded on the occurrence's `snoozedUntilMs`,
  /// the same field the mode ladder honours, so a start-anchored alarm and
  /// its reminder ladder defer together.
  Future<void> snooze(String taskId) async {
    await _cancelRings(taskId);
    final occurrence = await _openOccurrenceFor(taskId);
    if (occurrence == null) return;
    final now = _now();
    final until = now.add(const Duration(minutes: snoozeMinutes));
    await _occurrences.upsert(
      occurrence.copyWith(
        snoozedUntilMs: until.millisecondsSinceEpoch,
        // A snooze after a stop is the user changing their mind.
        alarmStoppedAtMs: null,
        updatedAtMs: now.millisecondsSinceEpoch,
      ),
    );
    await rearmAll();
  }

  /// Cancel every armed ring for [taskId] without stamping anything — for
  /// task deletion and for a start-anchored alarm whose task resolved.
  Future<void> cancelForTask(String taskId) => _cancelRings(taskId);

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _cancelRings(String taskId) async {
    for (var i = 0; i < ringCount; i++) {
      await _cancelRing(taskId, i);
    }
  }

  Future<void> _cancelRing(String taskId, int ring) async {
    try {
      await _notifications.cancel(
        _notifications.idFromTaskAlarm(taskId, ring: ring),
      );
    } catch (e) {
      debugPrint('[AlarmScheduler] cancel swallowed: $e');
    }
  }

  /// The occurrence for the config's scheduled day — the row that carries
  /// the stop stamp and the snooze. Keyed by the REMINDER's day, not the
  /// alarm's: a 10 PM sleep with a 6 AM wake-up is still "tonight's" row.
  Future<ReminderOccurrence?> _occurrenceFor(ReminderConfig config) async {
    final iso = config.scheduledAtIso;
    final scheduledAt = iso == null ? null : DateTime.tryParse(iso);
    if (scheduledAt == null) return null;
    return _occurrences.findByKey(
      entityKind: ReminderEntityKinds.task,
      entityId: config.taskId,
      dateKey: DateKeys.yyyymmdd(scheduledAt),
    );
  }

  /// The row a ring action refers to: the config's current day, whether or
  /// not it has resolved (a Sleep task done at bedtime is resolved, and its
  /// wake-up ring still needs somewhere to record Stop).
  Future<ReminderOccurrence?> _openOccurrenceFor(String taskId) async {
    final configs = await _reminders.listAllReminders();
    for (final config in configs) {
      if (config.taskId != taskId) continue;
      return _occurrenceFor(config);
    }
    return null;
  }
}
