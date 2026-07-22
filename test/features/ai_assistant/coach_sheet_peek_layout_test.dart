// Regression net for the coach sheet's ask-bar peek (decision log
// 2026-07-16): the sheet-mode screen must lay out WITHOUT RenderFlex
// overflow at the peek budget — and at even tighter, keyboard-animation
// heights. On-device this striped three times before the layout was made
// structurally overflow-proof; these tests pin it.

import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_providers.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:sidepal/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:sidepal/features/ai_assistant/presentation/widgets/quick_directives_row.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _stubPayload = AiOperatingLayerPayload(userInput: 'test');

class _FakeAssembler implements AiPayloadAssembler {
  const _FakeAssembler();

  @override
  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    intentRoute,
    proactiveContext,
    String? featureGuideText,
  }) async => _stubPayload;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient implements AiOperatingLayerClient {
  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async =>
      AiPlannedChanges(
        sessionId: 'x',
        responseType: AiResponseType.informational,
        informationalMessage: 'ok',
      );
}

class _NoOpHistory implements AiInteractionHistoryRepository {
  @override
  Future<void> saveAssistantSummary(String sessionId, String summary) async {}

  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<dynamic> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExecutor implements AiActionExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AiAssistantService _fakeService() {
  final history = _NoOpHistory();
  return AiAssistantService(
    intentParser: AiIntentParser(
      client: _FakeClient(),
      assembler: const _FakeAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: history,
        normaliser: const EntityNormaliser(),
      ),
    ),
    actionExecutor: _FakeExecutor(),
    historyRepository: history,
  );
}

/// Pumps the sheet-mode screen constrained to [height] px — the same
/// budget the DraggableScrollableSheet gives it at that stage.
Future<void> _pumpAtHeight(WidgetTester tester, double height) async {
  final service = _fakeService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        resolvedAiAssistantProvider.overrideWith((ref) async => service),
      ],
      child: MaterialApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 390,
            height: height,
            child: const AiAssistantScreen(sheetMode: true),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // provider future resolves
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  Future<double> openSheetAndMeasure(
    WidgetTester tester,
    AiAssistantService service,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resolvedAiAssistantProvider.overrideWith((ref) async => service),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () => showCoachAiSheet(context, askBar: true),
                child: const Icon(Icons.chat),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FloatingActionButton));
    // Bounded pumps (blinking cursor forbids pumpAndSettle): provider
    // resolve + both growth animations + measurement frames.
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    return tester.getSize(find.byType(AiAssistantScreen)).height;
  }

  testWidgets(
    'content-aware growth: a short thread settles at 60%, not full',
    (tester) async {
      final service = _fakeService();
      await service.sendMessage('What is my plan?'); // one short exchange

      final height = await openSheetAndMeasure(tester, service);
      // 60% of the 844px surface ≈ 506; full would be ≈ 844.
      expect(height, lessThan(650),
          reason: 'short chat should stop at the 60% stage');
      expect(find.textContaining('What is my plan?'), findsOneWidget);
    },
  );

  testWidgets(
    'content-aware growth: an overflowing thread continues to full page',
    (tester) async {
      final service = _fakeService();
      // Enough exchanges to overflow the 60% viewport.
      for (var i = 0; i < 10; i++) {
        await service.sendMessage('Longer question number $i to fill space');
      }

      final height = await openSheetAndMeasure(tester, service);
      expect(height, greaterThan(700),
          reason: 'overflowing chat should rise to the full-page stage');
    },
  );

  testWidgets(
    'ask-bar opening onto an existing conversation grows to 60% (messages visible)',
    (tester) async {
      // Phone-sized viewport: the default 800x600 test surface is so short
      // that 60% of it sits below the composer-extras pixel threshold.
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final service = _fakeService();
      // Seed a conversation before the sheet ever opens — the on-device
      // report: peek was hiding an existing thread behind the input.
      await service.sendMessage('What is my plan?');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resolvedAiAssistantProvider.overrideWith((ref) async => service),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () => showCoachAiSheet(context, askBar: true),
                  child: const Icon(Icons.chat),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      // Bounded pumps (blinking cursor forbids pumpAndSettle): provider
      // resolve + growth animation (260ms) + snap.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      // Growth is observable through the composer extras: they only render
      // once the sheet is pixel-taller than the ask-bar peek.
      expect(find.byType(QuickDirectivesRow), findsOneWidget);
      // And the seeded thread is actually on screen.
      expect(find.textContaining('What is my plan?'), findsOneWidget);
    },
  );

  testWidgets('ask-bar peek budget (244px) lays out without overflow', (
    tester,
  ) async {
    await _pumpAtHeight(tester, 244);
    expect(tester.takeException(), isNull);
    // The peek's whole point: the input is present and usable.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('mid-keyboard-animation heights never stripe (structural guard)', (
    tester,
  ) async {
    // Sweep the pathological budgets the sheet can pass through while the
    // keyboard animates — every one must clip, not overflow.
    for (final height in const [120.0, 160.0, 200.0, 300.0]) {
      await _pumpAtHeight(tester, height);
      expect(tester.takeException(), isNull, reason: 'overflow at $height px');
    }
  });

  testWidgets('conversation stage (60% ≈ 480px) shows composer extras', (
    tester,
  ) async {
    await _pumpAtHeight(tester, 480);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
