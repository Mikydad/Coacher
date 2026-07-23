import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/scheduling/free_window_calculator.dart';
import 'package:sidepal/features/intentions/application/opportunity_planner.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';
import 'package:sidepal/features/intentions/domain/models/opportunity_slot.dart';

Intention makeIntention({
  int? windowStartMs,
  int? windowEndMs,
  int estimatedMinutes = 15,
  List<String> activityTags = const ['call'],
  int? pinnedAtMs,
  String? aiHintsJson,
}) {
  final now = DateTime(2026, 7, 20, 9); // Monday 09:00
  return Intention(
    id: 'intention_test',
    title: 'Call cousin Sara',
    rawUtterance: 'I need to call cousin Sara tomorrow',
    windowStartMs: windowStartMs ?? now.millisecondsSinceEpoch,
    windowEndMs:
        windowEndMs ?? DateTime(2026, 7, 21, 21).millisecondsSinceEpoch,
    estimatedMinutes: estimatedMinutes,
    activityTags: activityTags,
    pinnedAtMs: pinnedAtMs,
    aiHintsJson: aiHintsJson,
    createdAtMs: now.millisecondsSinceEpoch,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

void main() {
  final now = DateTime(2026, 7, 20, 9); // Monday 09:00

  group('OpportunityPlanner.plan', () {
    test('pinned intention gets exactly one slot at the pinned time', () {
      final pinned = DateTime(2026, 7, 20, 18).millisecondsSinceEpoch;
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(pinnedAtMs: pinned),
        now: now,
        freeWindowsByDateKey: const {},
      );
      expect(slots, hasLength(1));
      expect(slots.single.deliverAtMs, pinned);
      expect(slots.single.reasonKind, OpportunityReasonKind.pinned);
    });

    test('pinned time already past yields no slots', () {
      final pinned = DateTime(2026, 7, 20, 8).millisecondsSinceEpoch;
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(pinnedAtMs: pinned),
        now: now,
        freeWindowsByDateKey: const {},
      );
      expect(slots, isEmpty);
    });

    test('primary slot lands in a free window, safety near the deadline', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(
              startMinute: 14 * 60,
              endMinute: 16 * 60,
              beforeTitle: 'Dinner prep',
            ),
          ],
        },
      );
      expect(slots.first.slot, 0);
      expect(
        slots.first.deliverAtMs,
        DateTime(2026, 7, 20, 14).millisecondsSinceEpoch,
      );
      expect(slots.first.reasonKind, OpportunityReasonKind.freeWindow);
      // Safety slot ~2h before the Tuesday 21:00 deadline.
      final safety = slots.firstWhere((s) => s.slot == 1);
      expect(safety.reasonKind, OpportunityReasonKind.deadlinePressure);
      expect(
        safety.deliverAtMs,
        DateTime(2026, 7, 21, 19).millisecondsSinceEpoch,
      );
    });

    test('no free windows falls back to a single deadline-eve slot', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        freeWindowsByDateKey: const {},
      );
      expect(slots, hasLength(1));
      expect(slots.single.reasonKind, OpportunityReasonKind.deadlinePressure);
      expect(
        slots.single.deliverAtMs,
        DateTime(2026, 7, 21, 19).millisecondsSinceEpoch,
      );
    });

    test('quiet hours push the primary to a responsive window', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        // Two same-size windows; 14:00 is a quiet hour.
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
            FreeWindow(startMinute: 17 * 60, endMinute: 18 * 60),
          ],
        },
        quietHours: {14},
      );
      expect(
        slots.first.deliverAtMs,
        DateTime(2026, 7, 20, 17).millisecondsSinceEpoch,
      );
    });

    test('earlier of two otherwise-equal windows wins (no drift)', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
          ],
          '2026-07-21': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
          ],
        },
      );
      expect(
        slots.first.deliverAtMs,
        DateTime(2026, 7, 20, 14).millisecondsSinceEpoch,
      );
    });

    test('AI hint tilts between real candidates but cannot fabricate', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(
          aiHintsJson: '{"preferredTimeBlock":"evening"}',
        ),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            // Morning window slightly earlier (earliness edge) vs evening
            // window backed by the hint — hint weight should win.
            FreeWindow(startMinute: 10 * 60, endMinute: 11 * 60),
            FreeWindow(startMinute: 18 * 60, endMinute: 19 * 60),
          ],
        },
      );
      expect(
        slots.first.deliverAtMs,
        DateTime(2026, 7, 20, 18).millisecondsSinceEpoch,
      );
    });

    test('malformed AI hints never break planning', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(aiHintsJson: 'not json at all {{{'),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
          ],
        },
      );
      expect(slots, isNotEmpty);
    });

    test('slots are spaced at least two hours apart', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
            FreeWindow(startMinute: 15 * 60, endMinute: 16 * 60),
            FreeWindow(startMinute: 18 * 60, endMinute: 19 * 60),
          ],
        },
      );
      for (final a in slots) {
        for (final b in slots) {
          if (a.slot == b.slot) continue;
          expect(
            (a.deliverAtMs - b.deliverAtMs).abs(),
            greaterThanOrEqualTo(const Duration(hours: 2).inMilliseconds),
          );
        }
      }
    });

    test('copy is question-form and lowercases the title mid-sentence', () {
      final slots = OpportunityPlanner.plan(
        intention: makeIntention(),
        now: now,
        freeWindowsByDateKey: const {
          '2026-07-20': [
            FreeWindow(startMinute: 14 * 60, endMinute: 15 * 60),
          ],
        },
      );
      expect(slots.first.body, contains('call cousin Sara'));
      expect(slots.first.body, endsWith('?'));
    });
  });
}
