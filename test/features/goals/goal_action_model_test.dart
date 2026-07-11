import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/goals/domain/models/goal_action.dart';

void main() {
  test('fromMap defaults completed to false', () {
    final a = GoalAction.fromMap({
      'id': 'a1',
      'goalId': 'g1',
      'title': 'Read',
      'orderIndex': 0,
    });
    expect(a.completed, isFalse);
  });

  test('copyWith and toMap persist completed', () {
    const a = GoalAction(
      id: 'a1',
      goalId: 'g1',
      title: 'Read',
      orderIndex: 0,
      completed: true,
    );
    expect(a.toMap()['completed'], isTrue);
    expect(GoalAction.fromMap(a.toMap()).completed, isTrue);
  });

  test('repeatWeekdays and completedDateKeys roundtrip through map', () {
    const a = GoalAction(
      id: 'a1',
      goalId: 'g1',
      title: 'Stretch',
      orderIndex: 0,
      repeatWeekdays: [DateTime.monday, DateTime.friday],
      completedDateKeys: ['2025-03-03'],
    );
    final restored = GoalAction.fromMap(a.toMap());
    expect(restored.repeatWeekdays, [DateTime.monday, DateTime.friday]);
    expect(restored.completedDateKeys, ['2025-03-03']);
    expect(restored.isRepeating, isTrue);
  });

  test('one-time action: isCompletedOn mirrors completed flag', () {
    const a = GoalAction(
      id: 'a1',
      goalId: 'g1',
      title: 'Read',
      orderIndex: 0,
      completed: true,
    );
    expect(a.isRepeating, isFalse);
    expect(a.isCompletedOn('2025-03-03'), isTrue);
    expect(a.withCompletionOn('2025-03-03', done: false).completed, isFalse);
  });

  test('repeating action resets per scheduled day', () {
    const a = GoalAction(
      id: 'a1',
      goalId: 'g1',
      title: 'Stretch',
      orderIndex: 0,
      repeatWeekdays: [DateTime.monday, DateTime.wednesday],
    );
    // Monday 2025-03-03: complete it.
    final doneMonday = a.withCompletionOn('2025-03-03', done: true);
    expect(doneMonday.isCompletedOn('2025-03-03'), isTrue);
    // Wednesday 2025-03-05: fresh again.
    expect(doneMonday.isCompletedOn('2025-03-05'), isFalse);
    // Undo Monday.
    final undone = doneMonday.withCompletionOn('2025-03-03', done: false);
    expect(undone.isCompletedOn('2025-03-03'), isFalse);
  });

  test('isScheduledOn respects repeat weekdays', () {
    const a = GoalAction(
      id: 'a1',
      goalId: 'g1',
      title: 'Stretch',
      orderIndex: 0,
      repeatWeekdays: [DateTime.monday],
    );
    expect(a.isScheduledOn(DateTime(2025, 3, 3)), isTrue); // Monday
    expect(a.isScheduledOn(DateTime(2025, 3, 4)), isFalse); // Tuesday
    const oneTime = GoalAction(
      id: 'a2',
      goalId: 'g1',
      title: 'Buy shoes',
      orderIndex: 1,
    );
    expect(oneTime.isScheduledOn(DateTime(2025, 3, 4)), isTrue);
  });
}
