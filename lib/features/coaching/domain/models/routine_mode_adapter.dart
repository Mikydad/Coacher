import '../../../planning/domain/models/routine_mode.dart';
import 'coaching_style.dart';
import 'enforcement_mode.dart';

/// Backward-compatibility adapter between the deprecated [RoutineMode] and
/// the new [EnforcementMode] / [CoachingStyle] enums.
///
/// Use this to migrate call sites that still consume [RoutineMode].
/// New code must use [CoachingStyle] (global) and [EnforcementMode] (per-entity).
abstract final class RoutineModeAdapter {
  /// Maps a [RoutineMode] to its equivalent [EnforcementMode] (1:1 mapping).
  static EnforcementMode toEnforcementMode(RoutineMode mode) {
    switch (mode) {
      case RoutineMode.flexible:
        return EnforcementMode.flexible;
      case RoutineMode.disciplined:
        return EnforcementMode.disciplined;
      case RoutineMode.extreme:
        return EnforcementMode.extreme;
    }
  }

  /// Returns the default [CoachingStyle] implied by a [RoutineMode].
  ///
  /// Mapping:
  /// - `flexible`    → `supportive`
  /// - `disciplined` → `disciplined`
  /// - `extreme`     → `intense`
  static CoachingStyle defaultStyleForMode(RoutineMode mode) {
    switch (mode) {
      case RoutineMode.flexible:
        return CoachingStyle.supportive;
      case RoutineMode.disciplined:
        return CoachingStyle.disciplined;
      case RoutineMode.extreme:
        return CoachingStyle.intense;
    }
  }

  /// Reverse: maps an [EnforcementMode] back to the nearest [RoutineMode].
  /// Useful for adapters that still write [RoutineMode] for backward compat.
  static RoutineMode toRoutineMode(EnforcementMode mode) {
    switch (mode) {
      case EnforcementMode.flexible:
        return RoutineMode.flexible;
      case EnforcementMode.disciplined:
        return RoutineMode.disciplined;
      case EnforcementMode.extreme:
        return RoutineMode.extreme;
    }
  }
}
