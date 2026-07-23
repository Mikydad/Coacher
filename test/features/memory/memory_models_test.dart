import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';
import 'package:sidepal/features/memory/domain/models/person.dart';

void main() {
  group('MemoryFact', () {
    MemoryFact make() => const MemoryFact(
      id: 'memfact_test',
      kind: MemoryFactKind.preference,
      content: 'Prefers morning workouts',
      structuredJson: '{"preferredTimeBlock":"morning"}',
      personId: 'person_1',
      provenance: MemoryProvenance.userStated,
      confidence: 0.95,
      sourceQuote: 'I prefer morning workouts',
      sourceSessionId: 'session_1',
      contradictionCount: 1,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );

    test('toMap/fromMap round-trips every field', () {
      final restored = MemoryFact.fromMap(make().toMap());
      expect(restored.toMap(), make().toMap());
    });

    test('validate rejects blank and over-long content', () {
      expect(() => make().validate(), returnsNormally);
      expect(
        () => MemoryFact.fromMap(
          make().toMap()..['content'] = 'x' * 201,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => MemoryFact.fromMap(make().toMap()..['content'] = '').validate(),
        throwsArgumentError,
      );
    });

    test('unknown provenance falls back to the WEAKEST class', () {
      expect(
        memoryProvenanceFromStorage('garbage'),
        MemoryProvenance.aiInferred,
      );
      expect(memoryProvenanceFromStorage(null), MemoryProvenance.aiInferred);
    });

    test('only userStated/userConfirmed may be asserted', () {
      expect(make().isAsserted, isTrue);
      expect(
        make().copyWith(provenance: MemoryProvenance.aiInferred).isAsserted,
        isFalse,
      );
      expect(
        make()
            .copyWith(provenance: MemoryProvenance.derivedDeterministic)
            .isAsserted,
        isFalse,
      );
    });
  });

  group('Person', () {
    Person make() => const Person(
      id: 'person_test',
      displayName: 'Sarah',
      relationship: 'sister',
      kind: PersonKind.family,
      aliases: ['my sister', 'Sar'],
      provenance: MemoryProvenance.userStated,
      lastInteractionAtMs: 5000,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );

    test('toMap/fromMap round-trips every field', () {
      final restored = Person.fromMap(make().toMap());
      expect(restored.toMap(), make().toMap());
    });

    test('matchesReference sees name and aliases, case-insensitive', () {
      expect(make().matchesReference('call sarah tomorrow'), isTrue);
      expect(make().matchesReference('visit MY SISTER'), isTrue);
      expect(make().matchesReference('call mom'), isFalse);
    });
  });

  group('normalizeRelationship', () {
    test('family words normalize to family', () {
      expect(normalizeRelationship('sister'), PersonKind.family);
      expect(normalizeRelationship('my cousin'), PersonKind.family);
      expect(normalizeRelationship('Mom'), PersonKind.family);
    });

    test('partner, work and community words normalize', () {
      expect(normalizeRelationship('wife'), PersonKind.partner);
      expect(normalizeRelationship('cofounder'), PersonKind.work);
      expect(normalizeRelationship('neighbor'), PersonKind.community);
    });

    test('friend variants and unknowns', () {
      expect(normalizeRelationship('best friend'), PersonKind.friend);
      expect(normalizeRelationship('acquaintance'), PersonKind.other);
      expect(normalizeRelationship(null), PersonKind.other);
    });
  });
}
