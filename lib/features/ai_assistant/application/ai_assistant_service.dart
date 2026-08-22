import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_id.dart';
import '../../education/domain/feature_guides.dart';
import '../../intentions/application/intention_capture.dart';
import '../../memory/application/memory_extraction_service.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_intent_kind.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_response_type.dart';
import 'ai_action_executor.dart';
import 'ai_action_param_normaliser.dart' show looksPlanShapedProse;
import 'ai_capability_registry.dart';
import 'ai_informational_output_guard.dart';
import 'ai_intent_parser.dart';
import 'ai_intent_router.dart';
import 'proactive_chat_conversion_tracker.dart';
import 'entity_normaliser.dart';
import 'voice_plan_speech.dart';
import 'voice_reply_stream.dart';

/// Signature for fire-and-forget analytics logging from the service layer.
typedef AiAnalyticsLogger =
    void Function(String eventName, Map<String, dynamic> properties);

typedef AiScheduleCacheInvalidator = void Function(String sessionId);

/// Single entry point for the Coach AI presentation layer.
///
/// Owns the in-memory session: conversation thread, pending plan, session ID.
/// All mutations go through [sendMessage], [confirmPlan], [cancelPlan], [editPlan].
class AiAssistantService extends ChangeNotifier {
  AiAssistantService({
    required AiIntentParser intentParser,
    required AiActionExecutor actionExecutor,
    required AiInteractionHistoryRepository historyRepository,
    AiAnalyticsLogger? analyticsLogger,
    EntityNormaliser? normaliser,
    AiScheduleCacheInvalidator? onScheduleMutated,
    MemoryExtractionService? memoryExtraction,
    VoiceReplyStreamer? voiceReplyStreamer,
  }) : _intentParser = intentParser,
       _actionExecutor = actionExecutor,
       _historyRepository = historyRepository,
       _analyticsLogger = analyticsLogger,
       _normaliser = normaliser ?? const EntityNormaliser(),
       _onScheduleMutated = onScheduleMutated,
       _memoryExtraction = memoryExtraction,
       _voiceReplyStreamer = voiceReplyStreamer,
       _sessionId = StableId.generate('session');

  final AiIntentParser _intentParser;
  final AiActionExecutor _actionExecutor;
  final AiInteractionHistoryRepository _historyRepository;
  final MemoryExtractionService? _memoryExtraction;

  /// Exposed for UI (e.g. pick-up-where-you-left-off banner).
  AiInteractionHistoryRepository get historyRepository => _historyRepository;
  final AiAnalyticsLogger? _analyticsLogger;
  final EntityNormaliser _normaliser;
  final AiScheduleCacheInvalidator? _onScheduleMutated;
  final VoiceReplyStreamer? _voiceReplyStreamer;

  String _sessionId;
  final List<AiChatMessage> _messages = [];
  AiPlannedChanges? _pendingPlan;
  bool _isLoading = false;
  bool _inputFocusRequested = false;

  /// Set by [editPlan] — only then do we pass [previousPlan] into the parser.
  bool _refiningPendingPlan = false;

  /// A partial plan the model proposed that is still missing a detail (the
  /// parser asked a follow-up). Kept so the user's NEXT message refines it
  /// instead of starting over — otherwise "schedule as you suggested" loops
  /// back to the same question.
  AiPlannedChanges? _pendingClarification;

  String? _proactiveSuggestionId;
  String? _proactiveSuggestionType;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get hasPendingPlan => _pendingPlan != null;
  AiPlannedChanges? get pendingPlan => _pendingPlan;
  bool get inputFocusRequested => _inputFocusRequested;
  String get sessionId => _sessionId;

  /// Links this session to a proactive card the user tapped before opening Coach.
  void setProactiveContext({String? suggestionId, String? suggestionType}) {
    _proactiveSuggestionId = suggestionId;
    _proactiveSuggestionType = suggestionType;
  }

