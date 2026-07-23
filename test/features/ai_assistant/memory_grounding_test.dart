import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/presentation/widgets/chat_bubbles.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';
import 'package:sidepal/features/memory/domain/models/person.dart';

MemoryFact _fact({
  String id = 'memfact_1',
  MemoryProvenance provenance = MemoryProvenance.userStated,
  String content = 'Has a sister named Sarah',
}) {
  return MemoryFact(
    id: id,
    kind: MemoryFactKind.semanticFact,
    content: content,
    provenance: provenance,
    createdAtMs: 1000,
    updatedAtMs: 1000,
  );
}

void main() {
  group('extractMemoryReferences (chat renderer side)', () {
    test('strips a bare [mem:id] marker and collects the id', () {
      final result = extractMemoryReferences(
        'Your sister Sarah might like that. [mem:memfact_abc]',
      );
      expect(result.text, 'Your sister Sarah might like that.');
      expect(result.factIds, ['memfact_abc']);
    });

    test('strips markers carrying the |label suffix', () {
      final result = extractMemoryReferences(
        'You prefer mornings. [mem:memfact_x|inferred] Plan accordingly.',
      );
      expect(result.text, 'You prefer mornings. Plan accordingly.');
      expect(result.factIds, ['memfact_x']);
    });

    test('collects multiple ids in order and dedupes repeats', () {
      final result = extractMemoryReferences(
        'A [mem:f1] B [mem:f2] C [mem:f1]',
      );
      expect(result.factIds, ['f1', 'f2']);
      expect(result.text, 'A B C');
    });

    test('plain text passes through untouched', () {
      final result = extractMemoryReferences('No memory used here.');
      expect(result.text, 'No memory used here.');
      expect(result.factIds, isEmpty);
    });
  });

  group('AiPayloadAssembler memory line rendering', () {
    test('stated/confirmed facts render the "stated" label', () {
      expect(
        AiPayloadAssembler.renderMemoryFactLine(_fact()),
        '[mem:memfact_1|stated] Has a sister named Sarah',
      );
      expect(
        AiPayloadAssembler.renderMemoryFactLine(
          _fact(provenance: MemoryProvenance.userConfirmed),
        ),
        contains('|stated]'),
      );
    });

    test('inferred and observed labels are distinct', () {
      expect(
        AiPayloadAssembler.renderMemoryFactLine(
          _fact(provenance: MemoryProvenance.aiInferred),
        ),
        contains('|inferred]'),
      );
      expect(
        AiPayloadAssembler.renderMemoryFactLine(
          _fact(provenance: MemoryProvenance.derivedDeterministic),
        ),
        contains('|observed]'),
      );
    });

    test('a rendered fact line round-trips through the marker parser', () {
      final line = AiPayloadAssembler.renderMemoryFactLine(_fact());
      final result = extractMemoryReferences(line);
      expect(result.factIds, ['memfact_1']);
      expect(result.text, 'Has a sister named Sarah');
    });

    test('person line includes relationship and interaction recency', () {
      final person = Person(
        id: 'person_1',
        displayName: 'Sarah',
        relationship: 'my sister',
        kind: PersonKind.family,
        provenance: MemoryProvenance.userStated,
        lastInteractionAtMs: DateTime.now()
            .subtract(const Duration(days: 12))
            .millisecondsSinceEpoch,
        createdAtMs: 1000,
        updatedAtMs: 1000,
      );
      final line = AiPayloadAssembler.renderPersonLine(person);
      expect(line, contains('Sarah (my sister)'));
      expect(line, contains('12 days ago'));
    });

    test('person line without interaction stays silent about recency', () {
      final person = Person(
        id: 'person_2',
        displayName: 'Ben',
        kind: PersonKind.friend,
        provenance: MemoryProvenance.aiInferred,
        createdAtMs: 1000,
        updatedAtMs: 1000,
      );
      final line = AiPayloadAssembler.renderPersonLine(person);
      expect(line, 'Ben (friend)');
    });
  });
}
