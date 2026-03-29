import '../../planning/domain/models/routine_mode.dart';

/// Maps goal **intensity** (stored as 1–5 on [UserGoal]) to the same execution-mode
/// concept used for tasks and routines:
///
/// | Intensity | Mode |
/// |-----------|------|
/// | 1–2 | [RoutineMode.flexible] |
/// | 3–4 | [RoutineMode.disciplined] |
/// | 5 | [RoutineMode.extreme] |
///
/// Values outside 1–5 are clamped before mapping.
abstract final class GoalIntensityMode {
  static int clampIntensity(int intensity) => intensity.clamp(1, 5);

  static RoutineMode routineModeFromGoalIntensity(int intensity) {
    final i = clampIntensity(intensity);
    if (i <= 2) return RoutineMode.flexible;
    if (i <= 4) return RoutineMode.disciplined;
    return RoutineMode.extreme;
  }

  /// Same as [RoutineMode.name] — aligns with task `modeRefId` storage.
  static String modeRefIdFromGoalIntensity(int intensity) =>
      routineModeFromGoalIntensity(intensity).name;

  static String displayLabelForIntensity(int intensity) {
    switch (routineModeFromGoalIntensity(intensity)) {
      case RoutineMode.flexible:
        return 'Flexible';
      case RoutineMode.disciplined:
        return 'Disciplined';
      case RoutineMode.extreme:
        return 'Extreme';
    }
  }
}
