import 'package:flutter/foundation.dart';

import '../domain/models/ai_action.dart';
import '../domain/models/ai_intent_kind.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_response_type.dart';
import 'ai_action_param_normaliser.dart';
import 'ai_assumption_engine.dart';
import 'ai_capability_registry.dart';
import 'ai_chat_suggestion_enricher.dart';
import 'ai_conflict_detector.dart';
import 'ai_entity_resolver.dart';
import 'ai_intent_router.dart';
import '../../education/domain/feature_guides.dart';
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
    this.entityResolver,
  });

  final AiOperatingLayerClient client;
  final AiPayloadAssembler assembler;
  final AiAssumptionEngine assumptionEngine;
  final AiConflictDetector? conflictDetector;
  final AiChatSuggestionEnricher? chatSuggestionEnricher;

  /// Resolves entity-targeting actions to concrete ids before the preview
  /// card (fix-wave Phase 1). Null in legacy tests — targeting actions then
  /// reach the executor unresolved and fail loudly there.
  final AiEntityResolver? entityResolver;

  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
    bool voiceMode = false,
  }) async {
    // Fast path — "what can you do?" gets a real answer, never the LLM's
    // guess or a clarify loop.
    if (AiCapabilityRegistry.isCapabilityQuestion(userInput)) {
      return AiPlannedChanges(
        sessionId: sessionId,
        responseType: AiResponseType.informational,
        informationalMessage: AiCapabilityRegistry.capabilityAnswer,
        suggestedPrompts: AiCapabilityRegistry.capabilitySuggestedPrompts,
      );
    }

    // Education topic match — must precede detectUnsupported, otherwise
    // "What are Circles?" hits the canned "Circles are not available in
    // Coach AI" answer instead of a guide-grounded explanation. Commands
    // ("add me to a circle") are not education-shaped and fall through.
    final educationGuide = FeatureGuides.isEducationQuestion(userInput)
        ? FeatureGuides.matchTopic(userInput)
        : null;

    if (educationGuide == null) {
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
    }

    final route = AiIntentRouter.classify(userInput);

    // Deterministic clarify escape (clarify-loop fix 2026-08-20): when the
    // previous turn asked for a specific missing field, read the answer
    // straight out of the reply and complete the pending plan locally —
    // no model round-trip, no chance to re-ask a question the user just
    // answered ("What time should I schedule it?" → "2 pm" → same question
    // forever was the failure mode).
    if (previousPlan != null &&
        previousPlan.requiresFollowUp &&
        previousPlan.actions.isNotEmpty) {
      final merged = _overlayClarificationAnswers(
        previousPlan.actions,
        userInput,
        previousPlan.followUpQuestion,
      );
      if (!identical(merged, previousPlan.actions) &&
          AiMissingFieldDetector.checkAll(merged).isComplete) {
        final enriched = await _enrichWithAssumptions(merged);
        final conflicts = <String>[];
        final blocked = <String>[];
        if (conflictDetector != null) {
          try {
            final detected = await conflictDetector!.detect(enriched);
            conflicts.addAll(detected.softConflicts);
            blocked.addAll(detected.hardBlocks);
          } catch (_) {
            // Best-effort, same stance as the model path.
          }
        }
        return AiPlannedChanges(
          sessionId: sessionId,
          responseType: AiResponseType.mutate,
          actions: enriched,
          conflicts: conflicts,
          blockedByContext: blocked,
        );
      }
    }

    // Human-readable context for the model about the turn we're refining.
    // Must include the follow-up QUESTION (so a short answer like "9am" or
    // "as it is" is understood as answering it), not just the raw actions —
    // and must exist even when there are no partial actions, otherwise the
    // model re-parses the answer bare and re-asks the same question.
    String? previousPlanSummary;
    if (previousPlan != null) {
      final parts = <String>[];
      final question = previousPlan.followUpQuestion;
      if (question != null && question.isNotEmpty) {
        parts.add(
          'You just asked the user: "$question" — their new message '
          'is the answer. Merge it into the pending plan; do not re-ask.',
        );
      } else if (previousPlan.isSuggest) {
        parts.add(
          'You proposed the plan below and the user is replying to '
          'it. Refine that plan per their reply; keep everything they '
          'did not change (including times). Do not start over.',
        );
      }
      if (previousPlan.actions.isNotEmpty) {
        parts.add(
          'Pending plan: ${previousPlan.actions.map((a) => '${a.actionType.name}: ${a.parameters}').join('; ')}',
        );
      }
      if (parts.isNotEmpty) previousPlanSummary = parts.join(' ');
    }

    // Step 1 — Assemble payload
    // The turn ledger ([ai-timing], latency batch 2): assembly is every
    // local read the payload needs (Isar slices + ContextSnapshot method
    // channels); model is the whole agent loop (per-round detail logged
    // by the client). Splits the reply leg so slow turns name a culprit.
    final assembleSw = Stopwatch()..start();
    late AiOperatingLayerPayload payload;
    try {
      payload = await assembler.assemble(
        userInput,
        sessionId,
        previousPlanSummary: previousPlanSummary,
        intentRoute: route,
        proactiveContext: proactiveContext,
        featureGuideText: educationGuide?.toPromptBlock(),
        voiceMode: voiceMode,
      );
    } catch (e) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            "I'm having trouble reading your schedule right now. Could you try again?",
      );
    }
    assembleSw.stop();

    // Step 2 — Call AI client
    final modelSw = Stopwatch()..start();
    late AiPlannedChanges result;
    try {
      result = await client.parseIntent(payload);
    } on AiOperatingLayerException catch (e) {
      // Network-honest copy (P2-13): being offline is a fact of the world,
      // not a failure of the request — say so instead of a vague apology.
      final msg = e.isNetwork
          ? "You're offline — I need a connection for this. "
                "Ask me again once you're back online."
          : e.isRateLimit
          ? "I've hit my request limit. Please try again in a moment."
          : "Something went wrong processing your request. Please try again.";
      return AiPlannedChanges(sessionId: sessionId, followUpQuestion: msg);
    } catch (_) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion: 'I ran into an unexpected issue. Please try again.',
      );
    }
    modelSw.stop();
    if (kDebugMode) {
      debugPrint(
        '[ai-timing] assemble=${assembleSw.elapsedMilliseconds}ms '
        'model=${modelSw.elapsedMilliseconds}ms voice=$voiceMode',
      );
    }

    // Carry the correct sessionId (client may return the user input as id)
    result = result.copyWith(sessionId: sessionId);

    // Destructive-action guard: the model has answered a polite decline
    // ("no thank you") with a delete-everything plan (2026-08-22 bug
    // batch). Deletions only survive when the user's own words asked for
    // one — or when they're refining a plan that already contained them.
    result = _stripUnrequestedDeletes(result, userInput, previousPlan);

    // Retired-verb guard (fix-wave Phase 0): verbs the executor cannot
    // perform yet must never reach a preview card — a confirmed no-op that
    // says "Done" is worse than an honest refusal. The tool enum no longer
    // offers them, but the model can still emit one from conversation
    // history or drift; strip here so the card only ever promises real work.
    result = _stripRetiredActions(result);

    // Step 3 — Router guardrails before mutation pipeline.
    result = _applyRouterGuardrails(result, route, payload);

    // Read-only or unsupported answers skip the mutation pipeline.
    if (result.isInformational || result.isUnsupported) {
      // Teaching answers offer the guide's own follow-up prompts first.
      if (result.isInformational && educationGuide != null) {
        result = result.copyWith(
          suggestedPrompts: <String>{
            ...educationGuide.suggestedPrompts,
            ...result.suggestedPrompts,
          }.take(3).toList(),
        );
      }
      if (result.isInformational && chatSuggestionEnricher != null) {
        final extra = await chatSuggestionEnricher!.promptsForInformationalGaps(
          payload,
        );
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

    // The model may STILL have dropped a field the user just answered
    // (answering a follow-up) — overlay the extracted answer before
    // interrogating again, or the identical question loops.
    if (previousPlan != null &&
        previousPlan.requiresFollowUp &&
        result.actions.isNotEmpty) {
      result = result.copyWith(
        actions: _overlayClarificationAnswers(
          result.actions,
          userInput,
          previousPlan.followUpQuestion,
        ),
      );
    }

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

    // Entity resolution BEFORE the card: targeting actions map to concrete
    // ids here, so the preview shows the real matched entity and execution
    // can never guess. Zero/multiple matches become a LOCAL question — no
    // model call, no quota (fix-wave Phase 1, settled Q2).
    if (entityResolver != null) {
      final resolution = await entityResolver!.resolve(enrichedActions);
      switch (resolution) {
        case EntityResolutionQuestion(:final question):
          return AiPlannedChanges(
            sessionId: sessionId,
            followUpQuestion: question,
            actions: enrichedActions,
          );
        case EntityResolutionOk(:final actions):
          enrichedActions = actions;
      }
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
          ? (result.informationalMessage ??
                _defaultSuggestMessage(enrichedActions))
          : result.informationalMessage,
    );
  }

  /// Verbs the executor cannot perform (fix-wave Phase 0/1,
  /// PRD/AI_assitance/AI_chat_fix_design.md). The six mutation verbs were
  /// retired in Phase 0 and re-enabled in Phase 1 once their handlers
  /// became real (resolver-stamped ids, true edits, full deletion set).
  /// The two remaining kinds are decorative read-only actions with no
  /// executor — they used to throw mid-batch and poison confirmed plans
  /// into rollback (§8 E6).
  static const kRetiredActionTypes = {
    ActionType.suggestFreeTimeBlock,
    ActionType.moveConflictingTasks,
  };

  /// Drops actions whose verb is retired. When some actions survive, the
  /// plan proceeds with an honest note about the part that can't be done;
  /// when nothing survives, the turn degrades to an honest refusal with a
  /// pointer to the manual surface (settled Q1: no pre-filled-editor cards).
  AiPlannedChanges _stripRetiredActions(AiPlannedChanges result) {
    if (result.actions.isEmpty) return result;
    final dropped = result.actions
        .where((a) => kRetiredActionTypes.contains(a.actionType))
        .toList();
    if (dropped.isEmpty) return result;
    final kept = result.actions
        .where((a) => !kRetiredActionTypes.contains(a.actionType))
        .toList();
    final note = _retiredExplanation(dropped);
    if (kept.isNotEmpty) {
      if (note.isEmpty) return result.copyWith(actions: kept);
      final message = result.informationalMessage;
      return result.copyWith(
        actions: kept,
        informationalMessage: message == null || message.trim().isEmpty
            ? note
            : '$message\n\n$note',
      );
    }
    final lead = note.isEmpty
        ? "I couldn't turn that into a change I can apply."
        : note;
    return AiPlannedChanges(
      sessionId: result.sessionId,
      responseType: AiResponseType.informational,
      informationalMessage:
          "$lead I didn't change anything.\n\nWhat I can do from here: add "
          'new tasks or goals, set or reschedule reminders, start focus or '
          'sleep windows, and answer questions about your schedule.',
    );
  }

  /// One honest clause naming what was asked for and where to do it instead.
  String _retiredExplanation(List<AiAction> dropped) {
    final phrases = <String>{};
    for (final action in dropped) {
      switch (action.actionType) {
        case ActionType.editTask:
        case ActionType.moveTask:
          phrases.add('move or edit existing tasks');
        case ActionType.deleteTask:
          phrases.add('delete tasks');
        case ActionType.modifyGoal:
        case ActionType.deleteGoal:
          phrases.add('change or delete goals');
        case ActionType.removeReminder:
          phrases.add('remove reminders');
        default:
          break; // suggestFreeTimeBlock / moveConflictingTasks: silent drop
      }
    }
    if (phrases.isEmpty) return '';
    return "I can't ${phrases.join(' or ')} yet — tap the item in the app "
        'to do that.';
  }

  /// Action types that permanently destroy user data.
  static const _deleteActionTypes = {
    ActionType.deleteTask,
    ActionType.deleteGoal,
    ActionType.removeReminder,
  };

  /// Words that constitute an explicit request to destroy something.
  static final _deleteIntentPattern = RegExp(
    r'\b(delete|remove|clear|cancel|drop|erase|wipe|trash|scrap|'
    r'get rid|un ?schedule|take (it|that|them|this) off)\b',
  );

  /// Drops delete-type actions the user never asked for. When nothing is
  /// left, the turn degrades to an honest no-op answer instead of an empty
  /// plan.
  AiPlannedChanges _stripUnrequestedDeletes(
    AiPlannedChanges result,
    String userInput,
    AiPlannedChanges? previousPlan,
  ) {
    if (result.actions.isEmpty) return result;
    final hasDeletes = result.actions.any(
      (a) => _deleteActionTypes.contains(a.actionType),
    );
    if (!hasDeletes) return result;
    final allowed =
        _deleteIntentPattern.hasMatch(userInput.toLowerCase()) ||
        (previousPlan?.actions.any(
              (a) => _deleteActionTypes.contains(a.actionType),
            ) ??
            false);
    if (allowed) return result;
    final kept = result.actions
        .where((a) => !_deleteActionTypes.contains(a.actionType))
        .toList();
    if (kept.isNotEmpty) return result.copyWith(actions: kept);
    return AiPlannedChanges(
      sessionId: result.sessionId,
      responseType: AiResponseType.informational,
      informationalMessage:
          "I didn't change anything. If you want something deleted, just "
          'tell me which item.',
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

    // The mutate route is a keyword heuristic and misfires on conversational
    // messages ("what else can you do", "thanks"). When the model answered
    // with a real informational message, trust the model — only fall back to
    // the clarify question when it produced nothing usable at all.
    if (route.kind == AiIntentKind.mutate &&
        result.isInformational &&
        result.actions.isEmpty &&
        (result.informationalMessage == null ||
            result.informationalMessage!.trim().isEmpty)) {
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
    final parts = actions
        .take(3)
        .map((a) {
          final title = a.parameters['title']?.toString() ?? a.actionType.name;
          final time = a.parameters['time']?.toString();
          return time != null ? '$title at $time' : title;
        })
        .join(', ');
    return 'I\'d suggest: $parts. Tap Apply this plan when you\'re ready to preview.';
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Short affirmations/rejections are never field ANSWERS — "perfect" must
  /// not become a task title.
  static final _nonAnswerReply = RegExp(
    r'^(yes|yeah|yep|ok(ay)?|sure|confirm|perfect|great|good|no|nope|'
    r'cancel|stop)\b',
    caseSensitive: false,
  );

  /// Fills missing required fields on [actions] from the user's free-text
  /// reply — the deterministic half of clarification handling. Returns the
  /// SAME list instance when nothing was extracted (callers use identical()
  /// as the no-op signal). Title-ish fields fill only when [followUpQuestion]
  /// is literally that field's question: the user was asked for a name, so
  /// their reply IS the name.
  List<AiAction> _overlayClarificationAnswers(
    List<AiAction> actions,
    String userInput,
    String? followUpQuestion,
  ) {
    final askedForDurationInMinutes =
        followUpQuestion?.contains('in minutes') ?? false;
    var changed = false;
    final result = <AiAction>[];
    for (final action in actions) {
      final check = AiMissingFieldDetector.check(action);
      if (check.isComplete) {
        result.add(action);
        continue;
      }
      final params = Map<String, dynamic>.from(action.parameters);
      var actionChanged = false;
      for (final field in check.missingFields) {
        final answer = _extractFieldAnswer(
          field,
          userInput,
          bareNumberIsMinutes: askedForDurationInMinutes,
          // The pending question was THIS field's own question — only then
          // may free text be taken verbatim as a title.
          allowVerbatimTitle:
              followUpQuestion != null &&
              followUpQuestion == check.questionToAsk &&
              field == check.missingFields.first,
        );
        if (answer != null) {
          params[field] = answer;
          actionChanged = true;
        }
      }
      if (actionChanged) {
        changed = true;
        result.add(action.copyWith(parameters: params));
      } else {
        result.add(action);
      }
    }
    return changed ? result : actions;
  }

  Object? _extractFieldAnswer(
    String field,
    String userInput, {
    required bool bareNumberIsMinutes,
    required bool allowVerbatimTitle,
  }) {
    switch (field) {
      case 'time':
      case 'reminderTime':
        return AiActionParamNormaliser.extractTimeAnswer(userInput);
      case 'duration':
        return AiActionParamNormaliser.extractDurationAnswer(
          userInput,
          bareNumberIsMinutes: bareNumberIsMinutes,
        );
      case 'date':
      case 'destinationDate':
      case 'deadline':
        return AiActionParamNormaliser.extractDateAnswer(userInput);
      case 'title':
      case 'taskTitle':
      case 'goalTitle':
        if (!allowVerbatimTitle) return null;
        final text = userInput.trim();
        if (text.isEmpty || text.split(RegExp(r'\s+')).length > 6) return null;
        if (_nonAnswerReply.hasMatch(text)) return null;
        if (AiActionParamNormaliser.extractTimeAnswer(text) != null) {
          return null; // a time reply is not a name
        }
        return text;
      default:
        return null;
    }
  }

  /// For each action that is still incomplete after the first missing-field
  /// check, runs the Assumption Engine and merges any confident suggestions.
  Future<List<AiAction>> _enrichWithAssumptions(List<AiAction> actions) async {
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

      results.add(
        action.copyWith(
          parameters: mergedParams,
          reasonLabel: assumption.reasonLabel,
        ),
      );
    }
    return results;
  }
}
