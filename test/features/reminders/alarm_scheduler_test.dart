import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/reminders/application/alarm_scheduler.dart';
import 'package:sidepal/features/reminders/application/reminder_state_machine.dart';
import 'package:sidepal/features/reminders/data/reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_alert_mode.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// feat/alarm-mode: the ring ladder's lifecycle rules, settled 2026-09-13.
///
/// Every rule here is one the mode ladder gets WRONG for an alarm — which is
/// why alarms are scheduled straight onto the OS from their own scheduler
/// rather than compiled through [LadderCompiler].

final _now = DateTime(2026, 9, 13, 21, 0);

ReminderConfig _config({
  String taskId = 't1',
  bool enabled = true,
  ReminderAlertMode mode = ReminderAlertMode.alarm,
  DateTime? at,
  int offset = 0,
  String? title = 'Take meds',
}) => ReminderConfig(
  id: 'r_$taskId',
  taskId: taskId,
  taskTitle: title,
  enabled: enabled,
  scheduledAtIso: (at ?? _now.add(const Duration(hours: 1))).toIso8601String(),
  alertMode: mode,
  alarmOffsetMinutes: offset,
  createdAtMs: 0,
  updatedAtMs: 0,
);

ReminderOccurrence _occurrence(
  ReminderConfig config, {
  ReminderOccurrenceState state = ReminderOccurrenceState.upcoming,
  ReminderResolutionKind? resolution,
  int? snoozedUntilMs,
  int? alarmStoppedAtMs,
}) {
  final at = DateTime.parse(config.scheduledAtIso!);
  return ReminderOccurrence(
    id: 'o_${config.taskId}',
    entityId: config.taskId,
    entityKind: 'task',
    dateKey: DateKeys.yyyymmdd(at),
    scheduledAtMs: at.millisecondsSinceEpoch,
    windowMinutes: 30,
    state: state,
    resolutionKind: resolution,
    snoozedUntilMs: snoozedUntilMs,
    alarmStoppedAtMs: alarmStoppedAtMs,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

class _Reminders implements ReminderRepository {
  _Reminders(this.rows);
  final List<ReminderConfig> rows;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Occurrences implements ReminderOccurrenceRepository {
  _Occurrences([Iterable<ReminderOccurrence> seed = const []])
    : rows = {for (final o in seed) o.occurrenceKey: o};
  final Map<String, ReminderOccurrence> rows;

  @override
  Future<ReminderOccurrence?> findByKey({
    required String entityKind,
    required String entityId,
    required String dateKey,
  }) async => rows[ReminderOccurrence.keyFor(entityKind, entityId, dateKey)];

  @override
  Future<void> upsert(ReminderOccurrence occurrence) async {
    rows[occurrence.occurrenceKey] = occurrence;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<List<ReminderOccurrence>>.value(const []);
}

class _Port implements AlarmNotificationsPort {
  final Map<int, DateTime> armed = {};
  final List<int> cancelled = [];

  @override
  int idFromTaskAlarm(String taskId, {int ring = 0}) =>
      ('alarm:$taskId:$ring').hashCode.abs() % 2147483647;

  @override
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    armed[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    armed.remove(id);
  }
}

AlarmScheduler _scheduler(
  _Reminders reminders,
  _Occurrences occurrences,
  _Port port,
) => AlarmScheduler(
  reminders: reminders,
  occurrences: occurrences,
  notifications: port,
  now: () => _now,
);

void main() {
  group('compile', () {
    test('five rings, two minutes apart, from the alarm moment', () {
      final config = _config();
      final rings = AlarmScheduler.compile(
        config: config,
        occurrence: _occurrence(config),
        now: _now,
      );
      expect(rings.map((r) => r.ring), [0, 1, 2, 3, 4]);
      final base = config.alarmAt!;
      for (final r in rings) {
        expect(r.fireAt, base.add(Duration(minutes: r.ring * 2)));
      }
      expect(rings.first.body, contains('Alarm: time for Take meds'));
      expect(rings.last.body, contains('still ringing'));
    });

    test('a plain notification reminder compiles nothing', () {
      final config = _config(mode: ReminderAlertMode.notification);
      expect(
        AlarmScheduler.compile(
          config: config,
          occurrence: _occurrence(config),
          now: _now,
        ),
        isEmpty,
      );
    });

    test('Sleep: the alarm is anchored at sleep END and speaks as a wake-up',
        () {
      final bedtime = DateTime(2026, 9, 13, 22, 0);
      final config = _config(at: bedtime, offset: 8 * 60, title: 'Sleep');
      final rings = AlarmScheduler.compile(
        config: config,
        occurrence: _occurrence(config),
        now: _now,
      );
      expect(rings.first.fireAt, DateTime(2026, 9, 14, 6, 0));
      expect(rings.first.title, 'Wake up');
      expect(rings.first.body, isNot(contains('Sleep')));
    });

    test('past rings are dropped, future ones survive', () {
      // Alarm at 20:56 → rings 20:56, 20:58, 21:00, 21:02, 21:04; now 21:00.
      final config = _config(at: _now.subtract(const Duration(minutes: 4)));
      final rings = AlarmScheduler.compile(
        config: config,
        occurrence: _occurrence(config),
        now: _now,
      );
      expect(rings.map((r) => r.ring), [3, 4]);
    });

    test('a stopped day arms nothing, ever again', () {
      final config = _config();
      expect(
        AlarmScheduler.compile(
          config: config,
          occurrence: _occurrence(config, alarmStoppedAtMs: 1),
          now: _now,
        ),
        isEmpty,
      );
    });

    test('start-anchored: any resolution retires the alarm (done early)', () {
      final config = _config();
      for (final kind in ReminderResolutionKind.values) {
        expect(
          AlarmScheduler.compile(
            config: config,
            occurrence: _occurrence(
              config,
              state: ReminderOccurrenceState.resolved,
              resolution: kind,
            ),
            now: _now,
          ),
          isEmpty,
          reason: kind.name,
        );
      }
    });

    test(
      'end-anchored (wake-up): completed at bedtime or expired overnight '
      'keeps the alarm; moving or skipping the day retires it',
      () {
        final config = _config(
          at: DateTime(2026, 9, 13, 22, 0),
          offset: 8 * 60,
        );
        for (final kind in [
          ReminderResolutionKind.completed,
          ReminderResolutionKind.expired,
        ]) {
          expect(
            AlarmScheduler.compile(
              config: config,
              occurrence: _occurrence(
                config,
                state: ReminderOccurrenceState.resolved,
                resolution: kind,
              ),
              now: _now,
            ),
            hasLength(5),
            reason: kind.name,
          );
        }
        for (final kind in [
          ReminderResolutionKind.rescheduled,
          ReminderResolutionKind.skipped,
        ]) {
          expect(
            AlarmScheduler.compile(
              config: config,
              occurrence: _occurrence(
                config,
                state: ReminderOccurrenceState.resolved,
                resolution: kind,
              ),
              now: _now,
            ),
            isEmpty,
            reason: kind.name,
          );
        }
      },
    );

    test(
      'a routine Sleep that expires after bedtime still wakes you: an app '
      'open at 2 AM must not cancel the wake-up (2026-10-04)',
      () {
        // Sleep 22:00 for 8 h → wake-up at 06:00. A habit-anchored Sleep is
        // `routine`, so its 30-min window closes at 22:30 and the state
        // machine expires it — hours before the alarm is due.
        final config = _config(
          at: DateTime(2026, 9, 13, 22, 0),
          offset: 8 * 60,
          title: 'Sleep',
        );
        final night = DateTime(2026, 9, 14, 2, 0);
        final expired = ReminderStateMachine.advance(
          ReminderOccurrence(
            id: 'o_t1',
            entityId: 't1',
            entityKind: 'task',
            dateKey: '2026-09-13',
            scheduledAtMs: DateTime(2026, 9, 13, 22, 0).millisecondsSinceEpoch,
            windowMinutes: 30,
            taxonomy: ReminderTaxonomy.routine,
            createdAtMs: 0,
            updatedAtMs: 0,
          ),
          now: night,
        );
        expect(expired.resolutionKind, ReminderResolutionKind.expired);

        final rings = AlarmScheduler.compile(
          config: config,
          occurrence: expired,
          now: night,
        );
        expect(rings, hasLength(5));
        expect(rings.first.fireAt, DateTime(2026, 9, 14, 6, 0));
      },
    );

    test('a snooze past the alarm moment re-bases the whole ring ladder', () {
      final config = _config();
      final until = config.alarmAt!.add(const Duration(minutes: 5));
      final rings = AlarmScheduler.compile(
        config: config,
        occurrence: _occurrence(
          config,
          snoozedUntilMs: until.millisecondsSinceEpoch,
        ),
        now: _now,
      );
      expect(rings.first.fireAt, until);
      expect(rings, hasLength(5));
    });

    test('no occurrence yet still arms from the config alone', () {
      final config = _config();
      expect(
        AlarmScheduler.compile(config: config, occurrence: null, now: _now),
        hasLength(5),
      );
    });
  });

  group('rearmAll', () {
    test('arms every ring under the alarm id namespace', () async {
      final config = _config();
      final port = _Port();
      final result = await _scheduler(
        _Reminders([config]),
        _Occurrences([_occurrence(config)]),
        port,
      ).rearmAll();
      expect(result.armed, 5);
      for (var i = 0; i < 5; i++) {
        expect(port.armed, contains(port.idFromTaskAlarm('t1', ring: i)));
      }
      // Never the task-ladder id scheme: cancelForEntity must not reach it.
      expect(
        port.armed.keys,
        isNot(contains(('task:t1:0').hashCode.abs() % 2147483647)),
      );
    });

    test('a config that stops qualifying has its rings cancelled', () async {
      final config = _config();
      final port = _Port();
      final occurrences = _Occurrences([_occurrence(config)]);
      final scheduler = _scheduler(_Reminders([config]), occurrences, port);
      await scheduler.rearmAll();
      expect(port.armed, hasLength(5));

      await occurrences.upsert(_occurrence(config, alarmStoppedAtMs: 1));
      final result = await scheduler.rearmAll();
      expect(result.cleared, 1);
      expect(port.armed, isEmpty);
    });

    test('rings the pass no longer implies are cancelled, not left over',
        () async {
      // First pass at T-10: all five armed. Second pass after ring 0 and 1
      // have passed: only 2..4 are re-armed and 0..1 are cancelled.
      final config = _config(at: _now.add(const Duration(minutes: 10)));
      final port = _Port();
      final reminders = _Reminders([config]);
      final occurrences = _Occurrences([_occurrence(config)]);
      await _scheduler(reminders, occurrences, port).rearmAll();
      expect(port.armed, hasLength(5));

      final later = AlarmScheduler(
        reminders: reminders,
        occurrences: occurrences,
        notifications: port,
        now: () => _now.add(const Duration(minutes: 13)),
      );
      await later.rearmAll();
      expect(port.armed.keys, {
        port.idFromTaskAlarm('t1', ring: 2),
        port.idFromTaskAlarm('t1', ring: 3),
        port.idFromTaskAlarm('t1', ring: 4),
      });
    });

    test('non-alarm reminders are left entirely alone', () async {
      final port = _Port();
      final result = await _scheduler(
        _Reminders([_config(mode: ReminderAlertMode.notification)]),
        _Occurrences(),
        port,
      ).rearmAll();
      expect(result.didWork, isFalse);
      expect(port.cancelled, isEmpty);
    });
  });

  group('stop / snooze', () {
    test('stop cancels the rings and stamps the day', () async {
      final config = _config();
      final port = _Port();
      final occurrences = _Occurrences([_occurrence(config)]);
      final scheduler = _scheduler(_Reminders([config]), occurrences, port);
      await scheduler.rearmAll();

      await scheduler.stop('t1');
      expect(port.armed, isEmpty);
      final row = occurrences.rows.values.single;
      expect(row.isAlarmStopped, isTrue);
      expect(row.alarmStoppedAtMs, _now.millisecondsSinceEpoch);

      // And a later recompute does not bring it back.
      await scheduler.rearmAll();
      expect(port.armed, isEmpty);
    });

    test('stop on a Sleep task already marked done still finds its row',
        () async {
      final config = _config(
        at: DateTime(2026, 9, 13, 22, 0),
        offset: 8 * 60,
      );
      final port = _Port();
      final occurrences = _Occurrences([
        _occurrence(
          config,
          state: ReminderOccurrenceState.resolved,
          resolution: ReminderResolutionKind.completed,
        ),
      ]);
      final scheduler = _scheduler(_Reminders([config]), occurrences, port);
      await scheduler.rearmAll();
      expect(port.armed, hasLength(5));

      await scheduler.stop('t1');
      expect(occurrences.rows.values.single.isAlarmStopped, isTrue);
      await scheduler.rearmAll();
      expect(port.armed, isEmpty);
    });

    test('snooze quiets now and re-arms five rings from five minutes later',
        () async {
      final config = _config(at: _now.subtract(const Duration(minutes: 1)));
      final port = _Port();
      final occurrences = _Occurrences([_occurrence(config)]);
      final scheduler = _scheduler(_Reminders([config]), occurrences, port);
      await scheduler.rearmAll();

      await scheduler.snooze('t1');
      final until = _now.add(
        const Duration(minutes: AlarmScheduler.snoozeMinutes),
      );
      expect(
        occurrences.rows.values.single.snoozedUntilMs,
        until.millisecondsSinceEpoch,
      );
      expect(port.armed, hasLength(5));
      expect(port.armed[port.idFromTaskAlarm('t1', ring: 0)], until);
    });

    test('snooze after a stop is the user changing their mind', () async {
      final config = _config();
      final port = _Port();
      final occurrences = _Occurrences([
        _occurrence(config, alarmStoppedAtMs: 1),
      ]);
      final scheduler = _scheduler(_Reminders([config]), occurrences, port);
      await scheduler.snooze('t1');
      expect(occurrences.rows.values.single.isAlarmStopped, isFalse);
      expect(port.armed, hasLength(5));
    });
  });

  test('alarm payload round-trips the task id', () {
    expect(alarmPayloadFor('t 1/x'), 'alarm:t%201%2Fx');
  });
}
