// Sending the FIRST message from the ask-bar peek must show the pending
// turn at once (user bubble + thinking dots at the conversation stage) —
// not stay at the input-only peek until the reply lands (on-device
// report, 2026-09-22).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:sidepal/features/ai_assistant/presentation/widgets/chat_bubbles.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';

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
    bool voiceMode = false,
  }) async => _stubPayload;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The reply waits on [gate] — the turn stays in flight until released.
class _GatedClient implements AiOperatingLayerClient {
  final gate = Completer<void>();
  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    await gate.future;
    return AiPlannedChanges(
      sessionId: 'x',
      responseType: AiResponseType.informational,
      informationalMessage: 'ok',
    );
  }
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

({AiAssistantService service, _GatedClient client}) _gatedService() {
  final history = _NoOpHistory();
  final client = _GatedClient();
  final service = AiAssistantService(
    intentParser: AiIntentParser(
      client: client,
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
  return (service: service, client: client);
}

Future<void> _openAskBar(
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

double _sheetHeight(WidgetTester tester) =>
    tester.getSize(find.byType(AiAssistantScreen)).height;

void main() {
  for (final keyboard in [false, true]) {
    testWidgets(
      'first send from the peek shows the pending turn at the conversation '
      'stage while the reply is in flight (keyboard: $keyboard)',
      (tester) async {
        final (:service, :client) = _gatedService();
        await _openAskBar(tester, service);
        if (keyboard) {
          // A phone keyboard: ~336pt of the 844pt surface.
          tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        final peekHeight = _sheetHeight(tester);
        expect(tester.takeException(), isNull);

        unawaited(service.sendMessage('What is my plan?'));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);

        expect(
          service.isLoading,
          isTrue,
          reason: 'turn must still be in flight',
        );
        expect(
          find.textContaining('What is my plan?'),
          findsOneWidget,
          reason: 'the user bubble must be visible while waiting',
        );
        expect(
          find.byType(ThinkingIndicator),
          findsOneWidget,
          reason: 'the thinking dots must be visible while waiting',
        );
        expect(
          _sheetHeight(tester),
          greaterThan(peekHeight + 60),
          reason: 'the sheet must leave the input-only peek on send',
        );

        client.gate.complete();
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
