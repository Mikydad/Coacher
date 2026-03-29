import 'package:coach_for_life/features/planning/application/routine_mode_policy_resolver.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutineModePolicyResolver', () {
    const resolver = RoutineModePolicyResolver();

    test('high-priority disciplined task tightens timer and snooze policy', () {
      final disciplined = RoutineModeConfig.defaults().firstWhere(
        (m) => m.baseMode == RoutineMode.disciplined,
      );

      final result = resolver.resolve(
        config: disciplined,
        taskPriority: 1,
        urgencyScore: 40,
        strictTaskRequired: false,
      );

      expect(result.requireTimerForCompletion, isTrue);
      expect(result.baseSnoozeMinutes, lessThanOrEqualTo(10));
      expect(result.maxExtensionMinutes, lessThanOrEqualTo(45));
      expect(result.requireReasonForDeferral, isTrue);
    });

    test('urgent flexible task still tightens to short snooze', () {
      final flexible = RoutineModeConfig.defaults().firstWhere(
        (m) => m.baseMode == RoutineMode.flexible,
      );

      final result = resolver.resolve(
        config: flexible,
        taskPriority: 3,
        urgencyScore: 90,
      );

      expect(result.requireTimerForCompletion, isTrue);
      expect(result.baseSnoozeMinutes, 5);
      expect(result.maxExtensionMinutes, lessThanOrEqualTo(60));
    });

    test('strict task required enforces timer regardless of low urgency', () {
      final flexible = RoutineModeConfig.defaults().firstWhere(
        (m) => m.baseMode == RoutineMode.flexible,
      );

      final result = resolver.resolve(
        config: flexible,
        taskPriority: 5,
        urgencyScore: 10,
        strictTaskRequired: true,
      );

      expect(result.requireTimerForCompletion, isTrue);
      expect(result.requireReasonForDeferral, isTrue);
    });
  });
}
