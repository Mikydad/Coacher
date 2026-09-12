import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_activity_category_rule.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/time_tracker/data/activity_category_rule_repository.dart';
import 'package:sidepal/features/time_tracker/domain/day_summary.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_category_rule.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/timeline_builder.dart';

import '../../support/isar_test_harness.dart';

void main() {
  group('ActivityCategoryRule', () {
    test('deterministic id from normalised text', () {
      final a = ActivityCategoryRule.forText(
        '  Gym ',
        category: ActivityCategories.exercise,
        source: CategoryRuleSource.user,
        nowMs: 1,
      );
      final b = ActivityCategoryRule.forText(
        'GYM',
        category: ActivityCategories.exercise,
        source: CategoryRuleSource.ai,
        nowMs: 2,
      );
      expect(a.id, b.id);
      expect(a.normalizedText, 'gym');
      expect(() => a.validate(), returnsNormally);
    });

    test('round-trip and unknown category → other', () {
      final r = ActivityCategoryRule.forText(
        'Study Flutter',
        category: ActivityCategories.learning,
        source: CategoryRuleSource.ai,
        nowMs: 5,
      );
      final back = ActivityCategoryRule.fromMap(r.toMap());
      expect(back.id, r.id);
      expect(back.category, ActivityCategories.learning);
      expect(back.source, CategoryRuleSource.ai);
      final odd = ActivityCategoryRule.fromMap({
        'normalizedText': 'x',
        'category': 'nonsense',
        'updatedAtMs': 1,
      });
      expect(odd.category, ActivityCategories.other);
    });

    test('validate rejects bad category and non-deterministic id', () {
      expect(
        () => ActivityCategoryRule(
          id: 'cat_x',
          normalizedText: 'gym',
          category: ActivityCategories.exercise,
          source: CategoryRuleSource.ai,
          createdAtMs: 1,
          updatedAtMs: 1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => ActivityCategoryRule.forText(
          'gym',
          category: 'sports',
          source: CategoryRuleSource.ai,
          nowMs: 1,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('buildDaySummary with categories', () {
    final day = DateTime(2026, 9, 12);
    int at(int h, [int m = 0]) =>
        DateTime(day.year, day.month, day.day, h, m).millisecondsSinceEpoch;
    ActivityEvent e(String text, int start) => ActivityEvent(
      id: 'act_$start',
      text: text,
      startedAtMs: start,
      dateKey: activityDateKeyFor(start),
      createdAtMs: 1,
      updatedAtMs: 1,
    );

    test('no rules → no category block', () {
      final s = buildDaySummary(buildTimeline([e('Gym', at(7)), e('Work', at(8))]));
      expect(s.hasCategories, isFalse);
    });

    test('rules → category totals, uncategorised in Other, Other last', () {
      final rows = buildTimeline([
        e('Gym', at(7)),
        e('SidePal', at(8)),
        e('Mystery', at(9, 30)),
        e('End', at(10)),
      ]);
      final s = buildDaySummary(
        rows,
        categoryOf: {'gym': ActivityCategories.exercise, 'sidepal': ActivityCategories.work},
      );
      expect(s.hasCategories, isTrue);
      expect(s.categoryLines.map((l) => l.label), ['Work', 'Exercise', 'Other']);
      expect(s.categoryLines[0].total, const Duration(hours: 1, minutes: 30));
      expect(s.categoryLines[1].total, const Duration(hours: 1));
      expect(s.categoryLines[2].total, const Duration(minutes: 30));
      // Activity lines are unchanged.
      expect(s.lines.first.label, 'SidePal');
    });
  });

  group('ActivityCategoryRuleRepository', () {
    Isar? isar;
    Directory? dir;
    var clock = 1000;
    late ActivityCategoryRuleRepository repo;

    setUp(() async {
      SyncService.debugSkipQueuePersistenceForTests = true;
      final opened = await openTempIsar();
      isar = opened.isar;
      dir = opened.dir;
      OfflineStore.debugIsarOverride = isar;
      clock = 1000;
      repo = ActivityCategoryRuleRepository(now: () => clock);
    });

    tearDown(() async {
      SyncService.debugSkipQueuePersistenceForTests = false;
      OfflineStore.clearDebugIsarOverrideForTests();
      final i = isar;
      final d = dir;
      isar = null;
      dir = null;
      if (i != null && d != null) await closeTempIsar(i, d);
    });

    test('ai sets, user overrides, ai never overwrites user', () async {
      final ai = await repo.setCategory(
        'Gym',
        category: ActivityCategories.rest,
        source: CategoryRuleSource.ai,
      );
      expect(ai!.source, CategoryRuleSource.ai);
      clock = 2000;
      final user = await repo.setCategory(
        'gym ',
        category: ActivityCategories.exercise,
        source: CategoryRuleSource.user,
      );
      expect(user!.id, ai.id);
      expect(user.category, ActivityCategories.exercise);
      expect(user.createdAtMs, 1000);
      clock = 3000;
      final again = await repo.setCategory(
        'GYM',
        category: ActivityCategories.chores,
        source: CategoryRuleSource.ai,
      );
      expect(again!.category, ActivityCategories.exercise, reason: 'user wins');
      expect(again.updatedAtMs, 2000);
      expect(await isar!.isarActivityCategoryRules.count(), 1);
    });

    test('same value is a no-op; watchAll emits', () async {
      await repo.setCategory('Gym', category: ActivityCategories.exercise, source: CategoryRuleSource.ai);
      clock = 2000;
      final same = await repo.setCategory('Gym', category: ActivityCategories.exercise, source: CategoryRuleSource.ai);
      expect(same!.updatedAtMs, 1000);
      final all = await repo.watchAll().first;
      expect(all.single.normalizedText, 'gym');
    });

    test('LWW merge: newer remote applied, older ignored', () async {
      final local = await repo.setCategory('Gym', category: ActivityCategories.exercise, source: CategoryRuleSource.user);
      final older = local!.copyWith(category: ActivityCategories.rest, updatedAtMs: 500);
      expect(await mergeActivityCategoryRuleLwwIntoIsar(isar!, older), isFalse);
      final newer = local.copyWith(category: ActivityCategories.rest, updatedAtMs: 9000);
      expect(await mergeActivityCategoryRuleLwwIntoIsar(isar!, newer), isTrue);
      expect((await repo.getForText('gym'))!.category, ActivityCategories.rest);
    });
  });
}
