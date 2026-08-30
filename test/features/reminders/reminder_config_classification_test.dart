import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-21 (a user override is never overwritten) and FR-R-23 (classification
/// can never disable a reminder).
void main() {
  ReminderConfig config({
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
    int criticality = 1,
    ClassificationSource source = ClassificationSource.heuristic,
    bool enabled = true,
  }) => ReminderConfig(
    id: 'r1',
    taskId: 't1',
    taskTitle: 'Study',
    enabled: enabled,
    scheduledAtIso: '2026-08-30T14:00:00.000',
    taxonomy: taxonomy,
    criticality: criticality,
    classificationSource: source,
    createdAtMs: 1,
    updatedAtMs: 1,
  );

  group('withClassification — precedence (FR-R-21)', () {
    test('a heuristic result applies over a heuristic default', () {
      final updated = config().withClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 2,
        source: ClassificationSource.heuristic,
        updatedAtMs: 99,
      );
      expect(updated.taxonomy, ReminderTaxonomy.timeSensitive);
      expect(updated.criticality, 2);
      expect(updated.classificationSource, ClassificationSource.heuristic);
    });

    test('a heuristic result NEVER overwrites a user override', () {
      final userSet = config(
        taxonomy: ReminderTaxonomy.routine,
        criticality: 0,
        source: ClassificationSource.user,
      );

      final updated = userSet.withClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 2,
        source: ClassificationSource.heuristic,
        updatedAtMs: 99,
      );

      expect(updated.taxonomy, ReminderTaxonomy.routine);
      expect(updated.criticality, 0);
      expect(updated.classificationSource, ClassificationSource.user);
    });

    test('AI cannot overwrite a user override either', () {
      final userSet = config(source: ClassificationSource.user);
      final updated = userSet.withClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 3,
        source: ClassificationSource.ai,
        updatedAtMs: 99,
      );
      expect(updated.classificationSource, ClassificationSource.user);
      expect(updated.taxonomy, ReminderTaxonomy.flexible);
    });

    test('force lets the editor itself speak over a previous user choice', () {
      final userSet = config(
        taxonomy: ReminderTaxonomy.routine,
        source: ClassificationSource.user,
      );
      final updated = userSet.withClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 3,
        source: ClassificationSource.user,
        updatedAtMs: 99,
        force: true,
      );
      expect(updated.taxonomy, ReminderTaxonomy.timeSensitive);
      expect(updated.criticality, 3);
    });

    test('criticality is clamped to 0..3 whatever the caller passes', () {
      expect(
        config()
            .withClassification(
              taxonomy: ReminderTaxonomy.flexible,
              criticality: 99,
              source: ClassificationSource.ai,
              updatedAtMs: 1,
            )
            .criticality,
        3,
      );
      expect(
        config()
            .withClassification(
              taxonomy: ReminderTaxonomy.flexible,
              criticality: -5,
              source: ClassificationSource.ai,
              updatedAtMs: 1,
            )
            .criticality,
        0,
      );
    });
  });

  group('FR-R-23 — classification can never disable a reminder', () {
    test('an enabled reminder stays enabled through any classification', () {
      for (final source in ClassificationSource.values) {
        for (final taxonomy in ReminderTaxonomy.values) {
          final updated = config().withClassification(
            taxonomy: taxonomy,
            criticality: 0,
            source: source,
            updatedAtMs: 1,
          );
          expect(updated.enabled, isTrue, reason: '$source/$taxonomy');
        }
      }
    });

    test('a disabled reminder is not switched on by classification', () {
      final updated = config(enabled: false).withClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 3,
        source: ClassificationSource.ai,
        updatedAtMs: 1,
      );
      expect(updated.enabled, isFalse);
    });

    test('the scheduled time is never touched either', () {
      final updated = config().withClassification(
        taxonomy: ReminderTaxonomy.routine,
        criticality: 0,
        source: ClassificationSource.heuristic,
        updatedAtMs: 1,
      );
      expect(updated.scheduledAtIso, '2026-08-30T14:00:00.000');
    });
  });

  group('serialization round-trip', () {
    test('classification survives toMap/fromMap', () {
      final original = config(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 3,
        source: ClassificationSource.user,
      ).copyWith(classifierVersion: 7);

      final back = ReminderConfig.fromMap(original.toMap());

      expect(back.taxonomy, ReminderTaxonomy.timeSensitive);
      expect(back.criticality, 3);
      expect(back.classificationSource, ClassificationSource.user);
      expect(back.classifierVersion, 7);
    });

    test('a row written before classification existed is marked migration', () {
      final legacy = <String, dynamic>{
        'id': 'r1',
        'taskId': 't1',
        'enabled': true,
        'scheduledAtIso': '2026-08-30T14:00:00.000',
        'createdAtMs': 1,
        'updatedAtMs': 1,
      };

      final parsed = ReminderConfig.fromMap(legacy);

      expect(parsed.taxonomy, ReminderTaxonomy.flexible);
      expect(parsed.criticality, 1);
      // Not `heuristic`: no heuristic ever looked at this row. The marker is
      // what FR-R-22's AI pass targets.
      expect(parsed.classificationSource, ClassificationSource.migration);
      expect(parsed.classifierVersion, isNull);
    });

    test('an unknown taxonomy from a newer client degrades to flexible', () {
      final future = <String, dynamic>{
        'id': 'r1',
        'taskId': 't1',
        'enabled': true,
        'taxonomy': 'someFutureClass',
        'classificationSource': 'someFutureSource',
        'createdAtMs': 1,
        'updatedAtMs': 1,
      };

      final parsed = ReminderConfig.fromMap(future);

      expect(parsed.taxonomy, ReminderTaxonomy.flexible);
      expect(parsed.classificationSource, ClassificationSource.heuristic);
    });
  });
}
