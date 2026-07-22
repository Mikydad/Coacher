// ignore_for_file: deprecated_member_use

import 'package:sidepal/features/coaching/domain/models/coaching_style.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:sidepal/features/coaching/domain/models/routine_mode_adapter.dart';
import 'package:sidepal/features/planning/domain/models/routine_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── toEnforcementMode ────────────────────────────────────────────────────

  group('RoutineModeAdapter.toEnforcementMode', () {
    test('flexible → EnforcementMode.flexible', () {
      expect(
        RoutineModeAdapter.toEnforcementMode(RoutineMode.flexible),
        EnforcementMode.flexible,
      );
    });

    test('disciplined → EnforcementMode.disciplined', () {
      expect(
        RoutineModeAdapter.toEnforcementMode(RoutineMode.disciplined),
        EnforcementMode.disciplined,
      );
    });

    test('extreme → EnforcementMode.extreme', () {
      expect(
        RoutineModeAdapter.toEnforcementMode(RoutineMode.extreme),
        EnforcementMode.extreme,
      );
    });

    test('all RoutineMode values map to a distinct EnforcementMode', () {
      final mapped = RoutineMode.values
          .map(RoutineModeAdapter.toEnforcementMode)
          .toSet();
      expect(mapped.length, RoutineMode.values.length);
    });
  });

  // ─── defaultStyleForMode ──────────────────────────────────────────────────

  group('RoutineModeAdapter.defaultStyleForMode', () {
    test('flexible → supportive', () {
      expect(
        RoutineModeAdapter.defaultStyleForMode(RoutineMode.flexible),
        CoachingStyle.supportive,
      );
    });

    test('disciplined → disciplined', () {
      expect(
        RoutineModeAdapter.defaultStyleForMode(RoutineMode.disciplined),
        CoachingStyle.disciplined,
      );
    });

    test('extreme → intense', () {
      expect(
        RoutineModeAdapter.defaultStyleForMode(RoutineMode.extreme),
        CoachingStyle.intense,
      );
    });
  });

  // ─── toRoutineMode ────────────────────────────────────────────────────────

  group('RoutineModeAdapter.toRoutineMode', () {
    test('flexible → RoutineMode.flexible', () {
      expect(
        RoutineModeAdapter.toRoutineMode(EnforcementMode.flexible),
        RoutineMode.flexible,
      );
    });

    test('disciplined → RoutineMode.disciplined', () {
      expect(
        RoutineModeAdapter.toRoutineMode(EnforcementMode.disciplined),
        RoutineMode.disciplined,
      );
    });

    test('extreme → RoutineMode.extreme', () {
      expect(
        RoutineModeAdapter.toRoutineMode(EnforcementMode.extreme),
        RoutineMode.extreme,
      );
    });
  });

  // ─── Round-trip ───────────────────────────────────────────────────────────

  group('round-trip: RoutineMode → EnforcementMode → RoutineMode', () {
    for (final mode in RoutineMode.values) {
      test('$mode round-trips cleanly', () {
        final enforcement = RoutineModeAdapter.toEnforcementMode(mode);
        final restored = RoutineModeAdapter.toRoutineMode(enforcement);
        expect(restored, mode);
      });
    }
  });

  // ─── EnforcementMode serialisation ───────────────────────────────────────

  group('EnforcementMode.fromModeRefId', () {
    test('null → disciplined (default)', () {
      expect(EnforcementMode.fromModeRefId(null), EnforcementMode.disciplined);
    });

    test('"flexible" → flexible', () {
      expect(EnforcementMode.fromModeRefId('flexible'), EnforcementMode.flexible);
    });

    test('"extreme" → extreme', () {
      expect(EnforcementMode.fromModeRefId('extreme'), EnforcementMode.extreme);
    });

    test('"disciplined" → disciplined', () {
      expect(
        EnforcementMode.fromModeRefId('disciplined'),
        EnforcementMode.disciplined,
      );
    });

    test('unknown string → disciplined', () {
      expect(EnforcementMode.fromModeRefId('unknown'), EnforcementMode.disciplined);
    });

    test('case-insensitive: "EXTREME" → extreme', () {
      expect(EnforcementMode.fromModeRefId('EXTREME'), EnforcementMode.extreme);
    });
  });
}
