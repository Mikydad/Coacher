import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/add_task/application/saved_for_another_day.dart';

/// A task filed under another day says so after saving (2026-09-24).
void main() {
  const today = '2026-09-24'; // a Thursday

  test('today → nothing to say', () {
    expect(
      savedForAnotherDayMessage(planDateKey: today, todayKey: today),
      isNull,
    );
  });

  test('tomorrow and yesterday get their words', () {
    expect(
      savedForAnotherDayMessage(planDateKey: '2026-09-25', todayKey: today),
      'Saved for tomorrow. Find it in Tasks under "Open on other days".',
    );
    expect(
      savedForAnotherDayMessage(planDateKey: '2026-09-23', todayKey: today),
      startsWith('Saved for yesterday.'),
    );
  });

  test('further out names the weekday and date', () {
    expect(
      savedForAnotherDayMessage(planDateKey: '2026-09-28', todayKey: today),
      startsWith('Saved for Mon 28 Sep.'),
    );
  });
}
