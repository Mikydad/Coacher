import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/application/intention_capture.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';

void main() {
  final monday9 = DateTime(2026, 7, 20, 9); // Monday 09:00

  group('resolveIntentionWindow', () {
    test('tomorrow maps to waking-window bounds, never midnight', () {
      final w = resolveIntentionWindow(IntentionWindowKind.tomorrow, monday9);
      expect(w.start, DateTime(2026, 7, 21, 8));
      expect(w.end, DateTime(2026, 7, 21, 21));
    });

    test('today past 20:00 honestly becomes tomorrow', () {
      final lateNight = DateTime(2026, 7, 20, 22, 30);
      final w = resolveIntentionWindow(IntentionWindowKind.today, lateNight);
      expect(w.start, DateTime(2026, 7, 21, 8));
      expect(w.end, DateTime(2026, 7, 21, 21));
    });

    test('this week ends Sunday 21:00', () {
      final w = resolveIntentionWindow(IntentionWindowKind.thisWeek, monday9);
      expect(w.end, DateTime(2026, 7, 26, 21));
    });

    test('weekend spans Saturday morning to Sunday evening', () {
      final w = resolveIntentionWindow(IntentionWindowKind.weekend, monday9);
      expect(w.start, DateTime(2026, 7, 25, 8));
      expect(w.end, DateTime(2026, 7, 26, 21));
    });
  });

  group('IntentionHeuristicParser.parse', () {
    test('parses a call intention with lead-in and time phrase', () {
      final draft = IntentionHeuristicParser.parse(
        'I need to call cousin Sara tomorrow',
        clock: monday9,
      );
      expect(draft, isNotNull);
      expect(draft!.title, 'Call cousin Sara');
      expect(draft.activityTags, ['call']);
      expect(draft.estimatedMinutes, 15);
      expect(draft.windowStart, DateTime(2026, 7, 21, 8));
      expect(draft.rawUtterance, 'I need to call cousin Sara tomorrow');
    });

    test('message verbs get message tags and a 10-minute estimate', () {
      final draft = IntentionHeuristicParser.parse(
        'remind me to send the report today',
        clock: monday9,
      );
      expect(draft!.activityTags, ['message', 'quick']);
      expect(draft.estimatedMinutes, 10);
    });

    test('no time phrase returns null (quick-add sheet takes over)', () {
      expect(
        IntentionHeuristicParser.parse('call cousin Sara', clock: monday9),
        isNull,
      );
    });

    test('single-word action after stripping returns null', () {
      expect(
        IntentionHeuristicParser.parse('I need to sleep tomorrow',
            clock: monday9),
        isNull,
      );
    });

    test('overly long utterances are rejected', () {
      final long = 'I need to call ${'x' * 250} tomorrow';
      expect(IntentionHeuristicParser.parse(long, clock: monday9), isNull);
    });

    test('parseToActionParams emits executor-shaped parameters', () {
      final params = IntentionHeuristicParser.parseToActionParams(
        'I need to buy groceries this weekend',
        clock: monday9,
      );
      expect(params, isNotNull);
      expect(params!['title'], 'Buy groceries');
      expect(params['window'], 'weekend');
      expect(params['activityTags'], ['errand']);
      expect(params['estimatedMinutes'], 30);
    });
  });

  group('buildIntention / model round-trip', () {
    test('draft becomes a valid intention with stamped timestamps', () {
      final draft = IntentionHeuristicParser.parse(
        'I need to call cousin Sara tomorrow',
        clock: monday9,
      )!;
      final intention = buildIntention(draft, now: monday9);
      intention.validate();
      expect(intention.id, startsWith('intention_'));
      expect(intention.updatedAtMs, monday9.millisecondsSinceEpoch);
      expect(intention.isPlannable, isTrue);
    });

    test('toMap/fromMap round-trips every field', () {
      final original = buildIntention(
        IntentionDraft(
          title: 'Call cousin Sara',
          rawUtterance: 'call sara tomorrow',
          windowStart: DateTime(2026, 7, 21, 8),
          windowEnd: DateTime(2026, 7, 21, 21),
          estimatedMinutes: 15,
          importance: IntentionImportance.high,
          activityTags: const ['call'],
          aiHintsJson: '{"preferredTimeBlock":"evening"}',
        ),
        now: monday9,
      ).copyWith(status: IntentionStatus.dormant, nudgeCount: 2);

      final restored = Intention.fromMap(original.toMap());
      expect(restored.toMap(), original.toMap());
      expect(restored.status, IntentionStatus.dormant);
      expect(restored.importance, IntentionImportance.high);
      expect(restored.active, isTrue);
    });

    test('unknown storage values fall back safely', () {
      expect(intentionStatusFromStorage('???'), IntentionStatus.open);
      expect(
        intentionImportanceFromStorage(null),
        IntentionImportance.normal,
      );
    });
  });
}
