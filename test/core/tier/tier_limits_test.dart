import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/tier/tier_limits.dart';

void main() {
  group('TierLimits.defaults', () {
    test('enforcement ships OFF', () {
      expect(TierLimits.defaults.enforced, isFalse);
    });

    test('launch values match the PRD tier matrix', () {
      const d = TierLimits.defaults;
      expect(d.freeTasksPerDay, 5);
      expect(d.freeGoals, 5);
      expect(d.freeHabitAnchorsPerDay, 5);
      expect(d.freeReminders, 5);
      expect(d.freeAiInstructionsPerDay, 5);
      expect(d.freePhotoStakesPerMonth, 3);
      expect(d.freeCircles, 1);
      expect(d.proCircles, -1);
      expect(d.freeCircleMaxMembers, 5);
      expect(d.proCircleMaxMembers, 8);
      expect(d.mercyVetoFreePerMonth, 1);
      expect(d.mercyVetoProPerMonth, 3);
      expect(d.challengeFeeMinCents, 200);
      expect(d.challengeFeePercent, 7);
    });
  });

  group('TierLimits.parse', () {
    test('null, empty, and whitespace resolve to defaults', () {
      expect(TierLimits.parse(null).freeGoals, 5);
      expect(TierLimits.parse('').freeGoals, 5);
      expect(TierLimits.parse('   ').freeGoals, 5);
    });

    test('garbage resolves to defaults, never throws', () {
      expect(TierLimits.parse('not json').enforced, isFalse);
      expect(TierLimits.parse('[1,2,3]').freeGoals, 5);
      expect(TierLimits.parse('42').freeGoals, 5);
    });

    test('partial JSON overrides named fields, keeps defaults for the rest', () {
      final limits = TierLimits.parse('{"freeGoals": 10, "enforced": true}');
      expect(limits.freeGoals, 10);
      expect(limits.enforced, isTrue);
      expect(limits.freeTasksPerDay, 5);
      expect(limits.freePhotoStakesPerMonth, 3);
    });

    test('mistyped field falls back to its default', () {
      final limits = TierLimits.parse('{"freeGoals": "ten", "enforced": 1}');
      expect(limits.freeGoals, 5);
      expect(limits.enforced, isFalse);
    });

    test('toJson round-trips through parse', () {
      const original = TierLimits.defaults;
      final roundTripped = TierLimits.parse(jsonEncode(original.toJson()));
      expect(roundTripped.toJson(), original.toJson());
    });
  });
}
