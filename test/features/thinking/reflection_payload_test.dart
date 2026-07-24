import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';
import 'package:sidepal/features/memory/domain/models/person.dart';
import 'package:sidepal/features/thinking/application/reflection_parser.dart';
import 'package:sidepal/features/thinking/application/reflection_payload.dart';
import 'package:sidepal/features/thinking/application/thinking_loop_service.dart';

/// Phase 7 — reflection snapshot assembly + the durable-inputs hash that
/// gates re-reflection ("fresh inputs" semantics).

final _now = DateTime(2026, 7, 24, 10);

MemoryFact _fact(String id, {int updatedAtMs = 1000}) => MemoryFact(
  id: id,
  kind: MemoryFactKind.semanticFact,
  content: 'Prefers mornings',
  provenance: MemoryProvenance.userStated,
  confidence: 1.0,
  createdAtMs: 1000,
  updatedAtMs: updatedAtMs,
);

Person _person(String id, {int? lastInteractionAtMs}) => Person(
  id: id,
  displayName: 'Sarah',
  relationship: 'sister',
  kind: PersonKind.family,
  provenance: MemoryProvenance.userStated,
  lastInteractionAtMs: lastInteractionAtMs,
  createdAtMs: 1000,
  updatedAtMs: 1000,
);

Intention _intention(
  String id, {
  IntentionStatus status = IntentionStatus.open,
  int? windowEndMs,
  int updatedAtMs = 1000,
  int nudgeCount = 0,
  int snoozeCount = 0,
  bool active = true,
}) => Intention(
  id: id,
  title: 'Call cousin Sara',
  rawUtterance: 'call my cousin',
  windowStartMs: 500,
  windowEndMs: windowEndMs ?? _now.add(const Duration(days: 2)).millisecondsSinceEpoch,
  estimatedMinutes: 15,
  status: status,
  nudgeCount: nudgeCount,
  snoozeCount: snoozeCount,
  active: active,
  createdAtMs: 500,
  updatedAtMs: updatedAtMs,
);

void main() {
  group('buildReflectionSnapshot', () {
    test('carries facts, people and intentions with their ids', () {
      final snapshot = buildReflectionSnapshot(
        facts: [_fact('memfact_1')],
        people: [
          _person(
            'person_1',
            lastInteractionAtMs:
                _now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          ),
        ],
        intentions: [_intention('intention_1', snoozeCount: 3)],
        now: _now,
      );
      expect(snapshot['today'], '2026-07-24');
      expect((snapshot['facts'] as List).single, containsPair('id', 'memfact_1'));
      final person = (snapshot['people'] as List).single as Map;
      expect(person['lastInteractionDaysAgo'], 10);
      final intention = (snapshot['intentions'] as List).single as Map;
      expect(intention['snoozeCount'], 3);
      expect(intention['windowEndsInDays'], 2);
    });

    test('done/dismissed/inactive intentions are excluded; recently expired '
        'stay as avoidance evidence', () {
      final expiredRecently = _intention(
        'expired_recent',
        status: IntentionStatus.expired,
        windowEndMs:
            _now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      );
      final expiredLongAgo = _intention(
        'expired_old',
        status: IntentionStatus.expired,
        windowEndMs:
            _now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      );
      final snapshot = buildReflectionSnapshot(
        facts: const [],
        people: const [],
        intentions: [
          _intention('open_1'),
          _intention('done_1', status: IntentionStatus.done),
          _intention('dismissed_1', status: IntentionStatus.dismissed),
          _intention('inactive_1', active: false),
          expiredRecently,
          expiredLongAgo,
        ],
        now: _now,
      );
      final ids = [
        for (final i in snapshot['intentions'] as List) (i as Map)['id'],
      ];
      expect(ids, containsAll(['open_1', 'expired_recent']));
      expect(ids, isNot(contains('done_1')));
      expect(ids, isNot(contains('dismissed_1')));
      expect(ids, isNot(contains('inactive_1')));
      expect(ids, isNot(contains('expired_old')));
    });

    test('caps are enforced', () {
      final snapshot = buildReflectionSnapshot(
        facts: [for (var i = 0; i < 50; i++) _fact('memfact_$i')],
        people: const [],
        intentions: const [],
        now: _now,
      );
      expect(snapshot['facts'] as List, hasLength(kReflectionMaxFacts));
    });
  });

  group('reflectionInputsHash', () {
    test('is stable across ordering and day changes', () {
      final a = reflectionInputsHash(
        facts: [_fact('memfact_1'), _fact('memfact_2')],
        people: [_person('person_1')],
        intentions: [_intention('intention_1')],
      );
      final b = reflectionInputsHash(
        facts: [_fact('memfact_2'), _fact('memfact_1')],
        people: [_person('person_1')],
        intentions: [_intention('intention_1')],
      );
      expect(a, b);
    });

    test('changes when an intention status or avoidance count changes', () {
      final base = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: [_intention('intention_1')],
      );
      final snoozed = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: [_intention('intention_1', snoozeCount: 1)],
      );
      final done = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: [_intention('intention_1', status: IntentionStatus.done)],
      );
      expect(base, isNot(snoozed));
      expect(base, isNot(done));
      expect(snoozed, isNot(done));
    });

    test('changes when a fact is updated', () {
      final before = reflectionInputsHash(
        facts: [_fact('memfact_1', updatedAtMs: 1000)],
        people: const [],
        intentions: const [],
      );
      final after = reflectionInputsHash(
        facts: [_fact('memfact_1', updatedAtMs: 2000)],
        people: const [],
        intentions: const [],
      );
      expect(before, isNot(after));
    });
  });

  group('ThinkingLoopService.mergeHints', () {
    test('merges into existing hints without dropping other keys', () {
      final merged = ThinkingLoopService.mergeHints(
        '{"source":"reflect","other":1}',
        const ReflectionHintUpdate(
          intentionId: 'intention_1',
          preferredTimeBlock: 'evening',
        ),
      );
      expect(merged, contains('"preferredTimeBlock":"evening"'));
      expect(merged, contains('"other":1'));
      expect(merged, contains('"hintSource":"reflect"'));
    });

    test('malformed existing JSON is replaced, never a throw', () {
      final merged = ThinkingLoopService.mergeHints(
        'not json',
        const ReflectionHintUpdate(
          intentionId: 'intention_1',
          preferredTimeBlock: 'morning',
        ),
      );
      expect(merged, contains('"preferredTimeBlock":"morning"'));
    });
  });
}
