import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';
import 'package:sidepal/features/intentions/domain/models/intention_projection.dart';
import 'package:sidepal/features/intentions/domain/models/opportunity_slot.dart';

Intention makeIntention({int? windowEndMs}) {
  final now = DateTime(2026, 7, 24, 9);
  return Intention(
    id: 'intention_proj',
    title: 'Send the photos',
    rawUtterance: 'send the photos this week',
    windowStartMs: now.millisecondsSinceEpoch,
    windowEndMs: windowEndMs ?? DateTime(2026, 7, 27, 21).millisecondsSinceEpoch,
    estimatedMinutes: 10,
    activityTags: const ['message'],
    createdAtMs: now.millisecondsSinceEpoch,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

OpportunitySlot slotAt(int slot, DateTime at) => OpportunitySlot(
  slot: slot,
  deliverAtMs: at.millisecondsSinceEpoch,
  reasonKind: OpportunityReasonKind.freeWindow,
  reasonText: 'free',
  body: 'body',
);

void main() {
  final nowMs = DateTime(2026, 7, 24, 12).millisecondsSinceEpoch;

  group('IntentionProjection.fromPlan', () {
    test('covered with the earliest FUTURE slot as nextSlotMs', () {
      final p = IntentionProjection.fromPlan(
        intention: makeIntention(),
        slots: [
          slotAt(1, DateTime(2026, 7, 26, 20)),
          slotAt(0, DateTime(2026, 7, 24, 15)),
        ],
        nowMs: nowMs,
      );
      expect(p.covered, isTrue);
      expect(p.nextSlotMs, DateTime(2026, 7, 24, 15).millisecondsSinceEpoch);
    });

    test('a fired (past) slot never masks coverage', () {
      final p = IntentionProjection.fromPlan(
        intention: makeIntention(),
        slots: [slotAt(0, DateTime(2026, 7, 24, 9))], // already past 12:00
        nowMs: nowMs,
      );
      expect(p.covered, isFalse);
      expect(p.nextSlotMs, isNull);
    });

    test('no slots → uncovered', () {
      final p = IntentionProjection.fromPlan(
        intention: makeIntention(),
        slots: const [],
        nowMs: nowMs,
      );
      expect(p.covered, isFalse);
      expect(p.nextSlotMs, isNull);
    });

    test('mirrors the deadline for the sweep', () {
      final end = DateTime(2026, 7, 27, 21).millisecondsSinceEpoch;
      final p = IntentionProjection.fromPlan(
        intention: makeIntention(windowEndMs: end),
        slots: [slotAt(0, DateTime(2026, 7, 25, 10))],
        nowMs: nowMs,
      );
      expect(p.windowEndMs, end);
      expect(p.toMap()['covered'], isTrue);
      expect(p.toMap()['intentionId'], 'intention_proj');
    });
  });

  group('signature (compare-before-write)', () {
    IntentionProjection proj({required bool covered, int? next, int updated = 0}) =>
        IntentionProjection(
          intentionId: 'x',
          covered: covered,
          nextSlotMs: next,
          windowEndMs: 999,
          updatedAtMs: updated,
        );

    test('ignores updatedAtMs — a re-stamp is not a material change', () {
      final a = proj(covered: true, next: 1000, updated: 1);
      final b = proj(covered: true, next: 1000, updated: 2);
      expect(a.signature, b.signature);
    });

    test('ignores windowEndMs — that flows through the intention doc', () {
      final a = IntentionProjection(
        intentionId: 'x',
        covered: true,
        nextSlotMs: 1000,
        windowEndMs: 1,
        updatedAtMs: 0,
      );
      final b = IntentionProjection(
        intentionId: 'x',
        covered: true,
        nextSlotMs: 1000,
        windowEndMs: 2,
        updatedAtMs: 0,
      );
      expect(a.signature, b.signature);
    });

    test('changes when coverage or the next slot moves', () {
      expect(
        proj(covered: true, next: 1000).signature,
        isNot(proj(covered: false, next: null).signature),
      );
      expect(
        proj(covered: true, next: 1000).signature,
        isNot(proj(covered: true, next: 2000).signature),
      );
    });
  });
}