  Map<String, dynamic>? get _proactiveContextForPayload {
    if (_proactiveSuggestionId == null) return null;
    return {
      'suggestionId': _proactiveSuggestionId,
      if (_proactiveSuggestionType != null)
        'suggestionType': _proactiveSuggestionType,
    };
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// [voiceMode] marks a spoken turn (Voice Mode loop): the reply will be
  /// read aloud, so the parser routes it through the `coach_agent_voice`
  /// purpose for short conversational prose (latency batch 2026-08-07).
  Future<void> sendMessage(String userInput, {bool voiceMode = false}) async {
    if (userInput.trim().isEmpty) return;

    // Memory Phase 2: keep the session's inactivity clock fresh so
    // summarize-then-purge knows when this session actually ended.
    unawaited(_memoryExtraction?.noteSessionActivity(_sessionId));

    // Guests get a sign-in nudge instead of the server's permission error —
    // the aiChat function rejects anonymous accounts (cost-abuse guard).
    // Firebase.apps guard: VM tests construct this service without Firebase.
    final currentUser = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.user,
          content: userInput.trim(),
          timestamp: DateTime.now(),
        ),
      );
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content:
              'Coach AI needs a registered account. Create a free account in '
              'Profile → Sign in and your data comes with you.',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    // 0. While a plan is awaiting confirmation, treat a plain yes/no as the
    // answer to "confirm changes?" — never send it to the parser, which would
    // re-propose the same plan. Awaited so voice turns speak the OUTCOME
    // (confirm-by-voice, 2026-08-21) — execution is local-first, so the
    // await costs milliseconds.
    if (_pendingPlan != null &&
        await _handlePendingPlanShortReply(userInput.trim())) {
      return;
    }

    // 0b. Typed confirmation of a *suggested* plan ("confirm", "ok", "it's
    // good"). Suggest responses park the plan on the message as draftPlan with
    // no pending plan, so without this the affirmation would be re-parsed as a
    // brand-new request — the "What should I call this task?" loop.
    if (_pendingPlan == null &&
        await _tryConfirmLatestDraftOnAffirmation(userInput.trim())) {
      return;
    }

    // 0c. A short polite decline with no plan pending ("no thank you",
    // "that's it") closes the exchange locally. It must NEVER reach the
    // parser: the model has misread "no thank you" as a brand-new command —
    // including proposing deletions of the very items it just listed
    // (2026-08-22 bug batch).
    if (_pendingPlan == null && _handleStandaloneDecline(userInput.trim())) {
      return;
    }

