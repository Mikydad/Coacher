import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/memory/application/memory_extraction_parser.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';

const transcript = '''
User: I need to get back into running. My sister Sarah keeps telling me to.
Assistant: That sounds great — mornings or evenings?
User: I prefer morning workouts, honestly.
''';

void main() {
  group('quote verification (the load-bearing gate)', () {
    test('verbatim quote → userStated with the quote kept', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"preference","content":"Prefers morning workouts",'
        '"quote":"I prefer morning workouts, honestly."}],'
        '"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.facts.single.provenance, MemoryProvenance.userStated);
      expect(parsed.facts.single.sourceQuote, isNotNull);
    });

    test('quote survives whitespace and smart-quote drift', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"preference","content":"Prefers morning workouts",'
        '"quote":"I  prefer MORNING workouts,\\u2019 honestly."}],'
        '"people":[],"observations":[],"summary":null}',
        "User: I prefer morning workouts,' honestly.",
      );
      expect(parsed.facts.single.provenance, MemoryProvenance.userStated);
    });

    test('fabricated quote → demoted to aiInferred, quote dropped', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"semanticFact","content":"Has a dog named Rex",'
        '"quote":"my dog Rex loves the park"}],'
        '"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.facts.single.provenance, MemoryProvenance.aiInferred);
      expect(parsed.facts.single.sourceQuote, isNull);
    });

    test('no quote at all → aiInferred', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"learnedPattern","content":"Avoids evening plans",'
        '"quote":null}],"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.facts.single.provenance, MemoryProvenance.aiInferred);
    });

    test('people get the same verification', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[],"people":['
        '{"name":"Sarah","relationship":"sister","aliases":["my sister"],'
        '"quote":"My sister Sarah keeps telling me to."},'
        '{"name":"Bob","relationship":"friend","quote":"my friend Bob"}],'
        '"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.people[0].provenance, MemoryProvenance.userStated);
      expect(parsed.people[1].provenance, MemoryProvenance.aiInferred);
    });
  });

  group('robustness', () {
    test('malformed JSON degrades to an empty extraction', () {
      expect(MemoryExtractionParser.parse('not json', transcript).isEmpty, isTrue);
      expect(MemoryExtractionParser.parse('[]', transcript).isEmpty, isTrue);
      expect(MemoryExtractionParser.parse('', transcript).isEmpty, isTrue);
    });

    test('caps: max 8 facts, 5 people, 3 observations', () {
      final facts = List.generate(
        20,
        (i) => '{"kind":"semanticFact","content":"Fact $i","quote":null}',
      ).join(',');
      final people = List.generate(
        10,
        (i) => '{"name":"P$i","quote":null}',
      ).join(',');
      final observations = List.generate(
        6,
        (i) => '{"title":"Obs $i"}',
      ).join(',');
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[$facts],"people":[$people],'
        '"observations":[$observations],"summary":null}',
        transcript,
      );
      expect(parsed.facts, hasLength(8));
      expect(parsed.people, hasLength(5));
      expect(parsed.observations, hasLength(3));
    });

    test('model cannot smuggle an episodicSummary in as a fact', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"episodicSummary","content":"We talked",'
        '"quote":null}],"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.facts.single.kind, MemoryFactKind.semanticFact);
    });

    test('content over 200 chars is truncated', () {
      final long = 'x' * 300;
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"semanticFact","content":"$long","quote":null}],'
        '"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(parsed.facts.single.content.length, 200);
    });

    test('observation minutes are clamped to a sane range', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[],"people":[],"observations":['
        '{"title":"Reconnect with college friends","estimatedMinutes":10000},'
        '{"title":"Quick one","estimatedMinutes":1}],"summary":null}',
        transcript,
      );
      expect(parsed.observations[0].estimatedMinutes, 240);
      expect(parsed.observations[1].estimatedMinutes, 5);
    });

    test('structured hints are re-encoded as JSON strings', () {
      final parsed = MemoryExtractionParser.parse(
        '{"facts":[{"kind":"preference","content":"Morning person",'
        '"quote":null,"structured":{"preferredTimeBlock":"morning"}}],'
        '"people":[],"observations":[],"summary":null}',
        transcript,
      );
      expect(
        parsed.facts.single.structuredJson,
        '{"preferredTimeBlock":"morning"}',
      );
    });
  });
}
