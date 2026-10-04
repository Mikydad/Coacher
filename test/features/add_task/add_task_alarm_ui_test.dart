import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/add_task/presentation/sections/add_task_reminder_section.dart';
import 'package:sidepal/features/add_task/presentation/sections/add_task_sleep_extras_section.dart';

/// feat/alarm-mode: where the alarm option lives, and where it must not.
///
/// Settled 2026-09-13: Sleep gets a full "Wake-up alarm" row in its extras
/// card (the alarm IS the point there); every other category gets a small
/// chip beside the reminder's plan-day footnote, so the option never
/// competes with the pickers.

Widget _reminder({
  required String? category,
  bool alarm = false,
  bool systemAlarm = false,
  ValueChanged<bool>? onAlarmChanged,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: AddTaskReminderSection(
        sectionKey: GlobalKey(),
        reminderEnabled: true,
        reminderTime: DateTime(2026, 9, 13, 22, 0),
        category: category,
        effectiveDurationMinutes: 480,
        planDateKey: '2026-09-13',
        onReminderToggled: (_) {},
        onReminderTimeChanged: (_) {},
        alarm: alarm,
        systemAlarm: systemAlarm,
        onAlarmChanged: onAlarmChanged ?? (_) {},
      ),
    ),
  ),
);

Widget _sleepExtras({
  required String? category,
  bool alarm = false,
  String? sleepEndLabel,
  ValueChanged<bool>? onAlarmChanged,
}) => MaterialApp(
  home: Scaffold(
    body: AddTaskSleepExtrasSection(
      category: category,
      syncSleepWindowAndQuietMode: true,
      inAppQuietMode: 'sleep',
      onSyncChanged: (_) {},
      onQuietModeChanged: (_) {},
      alarm: alarm,
      sleepEndLabel: sleepEndLabel,
      onAlarmChanged: onAlarmChanged ?? (_) {},
    ),
  ),
);

void main() {
  group('reminder card chip', () {
    testWidgets('a normal task shows the chip, off, and toggles it', (
      tester,
    ) async {
      bool? toggled;
      await tester.pumpWidget(
        _reminder(category: 'Work', onAlarmChanged: (v) => toggled = v),
      );
      expect(find.byType(AddTaskAlarmChip), findsOneWidget);
      expect(find.text('Alarm'), findsOneWidget);
      expect(find.text('Alarm on'), findsNothing);

      await tester.tap(find.byType(AddTaskAlarmChip));
      expect(toggled, isTrue);
    });

    testWidgets('when on, the chip says so and the footnote explains the ring',
        (tester) async {
      await tester.pumpWidget(_reminder(category: 'Work', alarm: true));
      await tester.pumpAndSettle();
      expect(find.text('Alarm on'), findsOneWidget);
      expect(find.textContaining('every 2 minutes'), findsOneWidget);
      expect(find.byIcon(Icons.alarm_on_rounded), findsOneWidget);
    });

    testWidgets('with AlarmKit, the footnote promises an alarm clock, not '
        'notification rings (iOS 26+, 2026-10-04)', (tester) async {
      await tester.pumpWidget(
        _reminder(category: 'Work', alarm: true, systemAlarm: true),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('even on silent'), findsOneWidget);
      expect(find.textContaining('every 2 minutes'), findsNothing);
    });

    testWidgets('Sleep hides the chip — its alarm lives in the extras card', (
      tester,
    ) async {
      await tester.pumpWidget(_reminder(category: 'Sleep', alarm: true));
      expect(find.byType(AddTaskAlarmChip), findsNothing);
      expect(find.textContaining('every 2 minutes'), findsNothing);
      // The pickers are untouched.
      expect(find.text('Sleep start'), findsOneWidget);
      expect(find.text('Sleep end'), findsOneWidget);
    });
  });

  group('Sleep extras wake-up row', () {
    testWidgets('names the sleep-end time and toggles', (tester) async {
      bool? toggled;
      await tester.pumpWidget(
        _sleepExtras(
          category: 'Sleep',
          alarm: true,
          sleepEndLabel: '6:00 AM',
          onAlarmChanged: (v) => toggled = v,
        ),
      );
      expect(find.text('Wake-up alarm'), findsOneWidget);
      expect(find.textContaining('6:00 AM'), findsOneWidget);

      await tester.tap(find.text('Wake-up alarm'));
      expect(toggled, isFalse);
    });

    testWidgets('renders nothing at all for a non-sleep category', (
      tester,
    ) async {
      await tester.pumpWidget(_sleepExtras(category: 'Work', alarm: true));
      expect(find.text('Wake-up alarm'), findsNothing);
    });
  });
}