    // 1. Append user message
    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: userInput.trim(),
        timestamp: DateTime.now(),
      ),
    );

    await _parseAndRespond(userInput.trim(), voiceMode: voiceMode);
  }

  /// Steps 2–7 of a turn: loading bubble → parse → render result → persist
  /// history → analytics. Assumes the user message is already in the thread —
  /// [sendMessage] appends it; the streamed-voice fallback path arrives here
  /// with it already appended by [tryStreamVoiceReply].
  Future<void> _parseAndRespond(
    String userInput, {
    required bool voiceMode,
  }) async {
    // 2. Append loading message (thinking…)
    final loadingId = StableId.generate('msg');
    _addMessage(
      AiChatMessage(
        id: loadingId,
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      ),
    );
    _setLoading(true);

    // 3. Mark any existing plan as no longer current
    _demoteCurrentPlan();

    // Pass a previous plan when the user tapped Edit, OR when we're waiting on
    // the answer to a missing-detail question — so the reply refines that plan
    // instead of the model re-proposing from scratch (which caused the
    // "What time should I schedule it?" loop).
    final previousForParser = _refiningPendingPlan
        ? _pendingPlan
        : _pendingClarification;
    _refiningPendingPlan = false;
    _pendingClarification = null;

    // 4. Parse intent
    AiPlannedChanges result;
    try {
      result = await _intentParser.parse(
        userInput.trim(),
        _sessionId,
        previousPlan: previousForParser,
        proactiveContext: _proactiveContextForPayload,
        voiceMode: voiceMode,
      );
    } catch (e) {
      // Offline / AI-down: intention capture must not depend on the network
      // (PRD §4.2). If the utterance parses as a simple promise, capture it
      // locally through the same executor path the online AI uses.
      final heuristicParams = IntentionHeuristicParser.parseToActionParams(
        userInput.trim(),
      );
      if (heuristicParams != null) {
        _removeMessage(loadingId);
        _setLoading(false);
        await _autoCommitIntentionActions(
          [
            AiAction(
              actionType: ActionType.createIntention,
              parameters: heuristicParams,
            ),
          ],
          modelMessage: null,
        );
        return;
      }
      _replaceLoadingMessage(
        loadingId,
        "I ran into an unexpected error. Please try again.",
      );
      _setLoading(false);
      return;
    }

    // 5. Remove loading message, add real response
    _removeMessage(loadingId);
    _setLoading(false);

    // Intentions AUTO-COMMIT with inline undo — the one deliberate
    // relaxation of the confirm-gate (decision log 2026-07-23): stating a
    // promise IS the permission; the real confirmation happens at delivery,
    // where the nudge is phrased as a question.
    // Memory actions ride the same relaxation (Phase 2): "remember this"
    // must feel like telling a friend, not filing a form.
    const autoCommitTypes = {
      ActionType.createIntention,
      ActionType.rememberFact,
      ActionType.updateFact,
      ActionType.forgetFact,
    };
    final isIntentionAutoCommit =
        !result.requiresFollowUp &&
        result.actions.isNotEmpty &&
        result.actions.every((a) => autoCommitTypes.contains(a.actionType));
    if (isIntentionAutoCommit) {
      await _autoCommitIntentionActions(
        result.actions,
        modelMessage: result.informationalMessage,
      );
    } else if (result.requiresFollowUp) {
      final question = AiInformationalOutputGuard.sanitize(
        result.followUpQuestion!,
      );
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: question,
          timestamp: DateTime.now(),
        ),
      );
      _pendingPlan = null;
      // Remember the clarification — including the question itself — so the
      // user's answer refines it. Kept even with no partial actions: dropping
      // it made short answers parse bare and re-trigger the same question.
      _pendingClarification = result;
    } else if (result.isInformational || result.isUnsupported) {
      final raw =
          result.informationalMessage ??
          "I couldn't find an answer for that right now.";
      final message = AiInformationalOutputGuard.sanitize(raw);
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: message,
          timestamp: DateTime.now(),
          suggestedPrompts: result.suggestedPrompts,
        ),
      );
      _pendingPlan = null;
      // A plan that arrived as PROSE (a degraded turn the client repair
      // rounds could not fix) must stay refinable: park it so the next
      // "confirm"/"perfect" refines THIS plan instead of re-parsing bare
      // (deep check 2026-08-20 — the bare re-parse restarted the
      // "What time should I schedule it?" loop).
      if (result.isInformational && looksPlanShapedProse(message)) {
        _pendingClarification = result.copyWith(
          responseType: AiResponseType.suggest,
        );
      }
      if (result.isInformational) {
        _logEvent('aiInformationalAnswer', {
          'sessionId': _sessionId,
          'responseType': result.responseType.name,
        });
      } else {
        _logEvent('aiUnsupportedRequest', {
          'sessionId': _sessionId,
          'responseType': result.responseType.name,
        });
      }
    } else if (result.isSuggest) {
      final raw =
          result.informationalMessage ??
          'Here\'s what I\'d suggest based on your schedule.';
      final message = AiInformationalOutputGuard.sanitize(raw);
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: message,
          timestamp: DateTime.now(),
          draftPlan: result.actions.isNotEmpty ? result : null,
          suggestedPrompts: result.suggestedPrompts,
        ),
      );
      _pendingPlan = null;
      // A free-text reply to a suggestion ("make it 30 minutes", "move it to
      // 9am") must refine THIS plan, not start from scratch. Kept even with
      // NO actions: a narrative-only suggestion still needs "confirm"/
      // "perfect" to refine it rather than re-parse bare — the bare re-parse
      // was one leg of the clarify loop (deep check 2026-08-20).
      _pendingClarification = result;
      _logEvent('aiSuggestPlanShown', {
        'sessionId': _sessionId,
        'actionCount': result.actions.length,
      });
    } else if (result.actions.isEmpty) {
      _pendingPlan = null;
      const fallback =
          "I didn't quite catch what you'd like me to do there. I'm best at "
          "planning your day, managing tasks and goals, and answering "
          "schedule questions — ask \"what can you do?\" for the full list.";
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: fallback,
          timestamp: DateTime.now(),
          suggestedPrompts: const ['What can you do?', 'Help me plan tomorrow'],
        ),
      );
    } else {
      // Plan ready — show preview card. Prefer the model's own short
      // confirmation line when the agent provided one.
      _pendingPlan = result;
      final previewText = result.informationalMessage?.trim();
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: previewText?.isNotEmpty == true
              ? previewText!
              : 'Here\'s what I\'ll do:',
          timestamp: DateTime.now(),
          plannedChanges: result,
          isCurrentPlan: true,
        ),
      );
    }

    // 6. Persist interaction (user turn + assistant summary for multi-turn context)
    await _historyRepository.save(
      sessionId: _sessionId,
      userInput: userInput.trim(),
      parsedActions: result.actions,
      assistantSummary: _assistantSummaryForHistory(result),
      responseType: result.responseType.name,
    );

    // 7. Analytics
    _logEvent('aiCommandSubmitted', {
      'sessionId': _sessionId,
      'inputLength': userInput.trim().length,
    });
    if (result.requiresFollowUp) {
      _logEvent('aiFollowupQuestionAsked', {
        'sessionId': _sessionId,
        'question': result.followUpQuestion,
      });
    }

    notifyListeners();
  }

  // ─── Streamed voice turns (voice Level 2) ─────────────────────────────────

  /// Weekday/relative-day references the streamed endpoint cannot answer:
  /// context carries today, tomorrow, and week COUNTS — day detail beyond
  /// that needs the get_day_schedule tool, which only the agent path has.
  static final _otherDayPattern = RegExp(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|'
    r'yesterday|next month|last week)\b',
  );

  /// Voice Level 2 routing — the [VoiceModeController.tryStreamReply] seam.
  ///
  /// Returns a delta stream ONLY for conversational turns the no-tools
  /// aiChatStream endpoint can serve honestly: query-classified, no plan or
  /// clarification pending (short answers must refine those), none of the
  /// canned fast paths (capability/unsupported answer instantly; education
  /// needs guide grounding), no other-day reference. Everything else — and
  /// guests, whom the endpoint rejects — returns null so the full agent
  /// pipeline handles the turn.
  ///
  /// The streamed turn owns its thread bubbles: user message + a live
  /// assistant bubble that grows with each delta and finalizes into history.
  /// A failure before the first delta falls back internally to the normal
  /// parse path and emits that reply as a single chunk — the voice loop
  /// always gets something to speak (including honest offline copy).
  Stream<String>? tryStreamVoiceReply(String userInput) {
    final streamer = _voiceReplyStreamer;
    final text = userInput.trim();
    if (streamer == null || text.isEmpty) return null;
    if (_pendingPlan != null || _pendingClarification != null) return null;
    final currentUser = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) return null;
    if (AiCapabilityRegistry.isCapabilityQuestion(text)) return null;
    if (FeatureGuides.isEducationQuestion(text)) return null;
    if (AiCapabilityRegistry.detectUnsupported(text) != null) return null;
    final route = AiIntentRouter.classify(text);
    if (route.kind != AiIntentKind.query) return null;
    if (_otherDayPattern.hasMatch(text.toLowerCase())) return null;
    return _runStreamedVoiceTurn(text, route);
  }

  Stream<String> _runStreamedVoiceTurn(String text, AiIntentRoute route) {
    unawaited(_memoryExtraction?.noteSessionActivity(_sessionId));
    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: text,
        timestamp: DateTime.now(),
      ),
    );
    final bubbleId = StableId.generate('msg');
    _addMessage(
      AiChatMessage(
        id: bubbleId,
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      ),
    );
    _setLoading(true);
    _demoteCurrentPlan();
    _logEvent('aiCommandSubmitted', {
      'sessionId': _sessionId,
      'inputLength': text.length,
    });

    final buffer = StringBuffer();
    var settled = false;
    // The source's done/cancel events must not close [out] while the agent
    // fallback still owes it the reply — the error arrives first, the
    // source's trailing done right behind it.
    var fallingBack = false;
    StreamSubscription<String>? sub;
    late final StreamController<String> out;

    // Finalize the live bubble with whatever arrived (full reply, or the
    // partial text on interrupt/mid-stream error — the partial IS what was
    // spoken, so the thread stays honest about it).
    void settle() {
      if (settled) return;
      settled = true;
      final full = buffer.toString().trim();
      if (full.isEmpty) {
        _removeMessage(bubbleId);
      } else {
        final message = AiInformationalOutputGuard.sanitize(full);
        _replaceLoadingMessage(bubbleId, message);
        unawaited(
          _historyRepository.save(
            sessionId: _sessionId,
            userInput: text,
            parsedActions: const [],
            assistantSummary: message,
            responseType: AiResponseType.informational.name,
          ),
        );
        _logEvent('aiInformationalAnswer', {
          'sessionId': _sessionId,
          'responseType': AiResponseType.informational.name,
        });
      }
      _setLoading(false);
    }

    // Nothing arrived (offline, auth, server error): the agent path is the
    // safety net — it renders its own bubbles and produces honest error copy
    // as a reply, which we hand to the voice loop as one chunk.
    Future<void> fallBackToAgentPath() async {
      settled = true;
      fallingBack = true;
      _removeMessage(bubbleId);
      _setLoading(false);
      try {
        await _parseAndRespond(text, voiceMode: true);
      } catch (_) {}
      final reply = latestSpokenReplyText();
      if (!out.isClosed) {
        if (reply != null && reply.isNotEmpty) out.add(reply);
        await out.close();
      }
    }

    out = StreamController<String>(
      onListen: () {
        sub = _voiceReplyStreamer!(
          text,
          _sessionId,
          route: route,
          proactiveContext: _proactiveContextForPayload,
        ).listen(
          (delta) {
            buffer.write(delta);
            _replaceLoadingMessage(bubbleId, buffer.toString());
            notifyListeners();
            if (!out.isClosed) out.add(delta);
          },
          onError: (Object e) {
            if (buffer.isEmpty && !settled) {
              unawaited(fallBackToAgentPath());
              return;
            }
            settle();
            if (!out.isClosed) {
              out.addError(e);
              unawaited(out.close());
            }
          },
          onDone: () {
            if (fallingBack) return;
            settle();
            if (!out.isClosed) unawaited(out.close());
          },
        );
      },
      onCancel: () {
        // Interrupt: the voice pipeline dropped the stream — abort the HTTP
        // request upstream and keep the partial text as the reply.
        final s = sub;
        sub = null;
        if (s != null) unawaited(s.cancel());
        settle();
      },
    );
    return out.stream;
  }

  /// The text a voice turn should speak for the latest assistant bubble.
  /// Used by the streamed turn's fallback and by the Voice Mode buffered
  /// path.
  ///
  /// On the orb-only stage the preview card is invisible, so the voice IS
  /// the preview (confirm-by-voice, 2026-08-21): a pending plan is read
  /// aloud and closed with a confirm question — the spoken "confirm" that
  /// follows is the user pressing the button, in the modality they're in.
  String? latestSpokenReplyText() {
    for (final message in _messages.reversed) {
      if (message.role != ChatRole.assistant || message.isLoading) continue;
      final content = message.content.trim();

      // Preview awaiting confirmation: model one-liner (when it adds
      // something the summary doesn't), then the plan, then the ask.
      if (message.plannedChanges != null && message.isCurrentPlan) {
        final summary = formatPlanForSpeech(message.plannedChanges!);
        return [
          if (content.isNotEmpty && content != "Here's what I'll do:")
            content,
          if (summary.isNotEmpty) summary,
          'Should I go ahead? Just say confirm — or no.',
        ].join(' ');
      }

      // Suggested draft: the narrative already describes the plan; add the
      // voice affordance the screen button provides.
      if (message.hasDraftPlan) {
        return [
          if (content.isNotEmpty) content,
          'Want me to set it up? Just say confirm.',
        ].join(' ');
      }

      if (content.isNotEmpty) return content;
      if (message.plannedChanges != null) {
        return 'I put a plan together — take a look and confirm on screen.';
      }
      return null;
    }
    return null;
  }

  /// Executes createIntention actions immediately (no preview card) and
  /// appends one assistant bubble with inline [View] [Undo] affordances
  /// ([AiChatMessage.autoCommittedBatchId]). Frictionless capture,
  /// PRD §4.2 — errors surface honestly, per-item, Telegram-style.
  Future<void> _autoCommitIntentionActions(
    List<AiAction> actions, {
    String? modelMessage,
  }) async {
    _pendingPlan = null;
    ExecutionResult exec;
    try {
      exec = await _actionExecutor.execute(actions);
    } catch (e) {
      exec = ExecutionResult(failures: [e.toString()]);
    }
    final trimmedModel = modelMessage?.trim();
    final isMemoryBatch = actions.every(
      (a) =>
          a.actionType == ActionType.rememberFact ||
          a.actionType == ActionType.updateFact ||
          a.actionType == ActionType.forgetFact,
    );
    final content = exec.hasFailures
        ? (isMemoryBatch
              ? exec.toSummaryMessage()
              : "I couldn't save that promise — please try again.")
        : (trimmedModel?.isNotEmpty == true
              ? trimmedModel!
              : exec.toSummaryMessage());
    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: content.isEmpty ? 'Got it — consider it on my radar.' : content,
        timestamp: DateTime.now(),
        autoCommittedBatchId: exec.hasFailures ? null : exec.batchId,
        isExecuted: !exec.hasFailures,
      ),
    );
    _logEvent('aiIntentionAutoCommitted', {
      'sessionId': _sessionId,
      'actionCount': actions.length,
      'failed': exec.hasFailures,
    });
    notifyListeners();
  }

  /// Inline Undo on an auto-committed intention message: tombstones the
  /// created intention(s), cancels their nudges, and rewrites the bubble.
  Future<void> undoAutoCommittedBatch(String messageId, String batchId) async {
    final result = await _actionExecutor.undoBatchById(batchId);
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (result is UndoNotAvailable) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content: result.reason,
          timestamp: DateTime.now(),
        ),
      );
    } else if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        content: 'Undone.',
        clearAutoCommittedBatchId: true,
        isExecuted: false,
      );
    }
    _logEvent('aiIntentionAutoCommitUndone', {
      'sessionId': _sessionId,
      'available': result is! UndoNotAvailable,
    });
    notifyListeners();
  }

  /// Confirms and executes [planFromCard] when provided (source of truth from the
  /// preview card). Falls back to [_pendingPlan] for backwards compatibility.
  Future<void> confirmPlan([
    AiPlannedChanges? planFromCard,
    String? previewMessageId,
  ]) async {
    final plan = planFromCard ?? _pendingPlan;
    if (plan == null) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content:
              'That plan is no longer active. Send a new request and confirm the latest preview.',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    if (plan.actions.isEmpty) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.assistant,
          content:
              'There is nothing to apply in this plan. Try describing the change again.',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    _setLoading(true);

    final result = await _actionExecutor.execute(plan.actions);

    await _historyRepository.markConfirmed(_sessionId);
    await _historyRepository.markExecuted(_sessionId);

    // Store assistant summary for multi-turn conversationHistory (Phase 3)
    final executionSummary = result.hasFailures
        ? 'Already applied (do not repeat): ${result.successes.join("; ")}. Issues: ${result.failures.take(2).join("; ")}'
        : result.successes.isNotEmpty
        ? 'Already applied (do not repeat): ${result.successes.join("; ")}'
        : 'Already applied (do not repeat): Done';
    unawaited(
      _historyRepository.saveAssistantSummary(_sessionId, executionSummary),
    );

    // Seed resolvedCategory from the primary action for the Assumption Engine
    final primary = plan.actions.isNotEmpty ? plan.actions.first : null;
    if (primary != null) {
      final rawTitle =
          primary.parameters['title']?.toString() ??
          primary.parameters['taskTitle']?.toString() ??
          '';
      if (rawTitle.isNotEmpty) {
        final category = _normaliser.normalise(rawTitle);
        unawaited(
          _historyRepository.updateResolvedCategory(_sessionId, category),
        );
      }
    }

    _pendingPlan = null;
    _markPlanExecuted(previewMessageId, plan.sessionId);
    _demoteCurrentPlan();
    _setLoading(false);

    final summary = result.hasFailures
        ? 'Done with some issues:\n${result.toSummaryMessage()}'
        : result.successes.isNotEmpty
        ? result.toSummaryMessage()
        : 'No changes were applied. Try describing a specific task to add or update.';

    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: summary,
        timestamp: DateTime.now(),
      ),
    );

    _logEvent('aiCommandExecuted', {
      'sessionId': _sessionId,
      'actionCount': plan.actions.length,
      'actionTypes': plan.actions.map((a) => a.actionType.name).toList(),
    });
    _recordProactiveChatConversion();
    _onScheduleMutated?.call(_sessionId);

    // Log aiSuggestionAccepted for every action that had a reason label
    for (final action in plan.actions) {
      if (action.reasonLabel != null) {
        final rawTitle =
            action.parameters['title']?.toString() ??
            action.parameters['taskTitle']?.toString() ??
            '';
        final category = rawTitle.isNotEmpty
            ? _normaliser.normalise(rawTitle)
            : 'unknown';
        _logEvent('aiSuggestionAccepted', {
          'sessionId': _sessionId,
          'category': category,
          'confidence': action.confidence,
        });
      }
    }

    notifyListeners();
  }

  void applySuggestedPlan(String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final message = _messages[idx];
    final plan = message.draftPlan;
    if (plan == null || plan.actions.isEmpty) return;

    _demoteCurrentPlan();
    _pendingPlan = plan;
    _messages[idx] = message.copyWith(
      clearDraftPlan: true,
      plannedChanges: plan,
      isCurrentPlan: true,
    );

    _logEvent('aiSuggestPlanApplied', {
      'sessionId': _sessionId,
      'actionCount': plan.actions.length,
    });
    _recordProactiveChatConversion();

    notifyListeners();
  }

  void cancelPlan() {
    _refiningPendingPlan = false;
    _pendingClarification = null;
    _pendingPlan = null;
    // The rejected preview must become inert — leaving its Confirm button
    // live kept a cancelled delete-plan one accidental tap from executing
    // (2026-08-22 bug batch).
    _markCurrentPlanCancelled();
    _demoteCurrentPlan();

    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content:
            'Plan cancelled. Let me know if you\'d like to try something else.',
        timestamp: DateTime.now(),
      ),
    );

    _logEvent('aiCommandCanceled', {'sessionId': _sessionId});

    notifyListeners();
  }

  /// [focusInput] pops the keyboard for the typed refinement — Voice Mode
  /// passes false and prompts by voice instead (the refinement arrives
  /// through the same send path either way).
  void editPlan({bool focusInput = true}) {
    _refiningPendingPlan = true;
    // Log rejection for any action that had an assumption-based reason label
    if (_pendingPlan != null) {
      for (final action in _pendingPlan!.actions) {
        if (action.reasonLabel != null) {
          final rawTitle =
              action.parameters['title']?.toString() ??
              action.parameters['taskTitle']?.toString() ??
              '';
          final category = rawTitle.isNotEmpty
              ? _normaliser.normalise(rawTitle)
              : 'unknown';
          _logEvent('aiSuggestionRejected', {
            'sessionId': _sessionId,
            'category': category,
          });
        }
      }
    }
    // Keep plan visible (read-only card) and focus the input field
    if (focusInput) _inputFocusRequested = true;
    notifyListeners();
  }

  void clearInputFocusRequest() {
    _inputFocusRequested = false;
    // No notifyListeners needed — UI calls this after acting on it
  }

  void startNewSession() {
    // The old session visibly ended — extract its memory now (best-effort;
    // failures stay pending and the bootstrap sweep retries).
    final endedSessionId = _sessionId;
    unawaited(_memoryExtraction?.onSessionEnded(endedSessionId));
    _sessionId = StableId.generate('session');
    _messages.clear();
    _pendingPlan = null;
    _pendingClarification = null;
    _isLoading = false;
    _inputFocusRequested = false;
    _proactiveSuggestionId = null;
    _proactiveSuggestionType = null;
    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static final _rejectionPattern = RegExp(
    r'^(n+o+(pe|o*)?|nah+|cancel( that| it)?|stop|never ?mind|'
    r'no,?\s*thanks?( you)?|no,?\s*thank you|not now|'
    r"no,?\s*(that'?s|that is) (it|all|enough)|"
    r"don'?t|forget it)[.!]*$",
  );

  /// Broader than [_rejectionPattern]: closers that decline a SUGGESTION
  /// ("that's it", "I'm good", "nothing else"). Kept separate because a
  /// bare "that's all" while a plan awaits confirmation is ambiguous, but
  /// as a reply to "anything else?" it clearly means "no".
  static final _suggestionDeclinePattern = RegExp(
    r"^((that'?s|that is) (it|all|enough)|nothing( else| more)?|"
    r"i'?m (good|fine|ok(ay)?|set)|(we|you)'?re good|all good|"
    r'no more|maybe later|not today)[.!]*$',
  );

  /// True when [input] is a short polite decline — of a pending plan, a
  /// suggestion, or an "anything else?" style question.
  static bool _isDecline(String normalized) =>
      _rejectionPattern.hasMatch(normalized) ||
      _suggestionDeclinePattern.hasMatch(normalized);

  static final _affirmationPattern = RegExp(
    r'^(y+e+s+|yes please|ye[ap]h?|yep|sure|ok(ay)?|'
    r'confirm(ed)?( it| this| the plan)?|yes,? confirm|apply( it| this)?|'
    r'do it|go ahead|go for it|sounds? good|please do|perfect|great|love it|'
    r'looks good|'
    r"(it|that|this)('?s| is) (all )?(good|great|fine|perfect)|as it is|"
    r'(schedule|do) (it )?as (you )?suggested)[.!]*$',
  );

  /// Handles a short yes/no-style reply while a plan is pending.
  /// Returns true when the reply was consumed (confirmed or cancelled).
  /// Typed affirmation while the latest assistant message carries an
  /// un-adopted draft plan → adopt it and run the normal confirm flow.
  Future<bool> _tryConfirmLatestDraftOnAffirmation(String input) async {
    final normalized = input.toLowerCase().trim();
    if (normalized.split(RegExp(r'\s+')).length > 4) return false;
    if (!_affirmationPattern.hasMatch(normalized)) return false;

    // The draft must be the most recent assistant turn — never adopt a plan
    // the conversation has already moved past.
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.role != ChatRole.assistant) continue;
      final plan = m.draftPlan;
      if (plan == null || plan.actions.isEmpty) return false;
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.user,
          content: input,
          timestamp: DateTime.now(),
        ),
      );
      applySuggestedPlan(m.id);
      // Awaited: the caller (typed AND voice) reports the OUTCOME of the
      // execution, not the moment it was kicked off. Local-first, so this
      // is milliseconds.
      await confirmPlan();
      return true;
    }
    return false;
  }

  /// Consumes a standalone decline (no plan pending): appends the user turn,
  /// drops any parked suggestion, and answers with a warm closer — all
  /// local, no model round-trip. Returns true when consumed.
  bool _handleStandaloneDecline(String input) {
    final normalized = input.toLowerCase().trim();
    if (normalized.split(RegExp(r'\s+')).length > 4) return false;
    if (!_isDecline(normalized)) return false;
    _pendingClarification = null;
    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: input,
        timestamp: DateTime.now(),
      ),
    );
    _addMessage(
      AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content:
            'Alright! If you change your mind or need anything later, just '
            'let me know.',
        timestamp: DateTime.now(),
      ),
    );
    _logEvent('aiSuggestionDeclined', {'sessionId': _sessionId});
    notifyListeners();
    return true;
  }

  Future<bool> _handlePendingPlanShortReply(String input) async {
    final normalized = input.toLowerCase().trim();
    // Only intercept short replies — full sentences go to the parser.
    if (normalized.split(RegExp(r'\s+')).length > 4) return false;

    if (_rejectionPattern.hasMatch(normalized)) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.user,
          content: input,
          timestamp: DateTime.now(),
        ),
      );
      cancelPlan();
      return true;
    }

    if (_affirmationPattern.hasMatch(normalized)) {
      _addMessage(
        AiChatMessage(
          id: StableId.generate('msg'),
          role: ChatRole.user,
          content: input,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      // Awaited for the same outcome-reporting reason as the draft path.
      await confirmPlan();
      return true;
    }

    return false;
  }

  void _addMessage(AiChatMessage msg) {
    _messages.add(msg);
  }

  void _removeMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
  }

  void _replaceLoadingMessage(String id, String content) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(
      content: content,
      isLoading: false,
    );
  }

  /// Stamps the live preview card(s) cancelled so they render inert.
  void _markCurrentPlanCancelled() {
    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.plannedChanges != null && msg.isCurrentPlan && !msg.isExecuted) {
        _messages[i] = msg.copyWith(isCurrentPlan: false, isCancelled: true);
      }
    }
  }

  void _demoteCurrentPlan() {
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].isCurrentPlan) {
        _messages[i] = _messages[i].copyWith(isCurrentPlan: false);
      }
    }
  }

  void _markPlanExecuted(String? previewMessageId, String sessionId) {
    if (previewMessageId != null) {
      final idx = _messages.indexWhere((m) => m.id == previewMessageId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          isCurrentPlan: false,
          isExecuted: true,
        );
        return;
      }
    }
    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.plannedChanges?.sessionId == sessionId && msg.isCurrentPlan) {
        _messages[i] = msg.copyWith(isCurrentPlan: false, isExecuted: true);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _logEvent(String name, [Map<String, dynamic>? props]) {
    unawaited(
      Future.microtask(() => _analyticsLogger?.call(name, props ?? {})),
    );
  }

  String? _assistantSummaryForHistory(AiPlannedChanges result) {
    if (result.requiresFollowUp) {
      // Include the partial plan so the next turn's model context knows what
      // the question was about (titles/times survive even when the visible
      // chat text is just the question).
      if (result.actions.isNotEmpty) {
        return '${result.followUpQuestion} '
            '(pending: ${_compactActionsSummary(result)})';
      }
      return result.followUpQuestion;
    }
    if (result.isInformational || result.isUnsupported) {
      return result.informationalMessage;
    }
    if (result.isSuggest) {
      // The prose alone can lose the concrete times to the history cap; the
      // compact action list keeps them recoverable on the next turn.
      final msg = result.informationalMessage ?? '';
      return result.actions.isEmpty
          ? msg
          : '$msg [Proposed: ${_compactActionsSummary(result)}]';
    }
    if (result.actions.isEmpty) {
      return "I can answer questions about your schedule or help you add and move tasks. "
          "Try asking \"What's my plan for tomorrow?\" or \"Add a workout at 6am tomorrow.\"";
    }
    return _planPreviewSummary(result);
  }

  String _planPreviewSummary(AiPlannedChanges plan) {
    final parts = plan.actions
        .take(4)
        .map((a) {
          final title =
              a.parameters['title']?.toString() ??
              a.parameters['taskTitle']?.toString() ??
              a.actionType.name;
          return '${a.actionType.name}: $title';
        })
        .join('; ');
    return 'Plan preview: $parts';
  }

  /// Compact, lossless-enough action list for model context: keeps titles AND
  /// scheduling params (time/date/duration) that the prose summary can lose.
  String _compactActionsSummary(AiPlannedChanges plan) {
    const keys = [
      'title',
      'taskTitle',
      'time',
      'date',
      'destinationDate',
      'destinationTime',
      'duration',
      'reminderTime',
      'goalTitle',
    ];
    return plan.actions
        .take(6)
        .map((a) {
          final kept = [
            for (final k in keys)
              if ((a.parameters[k]?.toString() ?? '').isNotEmpty)
                '$k=${a.parameters[k]}',
          ].join(', ');
          return kept.isEmpty
              ? a.actionType.name
              : '${a.actionType.name}($kept)';
        })
        .join('; ');
  }

  void _recordProactiveChatConversion() {
    final type = _proactiveSuggestionType;
    if (type == null || type.isEmpty) return;
    ProactiveChatConversionTracker.record(type);
    _logEvent('proactiveSuggestionChatConverted', {
      'sessionId': _sessionId,
      'suggestionId': _proactiveSuggestionId,
      'suggestionType': type,
    });
  }
}
