import 'dart:async';

import '../../education/presentation/first_time_feature_card.dart';
import '../../education/presentation/help_dot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/utils/date_keys.dart';
import '../application/ai_action_batch_state.dart';
import '../application/ai_assistant_providers.dart';
import '../application/ai_assistant_service.dart';
import '../application/ai_action_executor.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_planned_changes.dart';
import '../../../core/ai/ai_proxy_client.dart';
import '../application/voice_mode_adapters.dart';
import '../application/voice_mode_controller.dart';
import '../application/voice_warmup.dart';
import '../application/voice_tts_resilience.dart';
import '../application/voice_tts_streaming.dart';
import 'widgets/ai_input_card.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/voice_mode_card.dart';
import 'widgets/planned_changes_card.dart';
import 'widgets/proactive_suggestions_coach_panel.dart';
import 'widgets/quick_directives_row.dart';
import '../../../app/application/main_tab_navigation.dart';
import '../../../app/presentation/main_tab_bar_inset.dart';
import '../application/proactive_suggestion_display.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/sync/sync_service.dart';

/// Optional route arguments for pre-filling the input (e.g. from a proactive
/// suggestion card on Home — see Phase 4).
class CoachRouteArgs {
  const CoachRouteArgs({
    this.preDraftedText,
    this.openSuggestionsPanel = false,
    this.proactiveSuggestionId,
    this.proactiveSuggestionType,
    this.autoSendMessage = false,
    this.startVoiceMode = false,
  });

  final String? preDraftedText;

  /// When true, shows the full proactive suggestions list at the top of Coach
  /// (e.g. from Home "See all in Coach").
  final bool openSuggestionsPanel;

  /// Proactive card the user tapped — passed into AI session context.
  final String? proactiveSuggestionId;
  final String? proactiveSuggestionType;

  /// When true, auto-sends a suggest-mode message on Coach open.
  final bool autoSendMessage;

  /// Opens Coach directly in Voice Mode (humanizing Phase 3) — the
  /// programmatic entry the Phase 4 Siri AppIntent will use.
  final bool startVoiceMode;
}

/// Opens Coach AI as the three-stage drag sheet over the current screen —
/// the ONLY Coach presentation since the tab was retired (decision log
/// 2026-07-16). Stages: ask-bar peek (input only, keyboard up) → 60%
/// conversation → full page. Sending from the peek auto-grows to 60%.
///
/// [askBar] starts at the peek (the coach FAB path: tap → type → send).
/// Flows with a payload ([args] — morning brief, proactive cards, help
/// sheet) start at 60% where the payload is visible. The route keeps the
/// '/coach' name for the feedback route tracker.
///
/// Closing the sheet IS the conversation boundary (P1-04): memory
/// extraction runs on the turns just gathered and the session id rotates,
/// so each opening starts a fresh conversation. Without this, the only
/// session end was a 30-minute idle timer INSIDE the sheet — a normal
/// chat-then-close never extracted, and the raw turns raced the purge.
Future<void> showCoachAiSheet(
  BuildContext context, {
  CoachRouteArgs? args,
  bool askBar = false,
}) {
  // Resolve before awaiting the sheet — [context] may be gone by then.
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The DraggableScrollableSheet inside owns all drag/resize/dismiss
    // gestures; the modal's own drag would fight it.
    enableDrag: false,
    backgroundColor: Colors.transparent,
    routeSettings: RouteSettings(
      name: AiAssistantScreen.routeName,
      arguments: args,
    ),
    builder: (_) => _CoachAiSheet(askBar: askBar),
  ).whenComplete(() {
    try {
      // The service is created via the parser future; if it never resolved
      // (sheet closed before AI booted) there is no session to end.
      container.read(resolvedAiAssistantProvider).value?.startNewSession();
    } catch (e) {
      debugPrint('[Coach] session-end extraction skipped: $e');
    }
  });
}

/// Opens Coach with a payload from anywhere — or, when the coach sheet is
/// already the active route (e.g. tapping "see all" INSIDE the sheet),
/// just delivers the args to the live screen instead of stacking a second
/// sheet ([_AiAssistantScreenState] listens to [coachTabArgsProvider]).
void openCoachAi(
  BuildContext context,
  WidgetRef ref, {
  CoachRouteArgs? args,
  bool askBar = false,
}) {
  if (ModalRoute.of(context)?.settings.name == AiAssistantScreen.routeName) {
    if (args != null) {
      ref.read(coachTabArgsProvider.notifier).state = args;
    }
    return;
  }
  showCoachAiSheet(context, args: args, askBar: askBar);
}

/// Owns the sheet's [DraggableScrollableController]: three snap stages
/// (peek ask-bar / 60% / full page), dismiss below the peek. Corners
/// square off as the sheet approaches full — the sheet visually becomes
/// a page.
class _CoachAiSheet extends StatefulWidget {
  const _CoachAiSheet({required this.askBar});

  final bool askBar;

  /// Ask-bar peek: grabber + input, the page still visible behind.
  static const peekSize = 0.18;
  static const midSize = 0.6;
  static const minSize = 0.08;
  static const maxSize = 1.0;

  @override
  State<_CoachAiSheet> createState() => _CoachAiSheetState();
}

class _CoachAiSheetState extends State<_CoachAiSheet> {
  final _sheetController = DraggableScrollableController();
  bool _popped = false;

  /// Ask-bar height in PIXELS (grabber header + input card + insets). The
  /// peek must be pixel-anchored: the sheet's fractions apply to the space
  /// LEFT OVER above the keyboard, so a fractional peek collapses to
  /// nothing the moment the keyboard opens (the on-device 132px overflow).
  static const _peekPx = 244.0;

  double? _lastPeekFraction;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _popOnce() {
    if (_popped) return;
    _popped = true;
    Navigator.of(context).pop();
  }

