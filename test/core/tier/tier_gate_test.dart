import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/tier/tier_gate.dart';
import 'package:sidepal/core/tier/tier_limits.dart';

TierLimits _limits({bool enforced = true}) =>
    TierLimits.parse('{"enforced": $enforced}');

void main() {
  group('TierGate bypass', () {
    test('enforcement off allows everything at any count', () {
      final gate = TierGate(
        limits: _limits(enforced: false),
        tier: UserTier.free,
      );
      expect(gate.isBypassed, isTrue);
      expect(gate.canCreateTaskForDay(999), isTrue);
      expect(gate.canCreateGoal(999), isTrue);
      expect(gate.canAddHabitAnchorForDay(999), isTrue);
      expect(gate.canCreateReminder(999), isTrue);
      expect(gate.canCreatePhotoStakeThisMonth(999), isTrue);
    });

    test('Pro allows everything even when enforced', () {
      final gate = TierGate(limits: _limits(), tier: UserTier.pro);
      expect(gate.isBypassed, isTrue);
      expect(gate.canCreateTaskForDay(999), isTrue);
      expect(gate.canCreateGoal(999), isTrue);
    });
  });

  group('TierGate free limits (enforced)', () {
    final gate = TierGate(limits: _limits(), tier: UserTier.free);

    test('allows below the cap, blocks at the cap', () {
      expect(gate.canCreateTaskForDay(4), isTrue);
      expect(gate.canCreateTaskForDay(5), isFalse);
      expect(gate.canCreateGoal(4), isTrue);
      expect(gate.canCreateGoal(5), isFalse);
      expect(gate.canAddHabitAnchorForDay(4), isTrue);
      expect(gate.canAddHabitAnchorForDay(5), isFalse);
      expect(gate.canCreateReminder(4), isTrue);
      expect(gate.canCreateReminder(5), isFalse);
      expect(gate.canCreatePhotoStakeThisMonth(2), isTrue);
      expect(gate.canCreatePhotoStakeThisMonth(3), isFalse);
    });

    test('a negative RC limit means unlimited', () {
      final unlimited = TierGate(
        limits: TierLimits.parse('{"enforced": true, "freeGoals": -1}'),
        tier: UserTier.free,
      );
      expect(unlimited.canCreateGoal(9999), isTrue);
    });
  });

  group('TierGate.maxJoinedCircles', () {
    test('enforcement off keeps the legacy app-wide cap', () {
      final gate = TierGate(
        limits: _limits(enforced: false),
        tier: UserTier.free,
      );
      expect(gate.maxJoinedCircles(legacyLimit: 3), 3);
    });

    test('enforced: free = 1, Pro = unlimited (-1)', () {
      expect(
        TierGate(limits: _limits(), tier: UserTier.free)
            .maxJoinedCircles(legacyLimit: 3),
        1,
      );
      expect(
        TierGate(limits: _limits(), tier: UserTier.pro)
            .maxJoinedCircles(legacyLimit: 3),
        -1,
      );
    });
  });
}
