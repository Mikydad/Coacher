import '../domain/models/ai_action.dart';
import '../domain/models/ai_intent_kind.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_response_type.dart';
import 'ai_assumption_engine.dart';
import 'ai_capability_registry.dart';
import 'ai_chat_suggestion_enricher.dart';
import 'ai_conflict_detector.dart';
import 'ai_intent_router.dart';
import 'ai_missing_field_detector.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';
import 'ai_plan_deduplicator.dart';
import 'ai_schedule_answer_formatter.dart';

/// Orchestrates the full parse pipeline for a single user turn:
///
///   1. Classify intent (query / suggest / mutate).
///   2. Assemble context payload from live app data.
///   3. Call the AI client to parse the user's intent.
///   4. Apply router guardrails (query coercion, mutate clarify).
///   5. Run the Missing Field Detector + Assumption Engine.
///   6. Run the Conflict Detector on the complete action list.
///   7. Return [AiPlannedChanges] — informational, suggest, mutate, or follow-up.
class AiIntentParser {
  const AiIntentParser({
    required this.client,
    required this.assembler,
    required this.assumptionEngine,
    this.conflictDetector,
    this.chatSuggestionEnricher,
  });

  final AiOperatingLayerClient client;
  final AiPayloadAssembler assembler;
  final AiAssumptionEngine assumptionEngine;
  final AiConflictDetector? conflictDetector;
  final AiChatSuggestionEnricher? chatSuggestionEnricher;

  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
  }) async {
    // Fast path — unsupported domains never reach the LLM.
    final unsupported = AiCapabilityRegistry.detectUnsupported(userInput);
    if (unsupported != null) {
      return AiPlannedChanges(
        sessionId: sessionId,
        responseType: AiResponseType.unsupported,
        informationalMessage: unsupported.message,
        suggestedPrompts: unsupported.suggestedPrompts,
      );
    }

    final route = AiIntentRouter.classify(userInput);

    // Build a human-readable summary of the previous plan for the AI context
    final previousPlanSummary = previousPlan != null && previousPlan.actions.isNotEmpty
        ? previousPlan.actions
            .map((a) => '${a.actionType.name}: ${a.parameters}')
            .join('; ')
        : null;

    // Step 1 — Assemble payload
    late AiOperatingLayerPayload payload;
    try {
      payload = await assembler.assemble(
        userInput,
        sessionId,
        previousPlanSummary: previousPlanSummary,
        intentRoute: route,
        proactiveContext: proactiveContext,
      );
    } catch (e) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            "I'm having trouble reading your schedule right now. Could you try again?",
      );
    }

    // Step 2 — Call AI client
    late AiPlannedChanges result;
    try {
      result = await client.parseIntent(payload);
    } on AiOperatingLayerException catch (e) {
      final msg = e.isRateLimit
          ? "I've hit my request limit. Please try again in a moment."
          : "Something went wrong processing your request. Please try again.";
      return AiPlannedChanges(sessionId: sessionId, followUpQuestion: msg);
    } catch (_) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            'I ran into an unexpected issue. Please try again.',
      );
    }

    // Carry the correct sessionId (client may return the user input as id)
    result = result.copyWith(sessionId: sessionId);

    // Step 3 — Router guardrails before mutation pipeline.
    result = _applyRouterGuardrails(result, route, payload);

    // Read-only or unsupported answers skip the mutation pipeline.
    if (result.isInformational || result.isUnsupported) {
      if (result.isInformational && chatSuggestionEnricher != null) {
        final extra =
            await chatSuggestionEnricher!.promptsForInformationalGaps(payload);
        if (extra.isNotEmpty) {
          final merged = <String>[
            ...result.suggestedPrompts,
            ...extra,
          ].take(3).toList();
          result = result.copyWith(suggestedPrompts: merged);
        }
      }
      return result;
    }

    // Suggest with narrative only (no draft actions).
    if (result.isSuggest && result.actions.isEmpty) return result;

    // If the AI already asked a follow-up, propagate it
    if (result.requiresFollowUp) return result;

    // Step 4 — Missing field check + Assumption Engine
    var enrichedActions = await _enrichWithAssumptions(result.actions);

    // Drop actions that duplicate tasks already on today's list
    enrichedActions = AiPlanDeduplicator.filter(
      enrichedActions,
      payload.activeTasks,
      userInput,
      isRefiningPreviousPlan: previousPlan != null,
    );
    if (enrichedActions.isEmpty &&
        result.actions.isNotEmpty &&
        previousPlan == null) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            "That already appears on today's list. What else would you like to add?",
      );
    }

    final missingCheck = AiMissingFieldDetector.checkAll(enrichedActions);
    if (!missingCheck.isComplete) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion: missingCheck.questionToAsk,
        actions: enrichedActions,
      );
    }

    // Step 5 — Conflict detection (reminder collision, context, enforcement)
    final allConflicts = List<String>.from(result.conflicts);
    final allBlocked = <String>[];

    if (conflictDetector != null) {
      try {
        final detected = await conflictDetector!.detect(enrichedActions);
        allConflicts.addAll(detected.softConflicts);
        allBlocked.addAll(detected.hardBlocks);
      } catch (_) {
        // Conflict detection is best-effort — never block the pipeline
      }
    }

    final responseType = _resolveResponseType(result, route, enrichedActions);

    return result.copyWith(
      responseType: responseType,
      actions: enrichedActions,
      conflicts: allConflicts,
      blockedByContext: allBlocked,
      informationalMessage: responseType == AiResponseType.suggest
          ? (result.informationalMessage ?? _defaultSuggestMessage(enrichedActions))
          : result.informationalMessage,
    );
  }

  AiPlannedChanges _applyRouterGuardrails(
    AiPlannedChanges result,
    AiIntentRoute route,
    AiOperatingLayerPayload payload,
  ) {
    if (route.kind == AiIntentKind.query &&
        result.isMutate &&
        result.actions.isNotEmpty) {
      final coerced = AiScheduleAnswerFormatter.tryAnswerScheduleQuery(payload);
      if (coerced != null) {
        return AiPlannedChanges(
          sessionId: result.sessionId,
          responseType: AiResponseType.informational,
          informationalMessage: coerced,
        );
      }
    }

    if (route.kind == AiIntentKind.mutate &&
        result.isInformational &&
        result.actions.isEmpty) {
      return AiPlannedChanges(
        sessionId: result.sessionId,
        followUpQuestion:
            'Could you tell me exactly what you\'d like to change? '
            'For example: "Add workout at 6am tomorrow."',
      );
    }

    if (route.kind == AiIntentKind.suggest &&
        result.isMutate &&
        result.actions.isNotEmpty &&
        (result.informationalMessage == null ||
            result.informationalMessage!.isEmpty)) {
      return result.copyWith(
        responseType: AiResponseType.suggest,
        informationalMessage: _defaultSuggestMessage(result.actions),
      );
    }

    return result;
  }

  AiResponseType _resolveResponseType(
    AiPlannedChanges result,
    AiIntentRoute route,
    List<AiAction> actions,
  ) {
    if (result.isSuggest) return AiResponseType.suggest;
    if (route.kind == AiIntentKind.suggest && actions.isNotEmpty) {
      return AiResponseType.suggest;
    }
    return AiResponseType.mutate;
  }

  String _defaultSuggestMessage(List<AiAction> actions) {
    if (actions.isEmpty) {
      return 'Here\'s what I\'d suggest based on your schedule.';
    }
    final parts = actions.take(3).map((a) {
      final title = a.parameters['title']?.toString() ?? a.actionType.name;
      final time = a.parameters['time']?.toString();
      return time != null ? '$title at $time' : title;
    }).join(', ');
    return 'I\'d suggest: $parts. Tap Apply this plan when you\'re ready to preview.';
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// For each action that is still incomplete after the first missing-field
  /// check, runs the Assumption Engine and merges any confident suggestions.
  Future<List<AiAction>> _enrichWithAssumptions(
    List<AiAction> actions,
  ) async {
    final results = <AiAction>[];
    for (final action in actions) {
      final check = AiMissingFieldDetector.check(action);
      if (check.isComplete) {
        results.add(action);
        continue;
      }

      // Try the Assumption Engine
      final assumption = await assumptionEngine.infer(action);
      if (!assumption.hasMatch) {
        results.add(action);
        continue;
      }

      // Merge suggested parameters (only null fields)
      final mergedParams = Map<String, dynamic>.from(action.parameters);
      assumption.suggestedParameters.forEach((key, value) {
        if (mergedParams[key] == null) {
          mergedParams[key] = value;
        }
      });

      results.add(action.copyWith(
        parameters: mergedParams,
        reasonLabel: assumption.reasonLabel,
      ));
    }
    return results;
  }
}