  /// When the keyboard changes the available height, the peek FRACTION
  /// changes too. If the user is sitting at the peek, keep them pinned to
  /// the recomputed one instead of stranding them at a stale fraction.
  void _repinPeek(double peek) {
    final old = _lastPeekFraction;
    _lastPeekFraction = peek;
    if (old == null || (peek - old).abs() < 0.005) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      if ((_sheetController.size - old).abs() < 0.04) {
        _sheetController.jumpTo(peek);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard: lift the whole sheet above it. Plain (non-animated) padding
    // tracks the keyboard frame-by-frame — an animation here lags the
    // inset and paints transient overflows.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight;
          final peek = available <= _peekPx
              ? _CoachAiSheet
                    .maxSize // pathological; let content flex
              : (_peekPx / available).clamp(_CoachAiSheet.peekSize, 0.5);
          _repinPeek(peek);
          return _buildSheet(context, peek);
        },
      ),
    );
  }

  Widget _buildSheet(BuildContext context, double peek) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if (n.extent <= n.minExtent + 0.005) _popOnce();
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        expand: false,
        initialChildSize: widget.askBar ? peek : _CoachAiSheet.midSize,
        minChildSize: _CoachAiSheet.minSize,
        maxChildSize: _CoachAiSheet.maxSize,
        snap: true,
        snapSizes: [peek, _CoachAiSheet.midSize],
        builder: (context, scrollController) => AnimatedBuilder(
          animation: _sheetController,
          builder: (context, child) {
            // Corners square off over the last stretch toward full page —
            // the sheet reads as BECOMING a page, not covering one.
            final extent = _sheetController.isAttached
                ? _sheetController.size
                : _CoachAiSheet.midSize;
            final t = ((extent - 0.9) / 0.1).clamp(0.0, 1.0);
            final radius = 28.0 * (1 - t);
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
              child: child,
            );
          },
          child: AiAssistantScreen(
            sheetMode: true,
            autofocusInput: widget.askBar,
            sheetPeekFraction: peek,
            sheetScrollController: scrollController,
            sheetController: _sheetController,
            onSheetDismiss: _popOnce,
          ),
        ),
      ),
    );
  }
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({
    super.key,
    this.sheetMode = false,
    this.autofocusInput = false,
    this.sheetPeekFraction,
    this.sheetScrollController,
    this.sheetController,
    this.onSheetDismiss,
  });

  static const routeName = '/coach';

  /// True when presented via [showCoachAiSheet]: slim grabber header instead
  /// of the AppBar, and the message list drives the sheet's drag-resize.
  final bool sheetMode;

  /// Ask-bar opening (peek stage): focus the input immediately — the whole
  /// point of the peek is tap → type → send without leaving the page.
  final bool autofocusInput;

  /// The CURRENT peek fraction (pixel-anchored, so it changes with the
  /// keyboard). Stage-snapping in the grabber uses this, not a constant.
  final double? sheetPeekFraction;

  /// The [DraggableScrollableSheet]-provided controller (sheet mode only).
  final ScrollController? sheetScrollController;

  /// Lets the slim header translate its drags into sheet resizes.
  final DraggableScrollableController? sheetController;

  /// Closes the sheet (header drag past the dismiss threshold).
  final VoidCallback? onSheetDismiss;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _openSuggestionsPanel = false;
  String? _pendingAutoSendMessage;
  ({String id, String? type})? _pendingProactiveContext;
  bool _autoSendHandled = false;

  /// Non-null while Voice Mode owns the composer (humanizing Phase 3).
  VoiceModeController? _voiceController;
  bool _pendingStartVoiceMode = false;

  /// True while Voice Mode presents as the full-screen stage (orb only,
  /// no transcript). Dragging the sheet down (or the chevron) demotes to
  /// the compact card — the voice loop keeps running either way.
  bool _voiceImmersive = false;

  /// Demotion guard: only leave immersive after the sheet actually REACHED
  /// full — otherwise the snap-to-full animation itself (which passes
  /// through sub-full extents) would immediately kick us out.
  bool _voiceReachedFull = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCoachLaunchArgs(ModalRoute.of(context)?.settings.arguments);
      final pending = ref.read(coachTabArgsProvider);
      if (pending != null) {
        _applyCoachLaunchArgs(pending);
        ref.read(coachTabArgsProvider.notifier).state = null;
      }
      if (widget.autofocusInput) _inputFocusNode.requestFocus();
    });
  }

  /// The ask-bar peek is ONLY for empty-handed quick asks. Whenever there
  /// are messages to show — the sheet opened onto an existing conversation,
  /// the user sent something, or an AI reply landed — the sheet rises to
  /// the stage the CONTENT needs (decision log 2026-07-17):
  ///   fits the 60% viewport → 60%; overflows it → full page.
  /// Fires only on message events, only ever rises, and a manual drag in
  /// between is respected until the next message.
  Future<void> _growSheetForMessages() async {
    if (!widget.sheetMode) return;
    final sheet = widget.sheetController;
    if (sheet == null) return;
    if (!sheet.isAttached) {
      // First frame of an opening: the controller attaches after layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _growSheetForMessages();
      });
      return;
    }
    if (sheet.size < _CoachAiSheet.midSize - 0.05) {
      await sheet.animateTo(
        _CoachAiSheet.midSize,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    // Measure AFTER the 60% stage has laid out: does the thread overflow
    // its viewport? Then 60% would just mean cramped scrolling — continue
    // to full in the same motion. Re-measured over a few frames
    // (2026-08-25): the thread is a lazy ListView, so the very first
    // post-frame extent is an estimate that under-reported long replies
    // and the sheet never grew past 60%.
    _expandToFullIfOverflowing();
  }

  void _expandToFullIfOverflowing([int attempt = 0]) {
    final sheet = widget.sheetController;
    if (sheet == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !sheet.isAttached) return;
      if (sheet.size >= _CoachAiSheet.maxSize - 0.05) return; // already full
      // The user dragged down while we animated — their position wins
      // until the next message event.
      if (sheet.size < _CoachAiSheet.midSize - 0.06) return;
      final scroll = _activeScrollController;
      if (scroll.hasClients &&
          // Small tolerance: a few overflowing pixels aren't "a long chat".
          scroll.position.maxScrollExtent > 32) {
        sheet.animateTo(
          _CoachAiSheet.maxSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (attempt < 4) _expandToFullIfOverflowing(attempt + 1);
    });
  }

  AiAssistantService? _listenedService;
  int _seenMessageCount = 0;
  String _seenLastMessageSignature = '';
  DateTime _lastContentGrowAt = DateTime.fromMillisecondsSinceEpoch(0);

  String _lastMessageSignature(AiAssistantService service) {
    final messages = service.messages;
    if (messages.isEmpty) return '';
    final last = messages.last;
    return '${last.id}:${last.content.length}';
  }

  /// One growth mechanism for every message source: watch the service and
  /// grow when the thread gains a message (user send, auto-send, AI reply).
  /// On first attach, an already-non-empty thread grows immediately — the
  /// peek must never hide an existing conversation (on-device report).
  void _attachServiceListener(AiAssistantService service) {
    if (identical(_listenedService, service)) return;
    _listenedService?.removeListener(_onServiceMessagesChanged);
    _listenedService = service;
    _seenMessageCount = service.messages.length;
    _seenLastMessageSignature = _lastMessageSignature(service);
    service.addListener(_onServiceMessagesChanged);
    if (service.messages.isNotEmpty) {
      if (widget.sheetMode) _growSheetForMessages();
      _scrollToBottom();
    }
  }

  void _onServiceMessagesChanged() {
    final service = _listenedService;
    if (service == null || !mounted) return;
    final count = service.messages.length;
    final signature = _lastMessageSignature(service);
    final grew = count > _seenMessageCount;
    // The count is NOT the whole story (2026-08-25 regression): a reply
    // replaces its loading bubble in place (remove + add, same count), and
    // streamed replies rewrite one bubble token by token — the sheet never
    // re-measured and stayed cramped at 60% for long answers.
    final contentChanged = !grew && signature != _seenLastMessageSignature;
    _seenMessageCount = count;
    _seenLastMessageSignature = signature;
    if (grew) {
      // A new message resets any deliberate park — the user asked for more.
      _userParkedSheet = false;
      _growSheetForMessages();
      _scrollToBottom();
      return;
    }
    if (contentChanged) {
      // Streaming follows the tail only if the reader is already there
      // (§8 U3) — never yank someone who scrolled up to reread.
      _scrollToBottom(onlyIfNearBottom: true);
      // A manual drag mid-stream is a deliberate park (§8 U9): content
      // ticks stop resizing the sheet until the next real message.
      if (_userParkedSheet) return;
      // Throttled: streaming fires this per token batch.
      final now = DateTime.now();
      if (now.difference(_lastContentGrowAt) <
          const Duration(milliseconds: 350)) {
        return;
      }
      _lastContentGrowAt = now;
      _growSheetForMessages();
    }
  }

  /// True after a manual header drag while a reply is in flight — content
  /// growth stops fighting the chosen extent until the next message (§8 U9).
  bool _userParkedSheet = false;

  void _applyCoachLaunchArgs(Object? args) {
    ref.read(coachLastOpenedDateKeyProvider.notifier).state =
        DateKeys.todayKey();
    if (args is! CoachRouteArgs) return;
    setState(() {
      _openSuggestionsPanel = args.openSuggestionsPanel;
    });
    if (args.preDraftedText != null) {
      _inputController.text = args.preDraftedText!;
      if (!args.autoSendMessage) {
        _inputFocusNode.requestFocus();
      }
    }
    if (args.proactiveSuggestionId != null) {
      _pendingProactiveContext = (
        id: args.proactiveSuggestionId!,
        type: args.proactiveSuggestionType,
      );
    }
    if (args.autoSendMessage && args.preDraftedText != null) {
      _pendingAutoSendMessage = 'Help me with: ${args.preDraftedText}';
      _autoSendHandled = false;
    }
    if (args.startVoiceMode) {
      _pendingStartVoiceMode = true;
    }
  }

  void _handlePendingCoachLaunch(AiAssistantService service) {
    final proactive = _pendingProactiveContext;
    if (proactive != null) {
      service.setProactiveContext(
        suggestionId: proactive.id,
        suggestionType: proactive.type,
      );
      _pendingProactiveContext = null;
    }

    final autoMessage = _pendingAutoSendMessage;
    if (!_autoSendHandled && autoMessage != null) {
      _autoSendHandled = true;
      _pendingAutoSendMessage = null;
      // Post-frame (fix-wave Phase 7, §8 R7): this method runs during
      // build, and sendMessage reaches notifyListeners synchronously on
      // the guest branch — a setState-during-build crash armed the moment
      // the suggestions panel came back (U2).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) service.sendMessage(autoMessage);
      });
    }

    if (_pendingStartVoiceMode) {
      _pendingStartVoiceMode = false;
      // Post-frame: _handlePendingCoachLaunch runs during build and
      // _enterVoiceMode calls setState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterVoiceMode(service, externalLaunch: true);
      });
    }
  }

  // ─── Voice Mode (humanizing Phase 3) ──────────────────────────────────────

  /// Streaming-TTS spike flag (latency batch 2, 2026-08-08): true = play
  /// OpenAI audio as it streams from aiSpeechStream (time-to-first-audio
  /// ≈ network + first chunks); false = the buffered aiSpeech callable
  /// path. Kept as a flag so before/after [voice-timing] numbers come
  /// from the same build. Remove once the spike gate passes.
  static const bool _kStreamingTts = true;

  /// Voice Level 2 flag: stream conversational replies through aiChatStream
  /// and speak them sentence-pipelined as they generate. Off = every turn
  /// takes the buffered agent path. Kept as a flag for before/after
  /// [voice-timing] comparison, same discipline as [_kStreamingTts].
  static const bool _kStreamingChat = true;

  /// Swaps the composer for the Voice Mode orb and starts the
  /// listen → send → speak → relisten loop.
  ///
  /// [externalLaunch] marks entries where something else foregrounded the
  /// app (Siri "Talk to SidePal"): Siri's audio session is still releasing
  /// when we arrive, so the first mic open waits a beat — opening into
  /// Siri's session yields a recognizer that hears nothing forever.
  void _enterVoiceMode(
    AiAssistantService service, {
    bool externalLaunch = false,
  }) {
    if (_voiceController != null) return;
    dismissKeyboard(context);
    // First-turn latency: warm the auth cache, TLS pool, and function
    // instances NOW, while the user is still raising the phone — the first
    // utterance is seconds away and would otherwise pay every cold cost.
    final projectId = Firebase.app().options.projectId;
    unawaited(
      warmVoiceEndpoints(
        endpoints: [
          Uri.parse(
            'https://us-central1-$projectId.cloudfunctions.net/aiChatStream',
          ),
          Uri.parse(
            'https://us-central1-$projectId.cloudfunctions.net/aiSpeechStream',
          ),
        ],
        idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
      ),
    );
    // Coach voice: OpenAI TTS (streamed or buffered per the spike flag),
    // degrading silently to the on-device system voice when the network
    // can't deliver — the loop itself never stalls.
    final proxy = AiProxyClient();
    final VoiceTtsAdapter primary;
    if (_kStreamingTts) {
      primary = StreamingOpenAiTtsVoiceAdapter(
        endpoint: Uri.parse(
          'https://us-central1-$projectId'
          '.cloudfunctions.net/aiSpeechStream',
        ),
        idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
      );
    } else {
      primary = OpenAiTtsVoiceAdapter(
        synthesize: (text) =>
            proxy.speak(text, timeout: const Duration(seconds: 8)),
      );
    }
    final controller = VoiceModeController(
      speech: SpeechToTextVoiceAdapter(),
      tts: ResilientVoiceTtsAdapter(
        primary: primary,
        fallback: FlutterTtsVoiceAdapter(),
      ),
      sendAndGetReply: (text) => _voiceSendAndGetReply(service, text),
      tryStreamReply: _kStreamingChat ? service.tryStreamVoiceReply : null,
    );
    setState(() {
      _voiceController = controller;
      _voiceImmersive = true;
      _voiceReachedFull = false;
    });
    controller.start(
      listenDelay: externalLaunch ? const Duration(milliseconds: 900) : null,
    );
    // Background sync stays off the network while voice is live — pulls
    // and outbox storms were competing with voice turns for bandwidth.
    SyncService.instance.voiceModeActive = true;
    // Full-screen stage (ChatGPT-voice style): snap the sheet to full;
    // dragging down demotes to the compact card via the extent listener.
    widget.sheetController?.addListener(_onSheetExtentChangedForVoice);
    // POST-frame: swapping the body detaches the thread's scroll position,
    // which disposes any in-flight sheet animation (framework behavior) —
    // the snap must start only after the stage's own scrollable attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _snapSheetToFullForVoice();
    });
  }

  void _snapSheetToFullForVoice([int attempt = 0]) {
    if (!_voiceImmersive) return;
    final sheet = widget.sheetController;
    if (sheet == null) return; // non-sheet mode: the body itself is full
    if (!sheet.isAttached) {
      // The stage's scrollable attaches within a frame or two; bounded
      // retry so a pathological detach can never become a per-frame loop.
      if (attempt >= 30) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snapSheetToFullForVoice(attempt + 1);
      });
      return;
    }
    sheet.animateTo(
      _CoachAiSheet.maxSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Grabber/list drags leave immersive once the sheet visibly departs
  /// from full — into the compact card, voice still running.
  void _onSheetExtentChangedForVoice() {
    if (!_voiceImmersive || !mounted) return;
    final sheet = widget.sheetController;
    if (sheet == null || !sheet.isAttached) return;
    final size = sheet.size;
    if (size >= _CoachAiSheet.maxSize - 0.05) {
      _voiceReachedFull = true;
      return;
    }
    if (_voiceReachedFull && size < _CoachAiSheet.maxSize - 0.12) {
      _voiceReachedFull = false;
      setState(() => _voiceImmersive = false);
    }
  }

  /// Chevron / swipe-down on the immersive stage: compact card at 60%.
  void _minimizeVoiceMode() {
    if (!_voiceImmersive) return;
    setState(() => _voiceImmersive = false);
    _voiceReachedFull = false;
    final sheet = widget.sheetController;
    if (sheet != null && sheet.isAttached) {
      sheet.animateTo(
        _CoachAiSheet.midSize,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Expand icon on the compact card: back to the full-screen stage.
  void _expandVoiceMode() {
    if (_voiceController == null || _voiceImmersive) return;
    setState(() {
      _voiceImmersive = true;
      _voiceReachedFull = false;
    });
    // Post-frame for the same client-swap reason as _enterVoiceMode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _snapSheetToFullForVoice();
    });
  }

  Future<void> _exitVoiceMode() async {
    final controller = _voiceController;
    if (controller == null) return;
    widget.sheetController?.removeListener(_onSheetExtentChangedForVoice);
    SyncService.instance.voiceModeActive = false;
    setState(() {
      _voiceController = null;
      _voiceImmersive = false;
    });
    _voiceReachedFull = false;
    await controller.stopAndExit();
    // Stop routing singleton speech events at this session's (now dead)
    // callbacks — the dictation mic may claim them next (§8 V1).
    final speechAdapter = controller.speech;
    if (speechAdapter is SpeechToTextVoiceAdapter) speechAdapter.release();
    controller.dispose();
  }

  Future<void> _exitVoiceModeToType() async {
    await _exitVoiceMode();
    if (mounted) _inputFocusNode.requestFocus();
  }

  /// Edit Plan on the preview card. In Voice Mode the keyboard-focus
  /// affordance is invisible (the button appeared to do nothing) — prompt
  /// by voice instead and let the spoken answer refine the pending plan
  /// through the normal send path.
  void _onEditPlanPressed(AiAssistantService service) {
    final voice = _voiceController;
    if (voice != null && voice.isActive) {
      service.editPlan(focusInput: false);
      unawaited(
        voice.promptAndListen('Okay — what should I change about the plan?'),
      );
      return;
    }
    service.editPlan();
  }

  /// Voice utterances travel the exact same path as typed messages; the
  /// spoken reply is whatever assistant bubble lands — including honest
  /// error copy and the deterministic mock, which TTS reads offline.
  Future<String?> _voiceSendAndGetReply(
    AiAssistantService service,
    String text,
  ) async {
    await service.sendMessage(text, voiceMode: true);
    return service.latestSpokenReplyText();
  }

  @override
  void dispose() {
    _listenedService?.removeListener(_onServiceMessagesChanged);
    widget.sheetController?.removeListener(_onSheetExtentChangedForVoice);
    SyncService.instance.voiceModeActive = false;
    _voiceController?.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// In sheet mode the DraggableScrollableSheet's controller drives the
  /// message list so scrolling and sheet-resizing stay coordinated.
  ScrollController get _activeScrollController =>
      widget.sheetScrollController ?? _scrollController;

  /// Scrolls the thread to its end. [onlyIfNearBottom] is the streaming
  /// case (fix-wave Phase 7, §8 U3): content ticks must not yank a reader
  /// who deliberately scrolled up — only follow the tail when they are
  /// already at it.
  void _scrollToBottom({bool onlyIfNearBottom = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _activeScrollController;
      if (!controller.hasClients) return;
      final position = controller.position;
      if (onlyIfNearBottom &&
          position.maxScrollExtent - position.pixels > 220) {
        return;
      }
      controller.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CoachRouteArgs?>(coachTabArgsProvider, (previous, next) {
      if (next == null) return;
      _applyCoachLaunchArgs(next);
      ref.read(coachTabArgsProvider.notifier).state = null;
    });

    final serviceAsync = ref.watch(resolvedAiAssistantProvider);

    final body = serviceAsync.when(
      data: (service) {
        _attachServiceListener(service);
        return _buildBody(service);
      },
      loading: () => _buildLoadingBody(),
      error: (e, _) => _buildErrorBody(e),
    );

    if (widget.sheetMode) {
      // The sheet owns its feedback (fix-wave Phase 7, §8 U5): snackbars
      // used to land on the ROOT messenger under the modal barrier — undo
      // confirmations and the mic-permission error were invisible, so a
      // denied mic tap looked like nothing happened. The keyboard inset is
      // already applied by the sheet wrapper, so the Scaffold must not
      // re-apply it.
      return ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: AppColors.ink,
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              _buildSheetHeader(serviceAsync),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: _buildAppBar(serviceAsync),
      body: body,
    );
  }

  /// Slim sheet chrome: grabber + compact title row. Dragging it resizes the
  /// sheet (DraggableScrollableSheet only reacts to drags on its attached
  /// scrollable, so the header forwards its own).
  Widget _buildSheetHeader(AsyncValue<AiAssistantService> serviceAsync) {
    final sheet = widget.sheetController;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: sheet == null
          ? null
          : (details) {
              _userParkedSheet = true;
              final height = MediaQuery.sizeOf(context).height;
              sheet.jumpTo(
                (sheet.size - details.delta.dy / height).clamp(
                  _CoachAiSheet.minSize,
                  _CoachAiSheet.maxSize,
                ),
              );
            },
      onVerticalDragEnd: sheet == null
          ? null
          : (details) {
              final flingDown = details.velocity.pixelsPerSecond.dy > 700;
              // A fast fling closes; a gentle drag settles on the nearest
              // of the three stages (peek / conversation / full page).
              if (flingDown ||
                  sheet.size <
                      (widget.sheetPeekFraction ?? _CoachAiSheet.peekSize) *
                          0.6) {
                widget.onSheetDismiss?.call();
                return;
              }
              final peek = widget.sheetPeekFraction ?? _CoachAiSheet.peekSize;
              const mid = _CoachAiSheet.midSize;
              const full = _CoachAiSheet.maxSize;
              final size = sheet.size;
              final target = size < (peek + mid) / 2
                  ? peek
                  : size < (mid + full) / 2
                  ? mid
                  : full;
              sheet.animateTo(
                target,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              );
            },
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSoft.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Balances the trailing help button so the title stays centred.
              const SizedBox(width: 40),
              const Spacer(),
              const PageTitle('Coach AI'),
              const SizedBox(width: 8),
              _StatusPill(isReady: serviceAsync.hasValue),
              const Spacer(),
              // The sheet is the only Coach presentation — the help entry
              // lived on the retired tab's AppBar and was unreachable (§8 U2).
              const HelpAppBarButton('coachAi'),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<AiAssistantService> serviceAsync,
  ) {
    final isReady = serviceAsync.hasValue;
    return AppBar(
      backgroundColor: AppColors.ink,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const PageTitle('Coach AI'),
      centerTitle: true,
      actions: [
        const HelpAppBarButton('coachAi'),
        _StatusPill(isReady: isReady),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody(AiAssistantService service) {
    _handlePendingCoachLaunch(service);

    // Full-screen Voice Mode stage: the sheet's full extent shows only the
    // orb — no thread, no composer. Swipe down / chevron → compact card.
    final voice = _voiceController;
    if (voice != null && _voiceImmersive) {
      return VoiceImmersiveStage(
        controller: voice,
        onMinimize: _minimizeVoiceMode,
        onExit: _exitVoiceMode,
        onExitToType: _exitVoiceModeToType,
        // Keeps DraggableScrollableController.isAttached true (it requires
        // a scrollable with clients) — without this the snap-to-full froze
        // mid-flight and every sheet call threw "not attached".
        sheetScrollController: widget.sheetScrollController,
      );
    }

    // Listen to inputFocusRequested
    if (service.inputFocusRequested) {
      service.clearInputFocusRequest();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }

    final messages = service.messages;
    final hasMessages = messages.isNotEmpty;
    // Auto-scroll moved off the build path (§8 U3): the service listener
    // scrolls on real message events; a rebuild alone never yanks the list.

    final showSuggestionsPanel = _shouldShowSuggestionsPanel();

    // Discoverability chrome above the thread. Rendered in the sheet too
    // (fix-wave Phase 7, §8 U2): the old `!sheetMode` gate left the
    // suggestions panel and first-time card unreachable once the Coach tab
    // retired — four live entry points (FAB dot, morning brief, push tap)
    // promised a panel that no longer existed anywhere. The ask-bar peek
    // stays clean: the chrome appears once the sheet is tall enough.
    final hasFreshMessages = messages.any((m) => !m.isHistorical);
    final showRestoreBanner =
        !hasFreshMessages && service.canRestoreConversation;
    final showChrome = !widget.sheetMode || _showComposerExtras;
    final topExtras = <Widget>[
      if (showChrome) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FirstTimeFeatureCard(guideId: 'coachAi'),
        ),
        // Expanded while the chat is empty (suggestions are the
        // content); collapses to the slim header once a conversation
        // is underway so the transcript gets the space.
        if (showSuggestionsPanel)
          ProactiveSuggestionsCoachPanel(
            initiallyExpanded: _openSuggestionsPanel || !hasMessages,
          ),
      ],
      // Accidental-close recovery (fix-wave Phase 7, §8 U1/U10): within
      // 10 minutes of the sheet closing, the stashed thread can come back
      // exactly as it was — same session, plans and all.
      if (showRestoreBanner)
        _RestoreConversationBanner(onRestore: service.restoreConversation)
      // "Pick up where you left off" banner — shown when no active messages
      // and there is a recent unconfirmed plan
      else if (!hasMessages)
        _PickUpBanner(
          historyRepository: service.historyRepository,
          onResume: (input) {
            service.sendMessage(input);
          },
        ),
    ];

    return LayoutBuilder(
      builder: (context, bodyBox) => Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => dismissKeyboard(context),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The extras block is capped so the thread always keeps
                  // ~160px: with the keyboard up (or a short sheet) the extras
                  // scroll inside their cap instead of overflowing the Column.
                  final extrasMaxHeight = (constraints.maxHeight - 160).clamp(
                    0.0,
                    double.infinity,
                  );
                  return Column(
                    children: [
                      if (topExtras.isNotEmpty)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: extrasMaxHeight,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: topExtras,
                            ),
                          ),
                        ),
                      // Conversation thread
                      Expanded(
                        child: hasMessages
                            ? _MessageList(
                                messages: messages,
                                service: service,
                                scrollController: _activeScrollController,
                                isLoading: service.isLoading,
                                onSuggestedPrompt: (prompt) {
                                  _inputController.text = prompt;
                                  _inputFocusNode.requestFocus();
                                },
                                onEditPlan: () => _onEditPlanPressed(service),
                                onStop: service.cancelCurrentTurn,
                              )
                            : _buildEmptyState(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Fixed bottom: input + quick directives. The tab clears the floating
          // nav bar; the sheet only needs the home indicator (keyboard insets
          // are handled by the sheet wrapper lifting the whole sheet).
          // Rebuilds on every sheet-extent tick: the composer extras must
          // re-evaluate as the sheet grows/shrinks, not once per build.
          // The ConstrainedBox + reverse scroll make overflow STRUCTURALLY
          // impossible: if a frame's budget is too small for the composer
          // (keyboard mid-animation, large fonts), it clips from the top
          // instead of striping — the input row is always the visible part.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: bodyBox.maxHeight),
            child: SingleChildScrollView(
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedBuilder(
                animation:
                    widget.sheetController ??
                    const AlwaysStoppedAnimation<double>(0),
                builder: (context, _) => Container(
                  color: AppColors.ink,
                  padding: EdgeInsets.only(
                    bottom: widget.sheetMode
                        ? MediaQuery.paddingOf(context).bottom + 8
                        : mainTabFooterPadding(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_voiceController != null)
                        VoiceModeCard(
                          controller: _voiceController!,
                          onExit: _exitVoiceMode,
                          onExpand: _expandVoiceMode,
                        )
                      else
                        AiInputCard(
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          isLoading: service.isLoading,
                          onSend: () {
                            final text = _inputController.text.trim();
                            if (text.isEmpty) return;
                            _inputController.clear();
                            service.sendMessage(text);
                          },
                          onVoiceModeRequested: () => _enterVoiceMode(service),
                        ),
                      // The ask-bar peek is input-only; the extras appear once
                      // the sheet is PIXEL-tall enough to hold them.
                      if (_voiceController == null && _showComposerExtras) ...[
                        const SizedBox(height: 6),
                        _AiActionBar(service: service),
                        const SizedBox(height: 4),
                        QuickDirectivesRow(
                          onSelected: (text) {
                            _inputController.text = text;
                            _inputFocusNode.requestFocus();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the composer extras (action bar + quick directives) fit.
  /// PIXEL-based, not fraction-based: with the keyboard up even the 60%
  /// stage can be too short for them. Defaults to hidden in sheet mode
  /// until the controller attaches — the first frame must never overflow.
  bool get _showComposerExtras {
    if (!widget.sheetMode) return true;
    final sheet = widget.sheetController;
    if (sheet == null || !sheet.isAttached) return false;
    return sheet.pixels >= _CoachAiSheetState._peekPx + 130;
  }

  /// Empty state. In sheet mode its scrollable attaches to the sheet's
  /// controller (drag-to-resize/dismiss works on it) and the example prompt
  /// chips are hidden — the sheet goes straight to the composer.
  Widget _buildEmptyState() {
    return _EmptyState(
      controller: widget.sheetMode ? _activeScrollController : null,
      showExamples: !widget.sheetMode,
      onPromptSelected: (p) {
        _inputController.text = p;
        _inputFocusNode.requestFocus();
      },
    );
  }

  bool _shouldShowSuggestionsPanel() {
    if (_openSuggestionsPanel) return true;
    final suggestions = ref.watch(proactiveSuggestionsProvider).valueOrNull;
    if (suggestions == null) return false;
    return activeProactiveSuggestions(suggestions).length > 1;
  }

  Widget _buildLoadingBody() {
    // FittedBox: this renders on the FIRST frame of every sheet opening,
    // when the ask-bar peek may give it almost no height — scale down
    // rather than stripe.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Initialising Coach AI…',
              style: TextStyle(color: AppColors.textSoft, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody(Object e) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load Coach AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSoft, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
            const SizedBox(height: 16),
            // A failed boot (offline first open, RC fetch death) used to be
            // a dead end — the only recovery was closing and reopening the
            // sheet (§8 R4's error half).
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(aiOperatingLayerClientProvider);
                ref.invalidate(aiIntentParserProvider);
                ref.invalidate(resolvedAiAssistantProvider);
              },
              icon: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppColors.cyan,
              ),
              label: Text(
                'Try again',
                style: TextStyle(color: AppColors.cyan, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isReady});

  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: isReady
              ? AppColors.cyan.withValues(alpha: 0.4)
              : AppColors.fg.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReady ? AppColors.cyan : AppColors.textFaint,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isReady ? 'READY' : 'LOADING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isReady ? AppColors.cyan : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state (shown before first message) ─────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onPromptSelected,
    this.controller,
    this.showExamples = true,
  });

  final void Function(String) onPromptSelected;

  /// Sheet mode passes the DraggableScrollableSheet controller so dragging
  /// the empty area resizes/dismisses the sheet.
  final ScrollController? controller;

  /// Sheet mode hides the example prompt chips — composer-first.
  final bool showExamples;

  static const _examples = [
    "What's my plan for tomorrow?",
    'Add a workout at 6am',
    'How am I doing on my goals?',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: controller != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ask about your schedule or tell me what to plan.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.fg.withValues(alpha: 0.45),
              ),
            ),
          ),
          if (showExamples) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final example in _examples)
                    ActionChip(
                      label: Text(
                        example,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.inkCard,
                      side: BorderSide(
                        color: AppColors.cyan.withValues(alpha: 0.25),
                      ),
                      onPressed: () => onPromptSelected(example),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.service,
    required this.scrollController,
    required this.isLoading,
    required this.onSuggestedPrompt,
    required this.onEditPlan,
    required this.onStop,
  });

  final List<AiChatMessage> messages;
  final AiAssistantService service;
  final ScrollController scrollController;
  final bool isLoading;
  final void Function(String prompt) onSuggestedPrompt;

  /// Edit Plan on the preview card — voice-aware at the screen level.
  final VoidCallback onEditPlan;

  /// Cancels the in-flight turn (fix-wave Phase 7, §8 U1).
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    // SelectionArea: bubbles are copyable (§8 U8) — long-press selects.
    return SelectionArea(
      child: ListView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == messages.length) {
            // While a turn is in flight the thread ends with a Stop chip —
            // NOT a second ThinkingIndicator: the loading bubble already
            // draws the dots, and the trailing copy was the §8 U4
            // double-indicator.
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: Icon(
                    Icons.stop_rounded,
                    size: 14,
                    color: AppColors.textSoft,
                  ),
                  label: const Text('Stop', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inkCard,
                  side: BorderSide(
                    color: AppColors.textSoft.withValues(alpha: 0.25),
                  ),
                  onPressed: onStop,
                ),
              ),
            );
          }
          final msg = messages[i];
          Widget item = _MessageItem(
            message: msg,
            service: service,
            onSuggestedPrompt: onSuggestedPrompt,
            onEditPlan: onEditPlan,
          );
          // Rehydrated turns read as context, not conversation (§8 U10):
          // dimmed, with a labelled divider before the block and a plain
          // rule where the live conversation resumes.
          if (msg.isHistorical) {
            item = Opacity(opacity: 0.7, child: item);
          }
          final earlierDivider = i == 0 && msg.isHistorical;
          final freshDivider =
              i > 0 && messages[i - 1].isHistorical && !msg.isHistorical;
          if (!earlierDivider && !freshDivider) return item;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (earlierDivider) const _ThreadDivider(label: 'EARLIER TODAY'),
              if (freshDivider) const _ThreadDivider(),
              item,
            ],
          );
        },
      ),
    );
  }
}

/// Thin labelled rule between the rehydrated block and the live thread.
class _ThreadDivider extends StatelessWidget {
  const _ThreadDivider({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final line = Divider(
      height: 1,
      color: AppColors.textFaint.withValues(alpha: 0.25),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: label == null
          ? line
          : Row(
              children: [
                Expanded(child: line),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.textFaint,
                    ),
                  ),
                ),
                Expanded(child: line),
              ],
            ),
    );
  }
}

