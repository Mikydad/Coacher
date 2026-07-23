import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/insight_generation_orchestrator.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:sidepal/features/memory/application/relationship_care_service.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';
import 'package:sidepal/features/memory/domain/models/person.dart';

Person _person({
  String id = 'person_1',
  String name = 'Sarah',
  String? relationship = 'my sister',
  PersonKind kind = PersonKind.family,
  int? lastInteractionAtMs,
}) {
  return Person(
    id: id,
    displayName: name,
    relationship: relationship,
    kind: kind,
    provenance: MemoryProvenance.userStated,
    lastInteractionAtMs: lastInteractionAtMs,
    createdAtMs: 1000,
    updatedAtMs: 1000,
  );
}

void main() {
  final now = DateTime(2026, 7, 23, 12);

  group('RelationshipCareService.isCaredAboutKind', () {
    test('family and partner are cared about; others are not', () {
      expect(
        RelationshipCareService.isCaredAboutKind(
          _person(kind: PersonKind.family),
        ),
        isTrue,
      );
      expect(
        RelationshipCareService.isCaredAboutKind(
          _person(kind: PersonKind.partner),
        ),
        isTrue,
      );
      expect(
        RelationshipCareService.isCaredAboutKind(
          _person(kind: PersonKind.friend),
        ),
        isFalse,
      );
      expect(
        RelationshipCareService.isCaredAboutKind(
          _person(kind: PersonKind.work),
        ),
        isFalse,
      );
    });
  });

  group('RelationshipCareService.buildGapPattern', () {
    test('no baseline (never recorded) emits nothing — zero invention', () {
      final pattern = RelationshipCareService.buildGapPattern(
        _person(lastInteractionAtMs: null),
        now: now,
      );
      expect(pattern, isNull);
    });

    test('gap under threshold emits nothing', () {
      final tenDaysAgo = now
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch;
      final pattern = RelationshipCareService.buildGapPattern(
        _person(lastInteractionAtMs: tenDaysAgo),
        now: now,
      );
      expect(pattern, isNull);
    });

    test('gap at threshold emits a deterministic person pattern', () {
      final at = now.subtract(const Duration(days: 21));
      final pattern = RelationshipCareService.buildGapPattern(
        _person(lastInteractionAtMs: at.millisecondsSinceEpoch),
        now: now,
      )!;
      expect(pattern.patternCode, PatternCode.relationshipGap);
      expect(pattern.patternGroup, PatternGroup.relationshipCare);
      expect(pattern.entityKind, BehaviorEntityKind.person);
      expect(pattern.entityId, 'person_1');
      expect(pattern.severity, closeTo(0.4, 0.0001));
      expect(pattern.confidence, 1.0);
      expect(pattern.metadata['gapDays'], 21);
      expect(pattern.sourceWindowEndDateKey, '2026-07-23');
      pattern.validate();
    });

    test('severity grows with gap and caps at 1.0', () {
      final at = now.subtract(const Duration(days: 200));
      final pattern = RelationshipCareService.buildGapPattern(
        _person(lastInteractionAtMs: at.millisecondsSinceEpoch),
        now: now,
      )!;
      expect(pattern.severity, 1.0);
    });

    test('custom threshold is respected', () {
      final at = now.subtract(const Duration(days: 10));
      final pattern = RelationshipCareService.buildGapPattern(
        _person(lastInteractionAtMs: at.millisecondsSinceEpoch),
        now: now,
        gapThresholdDays: 7,
      );
      expect(pattern, isNotNull);
    });
  });

  group('RelationshipCareService.buildCareMessage', () {
    test('uses weeks for gaps of 2+ weeks and includes relationship', () {
      final message = RelationshipCareService.buildCareMessage(_person(), 28);
      expect(message, contains('4 weeks'));
      expect(message, contains('Sarah (my sister)'));
    });

    test('falls back to days under two weeks and to bare name', () {
      final message = RelationshipCareService.buildCareMessage(
        _person(relationship: null),
        10,
      );
      expect(message, contains('10 days'));
      expect(message, contains('Sarah'));
      expect(message, isNot(contains('(')));
    });
  });

  group('end-to-end: gap pattern → policy mapping → personalized insight', () {
    test(
      'a gapped family person yields one relationshipCareNudge insight '
      'scoped to the person with warm personalized copy',
      () {
        final person = _person(
          lastInteractionAtMs: now
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch,
        );
        final pattern = RelationshipCareService.buildGapPattern(
          person,
          now: now,
        )!;

        const orchestrator = InsightGenerationOrchestrator();
        final out = orchestrator.runForEntity(
          entityId: person.id,
          patterns: [pattern],
          now: now,
        );
        expect(out.hasFatalError, isFalse);
        final care = out.insights
            .where((i) => i.insightType == InsightType.relationshipCareNudge)
            .toList();
        expect(care, hasLength(1));
        expect(care.first.scopeType, InsightScopeType.entity);
        expect(care.first.scopeId, person.id);

        final personalized = RelationshipCareService.personalizeInsight(
          care.first,
          person,
          30,
        );
        expect(personalized.message, contains('Sarah (my sister)'));
        expect(personalized.message, contains('4 weeks'));
        expect(personalized.metadata['personId'], person.id);
        expect(personalized.metadata['gapDays'], 30);
        personalized.validate();
      },
    );

    test('personalizeInsight leaves other insight types untouched', () {
      final insight = GeneratedInsight(
        insightId: 'x',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        insightType: InsightType.latePattern,
        insightBucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        messageKey: 'late_pattern_1',
        message: 'original',
        action: InsightAction.reschedule,
        linkedPatternCodes: const ['lateBehavior'],
        confidence: 0.7,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-07-01',
        sourceWindowEndDateKey: '2026-07-23',
      );
      final result = RelationshipCareService.personalizeInsight(
        insight,
        _person(),
        30,
      );
      expect(identical(result, insight), isTrue);
    });
  });
}
