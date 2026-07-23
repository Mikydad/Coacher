import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/scheduling/free_window_calculator.dart';

Map<String, dynamic> block(String title, String start, String end) => {
  'title': title,
  'startTime': start,
  'endTime': end,
};

void main() {
  group('FreeWindowCalculator.computeWindows', () {
    test('empty schedule yields one full waking-day window', () {
      final windows = FreeWindowCalculator.computeWindows(const []);
      expect(windows, hasLength(1));
      expect(windows.single.startMinute, 7 * 60);
      expect(windows.single.endMinute, 22 * 60);
      expect(windows.single.beforeTitle, isNull);
    });

    test('gaps between blocks carry the following block title', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('Standup', '09:00', '10:00'),
        block('Dinner', '18:00', '19:00'),
      ]);
      expect(windows, hasLength(3));
      expect(windows[0].startMinute, 7 * 60);
      expect(windows[0].beforeTitle, 'Standup');
      expect(windows[1].startMinute, 10 * 60);
      expect(windows[1].endMinute, 18 * 60);
      expect(windows[1].beforeTitle, 'Dinner');
      // Last gap runs to end of day — no beforeTitle.
      expect(windows[2].endMinute, 22 * 60);
      expect(windows[2].beforeTitle, isNull);
    });

    test('windows shorter than 30 minutes are dropped', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('A', '07:00', '12:00'),
        block('B', '12:20', '22:00'), // 20-min gap → dropped
      ]);
      expect(windows, isEmpty);
    });

    test('overlapping blocks are merged', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('A', '09:00', '11:00'),
        block('B', '10:00', '12:00'),
      ]);
      expect(windows, hasLength(2));
      expect(windows[0].endMinute, 9 * 60);
      expect(windows[1].startMinute, 12 * 60);
    });

    test('fromMinuteOfDay excludes windows already past', () {
      final windows = FreeWindowCalculator.computeWindows(
        [block('Lunch', '13:00', '14:00')],
        fromMinuteOfDay: 12 * 60 + 45, // 12:45
      );
      // 12:45–13:00 is only 15 min → dropped; 14:00–22:00 remains.
      expect(windows, hasLength(1));
      expect(windows.single.startMinute, 14 * 60);
    });

    test('block without endTime defaults to 30 minutes busy', () {
      final windows = FreeWindowCalculator.computeWindows([
        {'title': 'Ping', 'startTime': '12:00'},
      ]);
      expect(windows, hasLength(2));
      expect(windows[1].startMinute, 12 * 60 + 30);
    });
  });

  group('calendar pseudo-blocks (Phase 4b)', () {
    Map<String, dynamic> calendarBlock(String start, String end) => {
      'title': 'your $start',
      'startTime': start,
      'endTime': end,
      'calendar': true,
    };

    test('gap before a calendar event carries beforeIsCalendar', () {
      final windows = FreeWindowCalculator.computeWindows([
        calendarBlock('14:00', '15:00'),
      ]);
      expect(windows.first.beforeIsCalendar, isTrue);
      expect(windows.first.beforeTitle, 'your 14:00');
      // The window after the meeting runs to day end: not calendar-bounded.
      expect(windows.last.beforeIsCalendar, isFalse);
    });

    test('micro-gap before a calendar event survives the 30-minute cut', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('Standup', '09:00', '13:45'),
        calendarBlock('14:00', '15:00'),
      ]);
      // 13:45–14:00 is 15 min — kept ONLY because it ends at a calendar
      // event (minMicroGapMinutes ≤ 15 < minWindowMinutes).
      final micro = windows.firstWhere((w) => w.startMinute == 13 * 60 + 45);
      expect(micro.durationMinutes, 15);
      expect(micro.beforeIsCalendar, isTrue);
    });

    test('same-size gap before a plain block is still dropped', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('Standup', '09:00', '13:45'),
        block('Meeting', '14:00', '15:00'),
      ]);
      expect(
        windows.where((w) => w.startMinute == 13 * 60 + 45),
        isEmpty,
      );
    });

    test('sub-micro gaps are dropped even before calendar events', () {
      final windows = FreeWindowCalculator.computeWindows([
        block('Standup', '09:00', '13:55'),
        calendarBlock('14:00', '15:00'),
      ]);
      expect(
        windows.where((w) => w.startMinute == 13 * 60 + 55),
        isEmpty,
      );
    });

    test('overlap merge keeps the earliest block\'s calendar flag', () {
      final windows = FreeWindowCalculator.computeWindows([
        calendarBlock('14:00', '15:00'),
        block('Overlap task', '14:30', '15:30'),
      ]);
      // The merged 14:00–15:30 interval starts with the calendar event, so
      // the preceding gap is calendar-bounded.
      expect(windows.first.beforeIsCalendar, isTrue);
      expect(windows.first.endMinute, 14 * 60);
    });
  });

  group('formatting', () {
    test('computeFormatted matches the legacy assembler shape', () {
      final formatted = FreeWindowCalculator.computeFormatted([
        block('Standup', '09:00', '10:00'),
      ]);
      expect(formatted.first, '07:00–09:00 (2h)');
    });

    test('formatSpan covers hour/minute combinations', () {
      expect(FreeWindowCalculator.formatSpan(25), '25m');
      expect(FreeWindowCalculator.formatSpan(60), '1h');
      expect(FreeWindowCalculator.formatSpan(150), '2h 30m');
    });
  });
}
