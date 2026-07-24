import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/application/intention_nudge_cap_policy.dart';
import 'package:sidepal/features/intentions/domain/models/opportunity_slot.dart';

/// P1-06 — daily politeness ceilings for intention nudges
/// (2 per intention per local day, 4 across all intentions).

OpportunitySlot _slot(int slot, DateTime deliverAt) => OpportunitySlot(
  slot: slot,
  deliverAtMs: deliverAt.millisecondsSinceEpoch,
  reasonKind: OpportunityReasonKind.freeWindow,
  reasonText: 'free window',
  body: 'Buy flowers?',
);

final _day = DateTime(2026, 7, 24);

void main() {
  group('applyIntentionDailyCaps', () {
    test('keeps everything under both ceilings', () {
      final slots = [
        _slot(0, _day.add(const Duration(hours: 10))),
        _slot(1, _day.add(const Duration(days: 1, hours: 18))),
      ];
      final allowed = applyIntentionDailyCaps(
        slots: slots,
        intentionCountByDay: const {},
        globalCountByDay: const {},
      );
      expect(allowed, hasLength(2));
    });

    test('caps an intention at 2 per day even within one ladder', () {
      final slots = [
        _slot(0, _day.add(const Duration(hours: 10))),
        _slot(1, _day.add(const Duration(hours: 14))),
        _slot(2, _day.add(const Duration(hours: 18))),
      ];
      final allowed = applyIntentionDailyCaps(
        slots: slots,
        intentionCountByDay: const {},
        globalCountByDay: const {},
      );
      expect(allowed, hasLength(2));
      expect(allowed.map((s) => s.slot), [0, 1]);
    });

    test('existing same-day claims count against the per-intention cap', () {
      final slots = [
        _slot(0, _day.add(const Duration(hours: 14))),
        _slot(1, _day.add(const Duration(hours: 18))),
      ];
      final allowed = applyIntentionDailyCaps(
        slots: slots,
        // One nudge already reached the user this morning.
        intentionCountByDay: const {'2026-07-24': 1},
        globalCountByDay: const {'2026-07-24': 1},
      );
      expect(allowed, hasLength(1));
    });

    test('the global 4/day ceiling holds across intentions', () {
      final slots = [
        _slot(0, _day.add(const Duration(hours: 10))),
        _slot(1, _day.add(const Duration(hours: 15))),
      ];
      final allowed = applyIntentionDailyCaps(
        slots: slots,
        intentionCountByDay: const {},
        // Other intentions already claimed all four of today's nudges.
        globalCountByDay: const {'2026-07-24': 4},
      );
      expect(allowed, isEmpty);
    });

    test('a capped-out day does not block slots on other days', () {
      final slots = [
        _slot(0, _day.add(const Duration(hours: 10))),
        _slot(1, _day.add(const Duration(days: 1, hours: 10))),
      ];
      final allowed = applyIntentionDailyCaps(
        slots: slots,
        intentionCountByDay: const {'2026-07-24': 2},
        globalCountByDay: const {'2026-07-24': 4},
      );
      expect(allowed, hasLength(1));
      expect(allowed.single.slot, 1);
    });

    test('does not mutate the caller-provided count maps', () {
      final own = <String, int>{'2026-07-24': 1};
      final global = <String, int>{'2026-07-24': 1};
      applyIntentionDailyCaps(
        slots: [_slot(0, _day.add(const Duration(hours: 10)))],
        intentionCountByDay: own,
        globalCountByDay: global,
      );
      expect(own, {'2026-07-24': 1});
      expect(global, {'2026-07-24': 1});
    });
  });
}
