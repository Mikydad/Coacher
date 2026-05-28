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
}