/// "Restore conversation" banner (fix-wave Phase 7, §8 U1/U10): shown when
/// the previous thread was stashed by an accidental close and the restore
/// window is still open.
class _RestoreConversationBanner extends StatelessWidget {
  const _RestoreConversationBanner({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.restore_rounded, size: 14, color: AppColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your last conversation is still here.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRestore,
            child: Text(
              'Restore',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pick up where you left off banner ───────────────────────────────────────

class _PickUpBanner extends StatefulWidget {
  const _PickUpBanner({
    required this.historyRepository,
    required this.onResume,
  });

  final AiInteractionHistoryRepository historyRepository;
  final void Function(String input) onResume;

  @override
  State<_PickUpBanner> createState() => _PickUpBannerState();
}

class _PickUpBannerState extends State<_PickUpBanner> {
  String? _pendingInput;
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await widget.historyRepository.getMostRecentUnconfirmed(
        withinMinutes: 30,
      );
      if (mounted && entry != null) {
        setState(() {
          _pendingInput = entry.userInput;
          _loaded = true;
        });
      } else if (mounted) {
        setState(() => _loaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed || _pendingInput == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 14, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You had a pending plan — want to continue?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.amber,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.onResume(_pendingInput!);
              setState(() => _dismissed = true);
            },
            child: Text(
              'Resume',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Icon(Icons.close, size: 14, color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}

// ─── Conflict summary banner ──────────────────────────────────────────────────

class _ConflictSummaryBanner extends StatelessWidget {
  const _ConflictSummaryBanner({required this.plan});

  final AiPlannedChanges plan;

  @override
  Widget build(BuildContext context) {
    final blockedCount = plan.blockedByContext.length;
    final conflictCount = plan.conflicts.length;
    final isHard = blockedCount > 0;

    final totalWarnings = blockedCount + conflictCount;
    final label = isHard
        ? '⛔ $blockedCount blocked item${blockedCount > 1 ? 's' : ''}'
              '${conflictCount > 0 ? " + $conflictCount conflict${conflictCount > 1 ? 's' : ''}" : ""}'
              ' — review below.'
        : '⚠ $totalWarnings conflict${totalWarnings > 1 ? 's' : ''} detected — review below before confirming.';

    final bg = isHard
        ? AppColors.danger.withValues(alpha: 0.12)
        : AppColors.amber.withValues(alpha: 0.12);
    final borderColor = isHard
        ? AppColors.danger.withValues(alpha: 0.4)
        : AppColors.amber.withValues(alpha: 0.4);
    final textColor = isHard ? AppColors.danger : AppColors.amber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isHard ? Icons.block_rounded : Icons.warning_amber_rounded,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message item ─────────────────────────────────────────────────────────────

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.message,
    required this.service,
    required this.onSuggestedPrompt,
    required this.onEditPlan,
  });

  final AiChatMessage message;
  final AiAssistantService service;
  final void Function(String prompt) onSuggestedPrompt;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return const ThinkingIndicator();

    if (message.hasPreviewCard) {
      final plan = message.plannedChanges!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.hasAnyWarnings && message.isCurrentPlan)
            _ConflictSummaryBanner(plan: plan),
          PlannedChangesCard(
            plan: plan,
            isCurrentPlan: message.isCurrentPlan,
            isExecuted: message.isExecuted,
            isCancelled: message.isCancelled,
            isLoading: service.isLoading,
            onConfirm: () => service.confirmPlan(plan, message.id),
            onEdit: onEditPlan,
            onCancel: service.cancelPlan,
          ),
          // Timestamp on executed cards (§8 U8): the undo window is
          // 30 minutes, so WHEN it ran is decision-relevant.
          if (message.isExecuted)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Text(
                'Applied '
                '${message.timestamp.hour.toString().padLeft(2, '0')}:'
                '${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: AppColors.textFaint),
              ),
            ),
        ],
      );
    }

    if (message.hasDraftPlan) {
      final draftActions = message.draftPlan!.actions;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssistantMessageBubble(content: message.content),
          // The plan's items, always visible — the model's prose doesn't
          // reliably describe them, and a bare "Apply this plan" button
          // with nothing above it reads as a glitch (2026-08-22).
          if (draftActions.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inkDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final action in draftActions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              Icons.circle,
                              size: 5,
                              color: AppColors.accentDim,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              describePlannedAction(action),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grayBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (message.suggestedPrompts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final prompt in message.suggestedPrompts)
                    ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.inkCard,
                      side: BorderSide(
                        color: AppColors.cyan.withValues(alpha: 0.25),
                      ),
                      onPressed: () => onSuggestedPrompt(prompt),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.isLoading
                    ? null
                    : () => service.applySuggestedPlan(message.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBright,
                  foregroundColor: AppColors.accentDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'APPLY THIS PLAN ▶',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (message.role == ChatRole.user) {
      return UserMessageBubble(content: message.content);
    }

    // Failed turn (fix-wave Phase 3, §8 H1 — the Telegram model's honest
    // half): distinct error treatment + a Retry chip that re-runs the turn
    // quota-free. The old shape was indistinguishable apology prose, and
    // recovery meant retyping the message.
    if (message.isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 48, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.retryInput != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: ActionChip(
                avatar: Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: AppColors.cyan,
                ),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
                backgroundColor: AppColors.inkCard,
                side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.25)),
                onPressed: service.isLoading
                    ? null
                    : () => service.retryTurn(message.id),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssistantMessageBubble(content: message.content),
        // Auto-committed intention (the one confirmless action type):
        // inline [View] [Undo] instead of a preview card.
        if (message.autoCommittedBatchId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inkCard,
                  side: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.25),
                  ),
                  onPressed: () {
                    // Promises live at the top of Home.
                    Navigator.of(context).maybePop();
                    final container = appRootProviderContainer;
                    if (container != null) {
                      navigateToMainTabWithContainer(
                        container,
                        index: MainTabIndex.home,
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Undo', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inkCard,
                  side: BorderSide(
                    color: AppColors.amber.withValues(alpha: 0.35),
                  ),
                  onPressed: () => service.undoAutoCommittedBatch(
                    message.id,
                    message.autoCommittedBatchId!,
                  ),
                ),
              ],
            ),
          ),
        if (message.suggestedPrompts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in message.suggestedPrompts)
                  ActionChip(
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.inkCard,
                    side: BorderSide(
                      color: AppColors.cyan.withValues(alpha: 0.25),
                    ),
                    onPressed: () => onSuggestedPrompt(prompt),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── AI action bar (undo + history) ────────────────────────────────────────────

class _AiActionBar extends ConsumerWidget {
  const _AiActionBar({required this.service});
  final AiAssistantService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndoAsync = ref.watch(canUndoLastAiBatchProvider);
    final recentAsync = ref.watch(recentAiBatchesProvider);
    final recentCount = recentAsync.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (canUndoAsync.valueOrNull == true)
            _UndoChip(onUndo: () => _handleUndo(context, ref)),
          const Spacer(),
          if (recentCount > 0)
            GestureDetector(
              onTap: () => _showHistorySheet(context, ref),
              child: Text(
                'View recent AI changes ($recentCount)',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleUndo(BuildContext context, WidgetRef ref) async {
    await handleAiUndo(context, ref, ref.read(aiActionExecutorProvider));
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    // Captured HERE, inside the coach sheet's ScaffoldMessenger — the
    // history sheet itself mounts on the root navigator, above it.
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AiHistorySheet(
        executor: ref.read(aiActionExecutorProvider),
        messenger: messenger,
      ),
    );
  }
}

/// Shared undo flow for the action bar and the history sheet — one
/// implementation so the two entry points cannot drift.
///
/// Honest ordering (fix-wave Phase 0, §8 E4): when tasks the batch touched
/// were completed since, the executor returns [UndoNeedsConfirmation]
/// WITHOUT rolling back; the dialog's Cancel genuinely cancels, and only
/// "Undo anyway" performs the rollback (forced, targeting that exact batch).
Future<void> handleAiUndo(
  BuildContext context,
  WidgetRef ref,
  AiActionExecutor executor, {
  ScaffoldMessengerState? messenger,
}) async {
  // Chip/count refresh needs no manual invalidation since fix-wave
  // Phase 2: the batch providers are Isar watch streams and emit on every
  // batch write — including the rollback's own state transition.
  // [messenger] lets the history sheet (its own modal route, OUTSIDE the
  // coach sheet's ScaffoldMessenger) still land feedback inside the coach
  // sheet instead of behind the barrier (§8 U5).
  void showSnack(String message) {
    (messenger ?? ScaffoldMessenger.of(context)).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.inkCard),
    );
  }

  final result = await executor.undoLastAiBatch();
  if (!context.mounted) return;

  switch (result) {
    case UndoSuccess():
      showSnack('AI changes have been undone.');

    case UndoFailed():
      showSnack(
        "Couldn't undo — some changes may not have been restored. "
        'Try again.',
      );

    case UndoNeedsConfirmation(:final batchId, :final completedTitles):
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.inkCard,
          title: Text(
            'Some tasks were completed',
            style: TextStyle(color: AppColors.fg),
          ),
          content: Text(
            'The following tasks added by the AI have since been completed. '
            'Undoing will revert those completions:\n\n'
            '${completedTitles.map((t) => '• $t').join('\n')}',
            style: TextStyle(color: AppColors.grayLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Undo anyway',
                style: TextStyle(color: AppColors.cyan),
              ),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (proceed == true) {
        // Force the SAME batch the user was warned about — never whatever
        // happens to be most recent by the time they answered.
        final forced = await executor.undoBatchById(batchId, force: true);
        if (!context.mounted) return;
        showSnack(switch (forced) {
          UndoSuccess() => 'AI changes undone (including completed tasks).',
          UndoFailed() =>
            "Couldn't undo — some changes may not have been restored.",
          UndoNotAvailable(:final reason) => reason,
          UndoNeedsConfirmation() => 'AI changes undone.', // unreachable
        });
      }
    // Cancel keeps the batch untouched and undoable — the watch stream
    // keeps the chip accurate either way.

    case UndoNotAvailable(:final reason):
      showSnack(reason);
  }
}

class _UndoChip extends StatelessWidget {
  const _UndoChip({required this.onUndo});
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUndo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.dark1E2A2A,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyanBorder20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.undo_rounded, color: AppColors.cyan, size: 14),
            SizedBox(width: 6),
            Text(
              'Undo AI changes',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI history bottom sheet ───────────────────────────────────────────────────

class _AiHistorySheet extends ConsumerWidget {
  const _AiHistorySheet({required this.executor, this.messenger});
  final AiActionExecutor executor;

  /// The coach sheet's messenger — undo feedback lands there (§8 U5).
  final ScaffoldMessengerState? messenger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentAiBatchesProvider);
    final canUndoAsync = ref.watch(canUndoLastAiBatchProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textDim,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SectionHeader('Recent AI changes'),
          ),
        ),
        const SizedBox(height: 12),
        recentAsync.when(
          data: (batches) => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batches.length,
            itemBuilder: (ctx, i) {
              final batch = batches[i];
              final isFirst = i == 0;
              final canUndo = isFirst && (canUndoAsync.valueOrNull ?? false);
              return _BatchRow(
                batch: batch,
                canUndo: canUndo,
                onUndo: canUndo
                    ? () async {
                        // One shared flow with the action bar — including
                        // the pre-rollback completed-tasks confirmation.
                        // Runs BEFORE the sheet closes: popping first would
                        // unmount this context and kill the dialog.
                        await handleAiUndo(
                          context,
                          ref,
                          executor,
                          messenger: messenger,
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    : null,
              );
            },
          ),
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppColors.cyan,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch, required this.canUndo, this.onUndo});

  final IsarAiActionBatch batch;
  final bool canUndo;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.fromMillisecondsSinceEpoch(batch.createdAtMs);
    final label =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}  '
        '${ts.day}/${ts.month}';
    final stateColor = _stateColor(batch.state);
    final stateLabel = _stateLabel(batch.state);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppColors.fg, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canUndo)
            TextButton(
              onPressed: onUndo,
              child: Text(
                'Undo',
                style: TextStyle(color: AppColors.cyan, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Color _stateColor(String state) {
    if (state == AiActionBatchState.completed.name) {
      return AppColors.statusGreen;
    }
    if (state == AiActionBatchState.rolledBack.name) {
      return AppColors.statusOrange;
    }
    if (state == AiActionBatchState.partialFailure.name) {
      return AppColors.danger;
    }
    return AppColors.textGray;
  }

  String _stateLabel(String state) {
    if (state == AiActionBatchState.completed.name) return 'Completed';
    if (state == AiActionBatchState.rolledBack.name) return 'Undone';
    if (state == AiActionBatchState.partialFailure.name) {
      return 'Partial failure';
    }
    if (state == AiActionBatchState.executing.name) return 'Executing';
    if (state == AiActionBatchState.pending.name) return 'Pending';
    return state;
  }
}
