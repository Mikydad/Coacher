import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/goals/application/goals_providers.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';

/// Home's "Today's goals" empty state names the active goals that are NOT
/// planned for today (2026-09-24), so a goal saved for another day is not
/// mistaken for lost.
UserGoal _goal({
  required String id,
  GoalRepeatCadence cadence = GoalRepeatCadence.daily,
  DateTime? periodStart,
  GoalStatus status = GoalStatus.active,
}) {
  final start = periodStart ?? DateTime(2020, 1, 1);
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'productivity',
    status: status,
    measurementKind: MeasurementKind.count,
    targetValue: 1,
    intensity: 3,
    periodStartMs: start.millisecondsSinceEpoch,
    periodEndMs: DateTime(2030, 1, 1).millisecondsSinceEpoch,
    repeatCadence: cadence,
    repeatInterval: 1,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

Future<int> _count(List<UserGoal> goals) async {
  final container = ProviderContainer(
    overrides: [
      goalsStreamProvider.overrideWith((ref) => Stream.value(goals)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(otherDayGoalsCountProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  return container.read(otherDayGoalsCountProvider);
}

void main() {
  test('a daily goal already running is due today → not counted', () async {
    expect(await _count([_goal(id: 'daily')]), 0);
  });

  test('a future start, a one-time goal, and a paused goal', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(
      await _count([
        _goal(id: 'later', periodStart: tomorrow),
        _goal(id: 'once', cadence: GoalRepeatCadence.off),
        _goal(id: 'paused', status: GoalStatus.paused),
        _goal(id: 'daily'),
      ]),
      2,
      reason: 'future start + one-time count; paused and due-today do not',
    );
  });
}
