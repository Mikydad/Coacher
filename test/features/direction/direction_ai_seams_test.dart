import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/analytics/domain/models/coaching_ai_payload.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';
import 'package:sidepal/features/thinking/application/reflection_payload.dart';

/// Direction reaches three AI readers (PRD/Direction §8). These tests pin
/// the seams: where the block appears, that it is omitted when empty, and
/// that a previous period never leaks in as current context.

final _now = DateTime(2026, 9, 11, 22);

DirectionEntry _entry(DirectionHorizon h, DateTime at, String text,
        {int? updatedAtMs}) =>
    DirectionEntry.forPeriod(
      DirectionPeriods.current(h, at),
      text: text,
      nowMs: updatedAtMs ?? at.millisecondsSinceEpoch,
    );

String _userPrompt(AiOperatingLayerPayload payload) {
  final messages = buildConversationalStreamMessages(payload);
  final user = messages.lastWhere((m) => m['role'] == 'user');
  return user['content'] as String;
}

void main() {
  group('Coach seam', () {
    test('payload serialises direction only when set', () {
      expect(
        AiOperatingLayerPayload(userInput: 'hi').toJson().containsKey('direction'),
        isFalse,
      );
      final json = AiOperatingLayerPayload(
        userInput: 'hi',
        direction: const ['This month (September): Ship it'],
      ).toJson();
      expect(json['direction'], ['This month (September): Ship it']);
    });

    test('prompt block sits after the intent hint, before the feature guide',
        () {
      final prompt = _userPrompt(
        AiOperatingLayerPayload(
          userInput: 'what should I work on?',
          intentHint: 'INTENT HINT',
          featureGuide: 'GUIDE TEXT',
          direction: const [
            'This quarter (Q3 2026): Launch SidePal',
            'This month (September): Get SidePal ready for launch',
          ],
        ),
      );
      final hint = prompt.indexOf('INTENT HINT');
      final block = prompt.indexOf('What matters to them right now');
      final guide = prompt.indexOf('FEATURE GUIDE');
      expect(hint, greaterThanOrEqualTo(0));
      expect(block, greaterThan(hint));
      expect(guide, greaterThan(block));
      expect(prompt, contains('  - This quarter (Q3 2026): Launch SidePal'));
      expect(prompt, contains('Direction is context, not a command'));
    });

    test('no direction → no block, no rule', () {
      final prompt = _userPrompt(
        AiOperatingLayerPayload(userInput: 'hi'),
      );
      expect(prompt, isNot(contains('What matters to them right now')));
      expect(prompt, isNot(contains('Direction is context')));
    });
  });

  group('Insight phrasing seam', () {
    test('CoachingAiPayload carries direction and bumps the prompt version',
        () {
      expect(kCoachingAiPromptVersion, 'v1.1.0');
      const ctx = AiDeliveryContext(
        timingProfile: 'morning',
        localDateKey: '2026-09-11',
      );
      const base = CoachingAiPayload(
        focusId: 'f1',
        focusReason: 'x',
        framing: CoachingFraming.consistency,
        summaryType: SummaryType.daily,
        primaryInsightType: 'y',
        focusScore: 0.5,
        urgencyScore: 0.5,
        evaluationTrace: [],
        keyPatternCodes: [],
        topEvidence: {},
        deliveryContext: ctx,
        generatedAtMs: 1,
        promptVersion: kCoachingAiPromptVersion,
      );
      expect(base.toMap().containsKey('direction'), isFalse);
      const withDirection = CoachingAiPayload(
        focusId: 'f1',
        focusReason: 'x',
        framing: CoachingFraming.consistency,
        summaryType: SummaryType.daily,
        primaryInsightType: 'y',
        focusScore: 0.5,
        urgencyScore: 0.5,
        evaluationTrace: [],
        keyPatternCodes: [],
        topEvidence: {},
        deliveryContext: ctx,
        generatedAtMs: 1,
        promptVersion: kCoachingAiPromptVersion,
        direction: ['This month (September): Ship it'],
      );
      expect(withDirection.toMap()['direction'], ['This month (September): Ship it']);
    });
  });

  group('Thinking Loop seam', () {
    test('snapshot carries current-period entries only, with ids', () {
      final august = DateTime(2026, 8, 20);
      final snapshot = buildReflectionSnapshot(
        facts: const [],
        people: const [],
        intentions: const [],
        now: _now,
        directions: [
          _entry(DirectionHorizon.month, august, 'August focus'),
          _entry(DirectionHorizon.quarter, _now, 'Launch SidePal'),
          _entry(DirectionHorizon.year, _now, ''),
        ],
      );
      final direction = snapshot['direction'] as List;
      expect(direction.length, 1);
      expect(direction.single['id'], 'dir_quarter_2026-Q3');
      expect(direction.single['period'], 'Q3 2026');
      expect(direction.single['text'], 'Launch SidePal');
    });

    test('snapshot omits the key when nothing current is set', () {
      final snapshot = buildReflectionSnapshot(
        facts: const [],
        people: const [],
        intentions: const [],
        now: _now,
        directions: [
          _entry(DirectionHorizon.month, DateTime(2026, 8, 1), 'Old'),
        ],
      );
      expect(snapshot.containsKey('direction'), isFalse);
    });

    test('direction ids join the grounding universe', () {
      final ids = reflectionKnownIds(
        facts: const [],
        people: const [],
        intentions: const [],
        directions: [_entry(DirectionHorizon.month, _now, 'Ship it')],
      );
      expect(ids, contains('dir_month_2026-09'));
    });

    test('hash changes with a direction edit, not with the clock', () {
      final a = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: const [],
        directions: [
          _entry(DirectionHorizon.month, _now, 'Ship it', updatedAtMs: 100),
        ],
      );
      final edited = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: const [],
        directions: [
          _entry(DirectionHorizon.month, _now, 'Ship it v2', updatedAtMs: 200),
        ],
      );
      final sameLaterDay = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: const [],
        directions: [
          _entry(DirectionHorizon.month, _now, 'Ship it', updatedAtMs: 100),
        ],
      );
      expect(a, isNot(edited));
      expect(a, sameLaterDay);
      // No direction at all keeps the pre-Direction hash shape.
      final none = reflectionInputsHash(
        facts: const [],
        people: const [],
        intentions: const [],
      );
      expect(none, isNot(a));
    });
  });
}
