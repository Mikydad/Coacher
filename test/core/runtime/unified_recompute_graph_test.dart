import 'package:flutter_test/flutter_test.dart';

import 'package:sidepal/core/runtime/recompute_scope.dart';
import 'package:sidepal/core/runtime/unified_recompute_graph.dart';

void main() {
  final graph = UnifiedRecomputeGraph.instance;

  setUp(() {
    graph.debugDurationOverride = Duration.zero;
  });

  tearDown(() => graph.resetForTests());

  group('RecomputeScope', () {
    test('merge ORs all flags', () {
      const a = RecomputeScope(overlaps: true, analytics: false);
      const b = RecomputeScope(overlaps: false, analytics: true, notifications: true);
      final merged = a.merge(b);
      expect(merged.overlaps, isTrue);
      expect(merged.analytics, isTrue);
      expect(merged.notifications, isTrue);
      expect(merged.focus, isFalse);
    });

    test('isEmpty returns true when all flags false', () {
      expect(const RecomputeScope().isEmpty, isTrue);
    });

    test('forReminderChange only sets notifications', () {
      final scope = RecomputeScope.forReminderChange();
      expect(scope.notifications, isTrue);
      expect(scope.analytics, isFalse);
      expect(scope.overlaps, isFalse);
      expect(scope.focus, isFalse);
      expect(scope.suggestions, isFalse);
      expect(scope.layer34, isFalse);
      expect(scope.aiSummary, isFalse);
    });

    test('forContextOverrideChange only sets notifications', () {
      final scope = RecomputeScope.forContextOverrideChange();
      expect(scope.notifications, isTrue);
      expect(scope.analytics, isFalse);
    });

    test('forTaskMutation sets all flags', () {
      final scope = RecomputeScope.forTaskMutation();
      expect(scope.overlaps, isTrue);
      expect(scope.analytics, isTrue);
      expect(scope.focus, isTrue);
      expect(scope.suggestions, isTrue);
      expect(scope.layer34, isTrue);
      expect(scope.aiSummary, isTrue);
      expect(scope.notifications, isTrue);
    });

    test('forGoalChange does NOT set overlaps or notifications', () {
      final scope = RecomputeScope.forGoalChange();
      expect(scope.overlaps, isFalse);
      expect(scope.notifications, isFalse);
      expect(scope.analytics, isTrue);
      expect(scope.focus, isTrue);
      expect(scope.suggestions, isTrue);
      expect(scope.layer34, isTrue);
    });
  });

  group('UnifiedRecomputeGraph', () {
    test('scheduling two mutations within debounce coalesces into one flush',
        () async {
      graph.schedule(RecomputeScope.forReminderChange());
      graph.schedule(RecomputeScope.forReminderChange());

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(graph.flushCountForTests, 1);
    });

    test('generation bump from second mutation before flush aborts first',
        () async {
      // Use a longer debounce so we can schedule a second one before flush.
      graph.debugDurationOverride = const Duration(milliseconds: 50);

      graph.schedule(RecomputeScope.forReminderChange());
      // Before the 50 ms fires, schedule again — bumps generation.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      graph.schedule(RecomputeScope.forReminderChange());

      // Wait for the second flush to fire.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only one flush should have fully completed (the first was aborted or
      // coalesced; the timer was reset so only the second fires).
      expect(graph.flushCountForTests, 1);
    });

    test('schedule with empty scope is a no-op', () async {
      graph.schedule(const RecomputeScope());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(graph.flushCountForTests, 0);
    });

    test('flushNowForTests triggers flush synchronously', () {
      graph.schedule(RecomputeScope.forGoalChange());
      graph.flushNowForTests();
      expect(graph.flushCountForTests, 1);
    });

    test('scopes coalesce correctly across two schedule calls', () async {
      graph.schedule(RecomputeScope.forReminderChange()); // notifications only
      graph.schedule(RecomputeScope.forGoalChange()); // analytics+focus+suggestions+layer34

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // One flush should have run with merged scope.
      expect(graph.flushCountForTests, 1);
    });
  });
}
