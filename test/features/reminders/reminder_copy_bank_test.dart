import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/reminder_copy_bank.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-63 (deterministic half) and FR-R-34.
///
/// The bank's contract is TOTALITY: every combination a compiled slot can
/// present must resolve to a real sentence, because by the time a slot fires
/// there is nobody left to compose a fallback.
void main() {
  const modes = ['flexible', 'disciplined', 'extreme'];

  group('coverage — every combination says something', () {
    test('mode x step x taxonomy x criticality is total', () {
      var checked = 0;
      for (final mode in [...modes, null, 'strict-ish-typo']) {
        for (var step = 0; step < 4; step++) {
          for (final taxonomy in ReminderTaxonomy.values) {
            for (var criticality = 0; criticality <= 3; criticality++) {
              final copy = ReminderCopyBank.forSlot(
                entityTitle: 'Study',
                modeRefId: mode,
                taxonomy: taxonomy,
                ladderPosition: step,
                criticality: criticality,
              );
              final label = '$mode/$step/${taxonomy.name}/c$criticality';

              expect(copy.body.trim(), isNotEmpty, reason: label);
              expect(copy.title.trim(), isNotEmpty, reason: label);
              // The task's name is what makes it specific (PRD §8).
              expect(copy.body, contains('Study'), reason: label);
              // No template leftovers reach the user.
              expect(copy.body, isNot(contains('{')), reason: label);
              expect(copy.body, isNot(contains('null')), reason: label);
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(200));
    });

    test('a blank title still produces a sayable sentence', () {
      for (final title in ['', '   ']) {
        final copy = ReminderCopyBank.forSlot(entityTitle: title);
        expect(copy.title.trim(), isNotEmpty);
        expect(copy.body, contains('your task'));
      }
    });
  });

  group('the modes actually sound different (M2)', () {
    test('at the same escalation step, each mode says its own thing', () {
      final bodies = {
        for (final mode in modes)
          mode: ReminderCopyBank.forSlot(
            entityTitle: 'Study',
            modeRefId: mode,
            ladderPosition: 2,
          ).body,
      };

      expect(bodies.values.toSet(), hasLength(3));
    });

    test('escalation gets more direct within a mode', () {
      final first = ReminderCopyBank.forSlot(
        entityTitle: 'Study',
        modeRefId: 'extreme',
        ladderPosition: 0,
      ).body;
      final last = ReminderCopyBank.forSlot(
        entityTitle: 'Study',
        modeRefId: 'extreme',
        ladderPosition: 3,
      ).body;

      expect(first, isNot(last));
      expect(last.toLowerCase(), contains('final call'));
    });

    test('extreme asks for a reason; flexible never does', () {
      expect(
        ReminderCopyBank.forSlot(
          entityTitle: 'Study',
          modeRefId: 'extreme',
          ladderPosition: 2,
        ).body.toLowerCase(),
        contains('reason'),
      );
      for (var step = 0; step < 2; step++) {
        expect(
          ReminderCopyBank.forSlot(
            entityTitle: 'Study',
            modeRefId: 'flexible',
            ladderPosition: step,
          ).body.toLowerCase(),
          isNot(contains('reason')),
        );
      }
    });

    test('every mode opens the same gentle way', () {
      for (final mode in modes) {
        expect(
          ReminderCopyBank.forSlot(
            entityTitle: 'Study',
            modeRefId: mode,
            ladderPosition: 0,
          ).body,
          'Time for Study.',
          reason: mode,
        );
      }
    });
  });

  group('taxonomy colours the wording', () {
    test('a time-sensitive follow-up says it will not keep', () {
      final expiring = ReminderCopyBank.forSlot(
        entityTitle: 'Call the bank',
        modeRefId: 'flexible',
        taxonomy: ReminderTaxonomy.timeSensitive,
        ladderPosition: 1,
      ).body;
      final flexible = ReminderCopyBank.forSlot(
        entityTitle: 'Call the bank',
        modeRefId: 'flexible',
        taxonomy: ReminderTaxonomy.flexible,
        ladderPosition: 1,
      ).body;

      expect(expiring, isNot(flexible));
    });

    test('routine never escalates, whatever the step or mode', () {
      for (final mode in modes) {
        for (var step = 0; step < 4; step++) {
          expect(
            ReminderCopyBank.forSlot(
              entityTitle: 'Water',
              modeRefId: mode,
              taxonomy: ReminderTaxonomy.routine,
              ladderPosition: step,
            ).body,
            'Time for Water.',
            reason: '$mode/$step',
          );
        }
      }
    });
  });

  group('criticality 3 speaks plainly', () {
    test('it never nags, whatever the mode', () {
      for (final mode in modes) {
        final body = ReminderCopyBank.forSlot(
          entityTitle: 'Take meds',
          modeRefId: mode,
          taxonomy: ReminderTaxonomy.timeSensitive,
          criticality: 3,
          ladderPosition: 3,
        ).body;
        expect(body.toLowerCase(), isNot(contains('final call')), reason: mode);
        expect(body, contains('Take meds'), reason: mode);
      }
    });
  });

  group('batched body no longer leaks intent ids (M4)', () {
    test('it counts partners instead of naming them', () {
      expect(
        ReminderCopyBank.batchedBody('Study', 1),
        'Time for Study, plus one more.',
      );
      expect(
        ReminderCopyBank.batchedBody('Study', 3),
        'Time for Study, plus 3 more.',
      );
    });

    test('no partners reads as a plain reminder', () {
      expect(ReminderCopyBank.batchedBody('Study', 0), 'Time for Study.');
    });
  });

  group('recovery summary', () {
    test('singular and plural both read naturally', () {
      expect(ReminderCopyBank.recoverySummary(1).body, contains('One task'));
      expect(ReminderCopyBank.recoverySummary(4).body, contains('4 tasks'));
    });
  });
}
