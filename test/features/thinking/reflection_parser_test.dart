import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/thinking/application/reflection_parser.dart';

/// Phase 7 — ReflectionParser. The reflection's output is never an
/// action: everything must survive grounding-or-drop, caps and shape
/// validation, or it silently disappears.

const _knownIds = {'memfact_1', 'person_1', 'intention_1', 'intention_2'};
const _openIds = {'intention_1', 'intention_2'};

ParsedReflection _parse(
  Map<String, dynamic> payload, {
  Set<String> knownIds = _knownIds,
  Set<String> openIntentionIds = _openIds,
  Set<String> existingTitleKeys = const {},
}) {
  return ReflectionParser.parse(
    jsonEncode(payload),
    knownIds: knownIds,
    openIntentionIds: openIntentionIds,
    existingTitleKeys: existingTitleKeys,
  );
}

void main() {
  group('decode', () {
    test('malformed JSON yields an empty reflection, never a throw', () {
      final parsed = ReflectionParser.parse(
        'not json at all',
        knownIds: _knownIds,
        openIntentionIds: _openIds,
        existingTitleKeys: const {},
      );
      expect(parsed.isEmpty, isTrue);
    });

    test('code-fenced JSON is unwrapped', () {
      final parsed = ReflectionParser.parse(
        '```json\n${jsonEncode({
          'dormantIntentions': [
            {
              'title': 'Get back into climbing',
              'basedOn': ['memfact_1'],
            },
          ],
        })}\n```',
        knownIds: _knownIds,
        openIntentionIds: _openIds,
        existingTitleKeys: const {},
      );
      expect(parsed.dormantIntentions, hasLength(1));
    });
  });

  group('dormant intentions', () {
    test('grounding-or-drop: unknown basedOn id drops the whole proposal',
        () {
      final parsed = _parse({
        'dormantIntentions': [
          {
            'title': 'Get back into climbing',
            'basedOn': ['memfact_1', 'invented_id'],
          },
        ],
      });
      expect(parsed.dormantIntentions, isEmpty);
    });

    test('empty basedOn drops the proposal — connect OUR dots only', () {
      final parsed = _parse({
        'dormantIntentions': [
          {'title': 'Get back into climbing', 'basedOn': <String>[]},
        ],
      });
      expect(parsed.dormantIntentions, isEmpty);
    });

    test('valid proposal survives with clamped minutes', () {
      final parsed = _parse({
        'dormantIntentions': [
          {
            'title': 'Get back into climbing',
            'estimatedMinutes': 500,
            'basedOn': ['memfact_1'],
          },
        ],
      });
      final candidate = parsed.dormantIntentions.single;
      expect(candidate.title, 'Get back into climbing');
      expect(candidate.estimatedMinutes, 120); // clamped
      expect(candidate.basedOn, ['memfact_1']);
    });

    test('dedupes against existing intention titles and within batch', () {
      final parsed = _parse(
        {
          'dormantIntentions': [
            {
              'title': 'Call Mom!',
              'basedOn': ['person_1'],
            },
            {
              'title': 'call mom',
              'basedOn': ['person_1'],
            },
            {
              'title': 'Water the plants',
              'basedOn': ['memfact_1'],
            },
          ],
        },
        existingTitleKeys: {'water the plants'},
      );
      expect(parsed.dormantIntentions, hasLength(1));
      expect(parsed.dormantIntentions.single.title, 'Call Mom!');
    });

    test('caps at 3', () {
      final parsed = _parse({
        'dormantIntentions': [
          for (var i = 0; i < 6; i++)
            {
              'title': 'Standing wish number $i',
              'basedOn': ['memfact_1'],
            },
        ],
      });
      expect(parsed.dormantIntentions, hasLength(3));
    });
  });

  group('hint updates', () {
    test('only open intention ids and known time blocks survive', () {
      final parsed = _parse({
        'hintUpdates': [
          {'intentionId': 'intention_1', 'preferredTimeBlock': 'evening'},
          {'intentionId': 'memfact_1', 'preferredTimeBlock': 'morning'},
          {'intentionId': 'intention_2', 'preferredTimeBlock': 'midnight'},
        ],
      });
      final hint = parsed.hintUpdates.single;
      expect(hint.intentionId, 'intention_1');
      expect(hint.preferredTimeBlock, 'evening');
    });

    test('one hint per intention — the first wins', () {
      final parsed = _parse({
        'hintUpdates': [
          {'intentionId': 'intention_1', 'preferredTimeBlock': 'evening'},
          {'intentionId': 'intention_1', 'preferredTimeBlock': 'morning'},
        ],
      });
      expect(parsed.hintUpdates, hasLength(1));
      expect(parsed.hintUpdates.single.preferredTimeBlock, 'evening');
    });
  });

  group('observations', () {
    test('at most ONE observation survives — quiet-app principle', () {
      final parsed = _parse({
        'observations': [
          {
            'message': 'Looks like calling Sara keeps slipping to weekends.',
            'basedOn': ['intention_1'],
          },
          {
            'message': 'You might be avoiding the tax paperwork.',
            'basedOn': ['intention_2'],
          },
        ],
      });
      expect(parsed.observation, isNotNull);
      expect(parsed.observation!.message, contains('Sara'));
    });

    test('ungrounded or out-of-bounds messages drop', () {
      final parsed = _parse({
        'observations': [
          {'message': 'too short', 'basedOn': <String>['memfact_1']},
          {
            'message': 'This one has no grounding at all, sadly for it.',
            'basedOn': <String>[],
          },
        ],
      });
      expect(parsed.observation, isNull);
    });

    test('a later valid observation is picked over earlier invalid ones',
        () {
      final parsed = _parse({
        'observations': [
          {'message': 'nope', 'basedOn': <String>['memfact_1']},
          {
            'message': 'You might be putting off the dentist visit.',
            'basedOn': ['intention_2'],
          },
        ],
      });
      expect(parsed.observation, isNotNull);
      expect(parsed.observation!.message, contains('dentist'));
    });
  });
}
