import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/reminder_classifier.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-20's golden set: real-looking task titles → the class they must get.
///
/// The `rule` is asserted alongside the class on purpose. A change that lands
/// the right taxonomy for the wrong reason (a keyword accidentally matching,
/// a default swallowing a rule) still fails here.
class _Case {
  const _Case(
    this.title,
    this.taxonomy,
    this.criticality,
    this.rule, {
    this.hasReminderTime = true,
    this.durationMinutes,
    this.category,
    this.isHabitAnchor = false,
  });

  final String title;
  final ReminderTaxonomy taxonomy;
  final int criticality;
  final String rule;
  final bool hasReminderTime;
  final int? durationMinutes;
  final String? category;
  final bool isHabitAnchor;
}

const _golden = <_Case>[
  // ── Keyword → timeSensitive, criticality 2 ────────────────────────────────
  _Case('Team meeting', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Standup', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Call the bank when they open',
      ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Dentist appointment', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Dr. Abebe — clinic visit',
      ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Take meds', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Take medication with food',
      ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Evening insulin', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Vitamins', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Flight to Addis', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Submit the tax form', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Assignment deadline', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('1:1 sync with Sara', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Job interview', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  _Case('Physics lecture', ReminderTaxonomy.timeSensitive, 2, 'keyword'),
  // Keywords outrank the habit toggle — daily meds are still medication.
  _Case('Take meds', ReminderTaxonomy.timeSensitive, 2, 'keyword',
      isHabitAnchor: true),

  // ── Habit anchor → routine, criticality 0 ─────────────────────────────────
  _Case('Drink water', ReminderTaxonomy.routine, 0, 'habitAnchor',
      isHabitAnchor: true),
  _Case('Make the bed', ReminderTaxonomy.routine, 0, 'habitAnchor',
      isHabitAnchor: true),
  _Case('Morning stretch', ReminderTaxonomy.routine, 0, 'habitAnchor',
      isHabitAnchor: true, category: 'Fitness'),
  _Case('Journal', ReminderTaxonomy.routine, 0, 'habitAnchor',
      isHabitAnchor: true, category: 'Personal'),
  _Case('Read 10 pages', ReminderTaxonomy.routine, 0, 'habitAnchor',
      isHabitAnchor: true, category: 'Study'),

  // ── Scheduled short work block → timeSensitive, criticality 1 ─────────────
  _Case('Review the PR', ReminderTaxonomy.timeSensitive, 1,
      'scheduledShortWorkBlock',
      durationMinutes: 20, category: 'Work'),
  _Case('Send the invoice', ReminderTaxonomy.timeSensitive, 1,
      'scheduledShortWorkBlock',
      durationMinutes: 30, category: 'Work'),
  // 31 minutes is not a slot any more.
  _Case('Write the spec', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 31, category: 'Work'),
  // Short, but no time set.
  _Case('Tidy the inbox', ReminderTaxonomy.flexible, 1, 'default',
      hasReminderTime: false, durationMinutes: 15, category: 'Work'),
  // Short and timed, but not Work.
  _Case('Stretch', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 15, category: 'Fitness'),

  // ── Default → flexible, criticality 1 ─────────────────────────────────────
  _Case('Study for 1 hour', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 60, category: 'Study'),
  _Case('Gym session', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 60, category: 'Fitness'),
  _Case('Clean the kitchen', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 45, category: 'Personal'),
  _Case('Plan the week', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 45, category: 'Plan'),
  _Case('Work on the side project', ReminderTaxonomy.flexible, 1, 'default',
      durationMinutes: 120, category: 'Work'),
  _Case('Groceries', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Water the plants', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Laundry', ReminderTaxonomy.flexible, 1, 'default',
      category: 'Kitchen chores'), // custom category → no special treatment

  // ── False positives the whole-word rule must NOT catch ────────────────────
  _Case('Social media catch-up', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Recall the old design', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Immediate follow-up notes', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Classify the photos', ReminderTaxonomy.flexible, 1, 'default'),
  _Case('Duesseldorf trip research', ReminderTaxonomy.flexible, 1, 'default'),
];

void main() {
  test('golden set covers at least 30 titles (FR-R-20)', () {
    expect(_golden.length, greaterThanOrEqualTo(30));
  });

  group('ReminderClassifier golden set', () {
    for (final c in _golden) {
      test('"${c.title}" → ${c.taxonomy.name} (${c.rule})', () {
        final result = ReminderClassifier.classify(
          title: c.title,
          hasReminderTime: c.hasReminderTime,
          durationMinutes: c.durationMinutes,
          category: c.category,
          isHabitAnchor: c.isHabitAnchor,
        );

        expect(result.taxonomy, c.taxonomy, reason: c.title);
        expect(result.criticality, c.criticality, reason: c.title);
        expect(result.rule, c.rule, reason: c.title);
      });
    }
  });

  group('invariants', () {
    test('the heuristic never assigns criticality 3', () {
      // Criticality 3 pierces the boundary, the Focus Shield and the sleep
      // window. Only the user grants it (settled 2026-08-30).
      for (final c in _golden) {
        final result = ReminderClassifier.classify(
          title: c.title,
          hasReminderTime: c.hasReminderTime,
          durationMinutes: c.durationMinutes,
          category: c.category,
          isHabitAnchor: c.isHabitAnchor,
        );
        expect(result.criticality, lessThan(3), reason: c.title);
      }
    });

    test('criticality always sits inside 0..3', () {
      for (final c in _golden) {
        final result = ReminderClassifier.classify(
          title: c.title,
          hasReminderTime: c.hasReminderTime,
          durationMinutes: c.durationMinutes,
          category: c.category,
          isHabitAnchor: c.isHabitAnchor,
        );
        expect(result.criticality, inInclusiveRange(0, 3));
      }
    });

    test('an empty title still classifies', () {
      final result = ReminderClassifier.classify(title: '   ');
      expect(result.taxonomy, ReminderTaxonomy.flexible);
      expect(result.rule, 'default');
    });

    test('classification is case- and punctuation-insensitive', () {
      for (final title in ['MEETING', 'Meeting!', '  meeting  ', 'a MEETING?']) {
        expect(
          ReminderClassifier.classify(title: title).taxonomy,
          ReminderTaxonomy.timeSensitive,
          reason: title,
        );
      }
    });

    test('tokenize splits on punctuation and drops empties', () {
      expect(
        ReminderClassifier.tokenize('Dr. Abebe — 1:1 sync!'),
        ['dr', 'abebe', '1', '1', 'sync'],
      );
    });

    test('the same input always gives the same answer', () {
      final a = ReminderClassifier.classify(title: 'Team meeting');
      final b = ReminderClassifier.classify(title: 'Team meeting');
      expect(a, b);
    });
  });
}
