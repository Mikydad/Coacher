import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/context/calendar_signal.dart';
import 'package:sidepal/core/context/context_snapshot_service.dart';

/// Scripted channel fake — no platform, fully deterministic.
class FakeCalendarChannel extends CalendarSignalChannel {
  FakeCalendarChannel({
    this.status = 'notDetermined',
    this.grantOnRequest = true,
    this.intervals = const [],
  });

  String status;
  bool grantOnRequest;
  List<CalendarBusyInterval> intervals;
  int requestCount = 0;

  @override
  Future<String> getAuthorizationStatus() async => status;

  @override
  Future<bool> requestAccess() async {
    requestCount++;
    if (grantOnRequest) status = 'authorized';
    return grantOnRequest;
  }

  @override
  Future<List<CalendarBusyInterval>> getBusyIntervals(
    DateTime start,
    DateTime end,
  ) async => intervals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CalendarBusyInterval.fromMap', () {
    test('parses valid maps and rejects malformed ones', () {
      final ok = CalendarBusyInterval.fromMap({
        'startMs': 1000,
        'endMs': 2000,
        'allDay': true,
      });
      expect(ok, isNotNull);
      expect(ok!.allDay, isTrue);

      expect(CalendarBusyInterval.fromMap({'startMs': 'x'}), isNull);
      expect(
        CalendarBusyInterval.fromMap({'startMs': 2000, 'endMs': 1000}),
        isNull,
      );
    });
  });

  group('CalendarSignalService', () {
    test('busyIntervals is null until the user enables the signal', () async {
      final channel = FakeCalendarChannel(status: 'authorized');
      final service = CalendarSignalService(channel: channel);
      expect(
        await service.busyIntervals(DateTime(2026), DateTime(2027)),
        isNull,
      );
    });

    test('enable requests the OS grant and remembers the outcome', () async {
      final channel = FakeCalendarChannel(grantOnRequest: true);
      final service = CalendarSignalService(channel: channel);
      expect(await service.enable(), isTrue);
      expect(channel.requestCount, 1);
      expect(await service.getChoice(), CalendarSignalChoice.enabled);
      expect(
        await service.busyIntervals(DateTime(2026), DateTime(2027)),
        isNotNull,
      );
    });

    test('OS denial is remembered as declined', () async {
      final channel = FakeCalendarChannel(grantOnRequest: false);
      final service = CalendarSignalService(channel: channel);
      expect(await service.enable(), isFalse);
      expect(await service.getChoice(), CalendarSignalChoice.declined);
    });

    test('declined choice silences the ask forever', () async {
      final channel = FakeCalendarChannel();
      final service = CalendarSignalService(channel: channel);
      expect(await service.shouldOfferAsk(), isTrue);
      await service.decline();
      expect(await service.shouldOfferAsk(), isFalse);
    });

    test('ask is not offered when the OS already denied', () async {
      final channel = FakeCalendarChannel(status: 'denied');
      final service = CalendarSignalService(channel: channel);
      expect(await service.shouldOfferAsk(), isFalse);
    });

    test('all-day events are dropped from busy intervals', () async {
      final channel = FakeCalendarChannel(
        status: 'authorized',
        intervals: [
          const CalendarBusyInterval(startMs: 1000, endMs: 2000),
          const CalendarBusyInterval(startMs: 0, endMs: 9000, allDay: true),
        ],
      );
      final service = CalendarSignalService(channel: channel);
      await service.enable();
      final busy = await service.busyIntervals(DateTime(2026), DateTime(2027));
      expect(busy, hasLength(1));
      expect(busy!.single.allDay, isFalse);
    });

    test('signal degrades to null when OS grant was revoked later', () async {
      final channel = FakeCalendarChannel(grantOnRequest: true);
      final service = CalendarSignalService(channel: channel);
      await service.enable();
      channel.status = 'denied'; // revoked in iOS Settings afterwards
      expect(
        await service.busyIntervals(DateTime(2026), DateTime(2027)),
        isNull,
      );
    });
  });

  group('calendarBusyToScheduleMaps', () {
    final day = DateTime(2026, 7, 24);

    test('converts intervals to coarse pseudo-blocks with time labels', () {
      final maps = calendarBusyToScheduleMaps([
        CalendarBusyInterval(
          startMs: DateTime(2026, 7, 24, 14).millisecondsSinceEpoch,
          endMs: DateTime(2026, 7, 24, 15).millisecondsSinceEpoch,
        ),
      ], day);
      expect(maps, hasLength(1));
      expect(maps.single['title'], 'your 14:00');
      expect(maps.single['startTime'], '14:00');
      expect(maps.single['endTime'], '15:00');
      expect(maps.single['calendar'], isTrue);
    });

    test('clamps multi-day events and skips other days', () {
      final maps = calendarBusyToScheduleMaps([
        // Ends tomorrow → clamped to day end.
        CalendarBusyInterval(
          startMs: DateTime(2026, 7, 24, 21).millisecondsSinceEpoch,
          endMs: DateTime(2026, 7, 25, 10).millisecondsSinceEpoch,
        ),
        // Entirely tomorrow → excluded.
        CalendarBusyInterval(
          startMs: DateTime(2026, 7, 25, 9).millisecondsSinceEpoch,
          endMs: DateTime(2026, 7, 25, 10).millisecondsSinceEpoch,
        ),
      ], day);
      expect(maps, hasLength(1));
      expect(maps.single['startTime'], '21:00');
      expect(maps.single['endTime'], '23:59');
    });
  });
}
