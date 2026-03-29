import 'package:coach_for_life/features/goals/application/goal_intensity_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('intensity 1 and 2 map to flexible', () {
    expect(GoalIntensityMode.routineModeFromGoalIntensity(1), RoutineMode.flexible);
    expect(GoalIntensityMode.routineModeFromGoalIntensity(2), RoutineMode.flexible);
    expect(GoalIntensityMode.modeRefIdFromGoalIntensity(2), 'flexible');
  });

  test('intensity 3 and 4 map to disciplined', () {
    expect(GoalIntensityMode.routineModeFromGoalIntensity(3), RoutineMode.disciplined);
    expect(GoalIntensityMode.routineModeFromGoalIntensity(4), RoutineMode.disciplined);
    expect(GoalIntensityMode.modeRefIdFromGoalIntensity(4), 'disciplined');
  });

  test('intensity 5 maps to extreme', () {
    expect(GoalIntensityMode.routineModeFromGoalIntensity(5), RoutineMode.extreme);
    expect(GoalIntensityMode.modeRefIdFromGoalIntensity(5), 'extreme');
  });

  test('intensity outside 1–5 is clamped', () {
    expect(GoalIntensityMode.routineModeFromGoalIntensity(0), RoutineMode.flexible);
    expect(GoalIntensityMode.routineModeFromGoalIntensity(-3), RoutineMode.flexible);
    expect(GoalIntensityMode.routineModeFromGoalIntensity(10), RoutineMode.extreme);
    expect(GoalIntensityMode.clampIntensity(0), 1);
    expect(GoalIntensityMode.clampIntensity(99), 5);
  });

  test('display labels', () {
    expect(GoalIntensityMode.displayLabelForIntensity(1), 'Flexible');
    expect(GoalIntensityMode.displayLabelForIntensity(4), 'Disciplined');
    expect(GoalIntensityMode.displayLabelForIntensity(5), 'Extreme');
  });
}
