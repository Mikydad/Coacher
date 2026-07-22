import 'package:sidepal/features/time_blocks/application/conflict_detection_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConflictDetectionEngine.importanceFromGoalIntensity', () {
    test('intensity 1 → 30', () {
      expect(ConflictDetectionEngine.importanceFromGoalIntensity(1), 30);
    });

    test('intensity 2 → 30', () {
      expect(ConflictDetectionEngine.importanceFromGoalIntensity(2), 30);
    });

    test('intensity 3 → 60', () {
      expect(ConflictDetectionEngine.importanceFromGoalIntensity(3), 60);
    });

    test('intensity 4 → 90', () {
      expect(ConflictDetectionEngine.importanceFromGoalIntensity(4), 90);
    });

    test('intensity 5 → 90', () {
      expect(ConflictDetectionEngine.importanceFromGoalIntensity(5), 90);
    });

    test('mirrors existing modeRefId scale: disciplined(60) == intensity3(60)', () {
      expect(
        ConflictDetectionEngine.importanceFromGoalIntensity(3),
        ConflictDetectionEngine.importanceFromModeRefId('disciplined'),
      );
    });

    test('mirrors existing modeRefId scale: extreme(90) == intensity5(90)', () {
      expect(
        ConflictDetectionEngine.importanceFromGoalIntensity(5),
        ConflictDetectionEngine.importanceFromModeRefId('extreme'),
      );
    });
  });
}
