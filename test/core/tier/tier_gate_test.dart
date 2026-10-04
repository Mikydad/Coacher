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
      expect(gate.canCreateStakeThisMonth(999), isTrue);
      expect(gate.canCreatePromiseThisWeek(999), isTrue);
      expect(gate.canViewTimeInsights, isTrue);
      expect(gate.canExportTimeLog, isTrue);
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

    test('allows below the cap, blocks at the cap (2026-09-27 values)', () {
      expect(gate.canCreateTaskForDay(3), isTrue);
      expect(gate.canCreateTaskForDay(4), isFalse);
      expect(gate.canCreateGoal(2), isTrue);
      expect(gate.canCreateGoal(3), isFalse);
      expect(gate.canAddHabitAnchorForDay(3), isTrue);
      expect(gate.canAddHabitAnchorForDay(4), isFalse);
      expect(gate.canCreateReminder(4), isTrue);
      expect(gate.canCreateReminder(5), isFalse);
      expect(gate.canCreateStakeThisMonth(0), isTrue);
      expect(gate.canCreateStakeThisMonth(1), isFalse);
      expect(gate.canCreatePromiseThisWeek(1), isTrue);
      expect(gate.canCreatePromiseThisWeek(2), isFalse);
    });

    test('time insights and export are Pro; free + enforced is blocked', () {
      expect(gate.canViewTimeInsights, isFalse);
      expect(gate.canExportTimeLog, isFalse);
      final pro = TierGate(limits: _limits(), tier: UserTier.pro);
      expect(pro.canViewTimeInsights, isTrue);
      expect(pro.canExportTimeLog, isTrue);
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

  group('Progress history (Week and beyond) is Pro', () {
    test('free + enforced is blocked', () {
      final gate = TierGate(limits: _limits(), tier: UserTier.free);
      expect(gate.canViewProgressHistory, isFalse);
    });

    test('Pro, or enforcement off, is allowed', () {
      expect(
        TierGate(limits: _limits(), tier: UserTier.pro).canViewProgressHistory,
        isTrue,
      );
      expect(
        TierGate(limits: _limits(enforced: false), tier: UserTier.free)
            .canViewProgressHistory,
        isTrue,
      );
    });
  });
}
