import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/progress_selection.dart';
import 'package:sidepal/features/analytics/domain/progress_period.dart';

void main() {
  final now = DateTime(2026, 9, 12, 10); // Saturday

  test('starts on today in the Day horizon', () {
    final c = ProgressSelectionController(now);
    expect(c.state.horizon, ProgressHorizon.day);
    expect(c.state.period.key, '2026-09-12');
    expect(c.state.selectedDateKey, '2026-09-12');
  });

  test('switching horizon keeps the anchor day and opens today for week/month', () {
    final c = ProgressSelectionController(now);
    c.setHorizon(ProgressHorizon.week);
    expect(c.state.period.key, '2026-W37');
    expect(c.state.selectedDateKey, '2026-09-12');
    c.setHorizon(ProgressHorizon.month);
    expect(c.state.period.key, '2026-09');
    expect(c.state.selectedDateKey, '2026-09-12');
    c.setHorizon(ProgressHorizon.quarter);
    expect(c.state.period.key, '2026-Q3');
    expect(c.state.selectedDateKey, isNull);
    c.setHorizon(ProgressHorizon.year);
    expect(c.state.period.key, '2026');
    expect(c.state.selectedDateKey, isNull);
  });

  test('zooming in from a past month lands on that month\'s last week', () {
    final c = ProgressSelectionController(now);
    c.setHorizon(ProgressHorizon.month);
    c.previous(); // August
    expect(c.state.period.key, '2026-08');
    expect(c.state.selectedDateKey, isNull); // today not in August
    c.setHorizon(ProgressHorizon.week);
    expect(c.state.period.contains('2026-08-31'), isTrue);
    c.setHorizon(ProgressHorizon.day);
    expect(c.state.period.key, '2026-08-31');
    expect(c.state.selectedDateKey, '2026-08-31');
  });

  test('next never moves into the future', () {
    final c = ProgressSelectionController(now);
    c.setHorizon(ProgressHorizon.week);
    c.next();
    expect(c.state.period.key, '2026-W37');
    c.previous();
    expect(c.state.period.key, '2026-W36');
    c.next();
    expect(c.state.period.key, '2026-W37');
  });

  test('toggleDay opens, closes, and ignores days outside the period', () {
    final c = ProgressSelectionController(now);
    c.setHorizon(ProgressHorizon.week);
    c.toggleDay('2026-09-08');
    expect(c.state.selectedDateKey, '2026-09-08');
    c.toggleDay('2026-09-08');
    expect(c.state.selectedDateKey, isNull);
    c.toggleDay('2026-09-01');
    expect(c.state.selectedDateKey, isNull);
    // Zooming to Day lands on the last-touched day, which stays selected;
    // toggling never clears the Day horizon's own day.
    c.setHorizon(ProgressHorizon.day);
    expect(c.state.period.key, '2026-09-08');
    expect(c.state.selectedDateKey, '2026-09-08');
    c.toggleDay('2026-09-08');
    expect(c.state.selectedDateKey, '2026-09-08');
  });
}
