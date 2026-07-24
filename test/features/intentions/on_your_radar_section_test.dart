import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/analytics/application/insight_generation_providers.dart';
import 'package:sidepal/features/analytics/data/insight_cache_repository.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:sidepal/features/intentions/application/intention_nudge_sync_service.dart';
import 'package:sidepal/features/intentions/application/intentions_providers.dart';
import 'package:sidepal/features/intentions/data/intentions_repository.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';
import 'package:sidepal/features/intentions/presentation/on_your_radar_section.dart';
import 'package:sidepal/features/thinking/application/thinking_loop_service.dart';

/// Phase 7b — the "on your radar" collapsed tail of Promises.

Intention _dormant(String id, {String title = 'Get back into climbing'}) =>
    Intention(
      id: id,
      title: title,
      rawUtterance: title,
      windowStartMs: 0,
      windowEndMs: DateTime.now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
      estimatedMinutes: 30,
      status: IntentionStatus.dormant,
      createdAtMs: 1,
      updatedAtMs: 1,
    );

GeneratedInsight _observation({String? dateKey}) {
  final day = dateKey ?? DateKeys.todayKey();
  return GeneratedInsight(
    insightId: 'insight_reflection_1',
    scopeType: InsightScopeType.entity,
    scopeId: ThinkingLoopService.reflectionScopeId,
    insightType: InsightType.reflectionObservation,
    insightBucket: InsightBucket.neutral,
    priority: InsightPriority.low,
    messageKey: 'reflection_observation_1',
    message: 'Looks like calling Sara keeps slipping to weekends.',
    action: InsightAction.focus,
    linkedPatternCodes: const [],
    confidence: 0.6,
    detectedAtMs: 1,
    sourceWindowStartDateKey: day,
    sourceWindowEndDateKey: day,
  );
}

class _FakeIntentionsRepository implements IntentionsRepository {
  final statusUpdates = <(String, IntentionStatus)>[];
  Intention? updateResult;

  @override
  Future<Intention?> updateStatus(
    String intentionId,
    IntentionStatus status, {
    int? completedAtMs,
    bool bumpNudgeCount = false,
    bool bumpSnoozeCount = false,
  }) async {
    statusUpdates.add((intentionId, status));
    return updateResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeNudgeSyncService implements IntentionNudgeSyncService {
  final applied = <String>[];

  @override
  Future<void> applyForIntention(Intention intention) async {
    applied.add(intention.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeInsightCache implements InsightCacheRepository {
  final cleared = <String>[];

  @override
  Future<void> replaceScopeInsights({
    required InsightScopeType scopeType,
    required String scopeId,
    required List<GeneratedInsight> insights,
  }) async {
    if (insights.isEmpty) cleared.add(scopeId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Widget _harness({
  required List<Intention> intentions,
  List<GeneratedInsight> insights = const [],
  _FakeIntentionsRepository? repo,
  _FakeNudgeSyncService? nudge,
  _FakeInsightCache? cache,
}) {
  return ProviderScope(
    overrides: [
      intentionsStreamProvider.overrideWith((ref) => Stream.value(intentions)),
      layer3EntityInsightsProvider(
        ThinkingLoopService.reflectionScopeId,
      ).overrideWith((ref) => Stream.value(insights)),
      if (repo != null) intentionsRepositoryProvider.overrideWithValue(repo),
      if (nudge != null)
        intentionNudgeSyncServiceProvider.overrideWithValue(nudge),
      if (cache != null)
        insightCacheRepositoryProvider.overrideWithValue(cache),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: OnYourRadarSection())),
    ),
  );
}

void main() {
  testWidgets('hidden entirely when nothing is on the radar', (tester) async {
    await tester.pumpWidget(_harness(intentions: const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('ON YOUR RADAR'), findsNothing);
  });

  testWidgets('collapsed by default: count visible, content hidden',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        intentions: [_dormant('intention_1')],
        insights: [_observation()],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ON YOUR RADAR · 2'), findsOneWidget);
    expect(find.text('Get back into climbing'), findsNothing);
  });

  testWidgets('expanding reveals dormant rows and the labeled observation',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        intentions: [_dormant('intention_1')],
        insights: [_observation()],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ON YOUR RADAR · 2'));
    await tester.pumpAndSettle();
    expect(find.text('Get back into climbing'), findsOneWidget);
    expect(find.textContaining('slipping to weekends'), findsOneWidget);
    expect(find.text('INFERRED'), findsOneWidget);
  });

  testWidgets("yesterday's observation does not linger", (tester) async {
    final yesterday = DateKeys.todayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    await tester.pumpWidget(
      _harness(
        intentions: [_dormant('intention_1')],
        insights: [_observation(dateKey: yesterday)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ON YOUR RADAR · 1'), findsOneWidget);
  });

  testWidgets('"Remind me" promotes to open and plans the ladder',
      (tester) async {
    final repo = _FakeIntentionsRepository();
    final nudge = _FakeNudgeSyncService();
    final dormant = _dormant('intention_1');
    repo.updateResult = dormant.copyWith(status: IntentionStatus.open);

    await tester.pumpWidget(
      _harness(intentions: [dormant], repo: repo, nudge: nudge),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ON YOUR RADAR · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remind me'));
    await tester.pumpAndSettle();

    expect(repo.statusUpdates, [('intention_1', IntentionStatus.open)]);
    expect(nudge.applied, ['intention_1']);
  });

  testWidgets('dismissing a dormant intention retires it', (tester) async {
    final repo = _FakeIntentionsRepository();
    await tester.pumpWidget(
      _harness(intentions: [_dormant('intention_1')], repo: repo),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ON YOUR RADAR · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(repo.statusUpdates, [
      ('intention_1', IntentionStatus.dismissed),
    ]);
  });

  testWidgets('dismissing the observation clears the reflection scope',
      (tester) async {
    final cache = _FakeInsightCache();
    await tester.pumpWidget(
      _harness(
        intentions: const [],
        insights: [_observation()],
        cache: cache,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ON YOUR RADAR · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(cache.cleared, [ThinkingLoopService.reflectionScopeId]);
  });
}
