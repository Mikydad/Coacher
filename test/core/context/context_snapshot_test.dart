import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/context/calendar_signal.dart';
import 'package:sidepal/core/context/context_snapshot.dart';
import 'package:sidepal/core/context/context_snapshot_service.dart';

class _EnabledChannel extends CalendarSignalChannel {
  _EnabledChannel(this.intervals);
  final List<CalendarBusyInterval> intervals;

  @override
  Future<String> getAuthorizationStatus() async => 'authorized';

  @override
  Future<List<CalendarBusyInterval>> getBusyIntervals(
    DateTime start,
    DateTime end,
  ) async => intervals;
}

class _UnavailableChannel extends CalendarSignalChannel {
  @override
  Future<String> getAuthorizationStatus() async => 'unavailable';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContextSnapshot.coarseLabels', () {
    test('emits only available signals, coarse shapes only', () {
      final snapshot = ContextSnapshot(
        capturedAtMs: 0,
        online: false,
        overrideMode: 'focus',
        freeMinutesNow: 25,
        nextCalendarEventStartMs: DateTime(2026, 7, 24, 14).millisecondsSinceEpoch,
      );
      expect(snapshot.coarseLabels(), [
        'free_25m',
        'next_calendar_event_14:00',
        'mode_focus',
        'offline',
      ]);
    });

    test('null signals emit nothing', () {
      const snapshot = ContextSnapshot(capturedAtMs: 0, online: true);
      expect(snapshot.coarseLabels(), isEmpty);
    });
  });

  group('ContextSnapshotService.capture', () {
    final now = DateTime(2026, 7, 24, 13, 30);

    ContextSnapshotService build({
      List<Map<String, dynamic>> schedule = const [],
      CalendarSignalChannel? channel,
      String? mode,
      bool? online = true,
    }) {
      return ContextSnapshotService(
        scheduleMapsForDay: (_) async => schedule,
        overrideMode: () async => mode,
        isOnline: () async => online,
        calendarSignal: CalendarSignalService(
          channel: channel ?? _UnavailableChannel(),
        ),
        now: () => now,
      );
    }

    test('free minutes reflect schedule + calendar busy together', () async {
      SharedPreferences.setMockInitialValues({
        CalendarSignalSettings.prefsKey: 'enabled',
      });
      final service = build(
        schedule: const [
          {'title': 'Standup', 'startTime': '09:00', 'endTime': '10:00'},
        ],
        channel: _EnabledChannel([
          CalendarBusyInterval(
            startMs: DateTime(2026, 7, 24, 14).millisecondsSinceEpoch,
            endMs: DateTime(2026, 7, 24, 15).millisecondsSinceEpoch,
          ),
        ]),
      );
      final snapshot = await service.capture();
      // 13:30 → the 14:00 meeting ends the current window in 30 minutes.
      expect(snapshot.freeMinutesNow, 30);
      expect(snapshot.currentWindowEndsBefore, 'your 14:00');
      expect(snapshot.hasCalendarSignal, isTrue);
      expect(
        snapshot.nextCalendarEventStartMs,
        DateTime(2026, 7, 24, 14).millisecondsSinceEpoch,
      );
    });

    test('calendar unavailable → nullable degradation, no claims', () async {
      SharedPreferences.setMockInitialValues({});
      final service = build(mode: 'focus', online: false);
      final snapshot = await service.capture();
      expect(snapshot.hasCalendarSignal, isFalse);
      expect(snapshot.nextCalendarEventStartMs, isNull);
      expect(snapshot.overrideMode, 'focus');
      expect(snapshot.online, isFalse);
      // Free window still computed from the schedule alone.
      expect(snapshot.freeMinutesNow, isNotNull);
    });
  });
}
