import '../../education/presentation/first_time_feature_card.dart';
import '../../education/presentation/help_dot.dart';
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
import 'widgets/ai_input_card.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/planned_changes_card.dart';
import 'widgets/proactive_suggestions_coach_panel.dart';
import 'widgets/quick_directives_row.dart';
import '../../../app/application/main_tab_navigation.dart';
import '../../../app/presentation/main_tab_bar_inset.dart';
import '../application/proactive_suggestion_display.dart';

import '../../../core/presentation/app_colors.dart';

/// Optional route arguments for pre-filling the input (e.g. from a proactive
/// suggestion card on Home — see Phase 4).
class CoachRouteArgs {
  const CoachRouteArgs({
    this.preDraftedText,
    this.openSuggestionsPanel = false,
    this.proactiveSuggestionId,
    this.proactiveSuggestionType,
    this.autoSendMessage = false,
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
}

/// Opens Coach AI as a drag-expandable modal bottom sheet (~60% height,
/// expandable toward full) over the current screen — quick AI access without
/// leaving the page. The Coach tab remains the full-page presentation;
/// conversation state lives in providers, so both show the same thread.
/// The route keeps the '/coach' name for the feedback route tracker.
Future<void> showCoachAiSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The DraggableScrollableSheet inside owns all drag/resize/dismiss
    // gestures; the modal's own drag would fight it.
    enableDrag: false,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: AiAssistantScreen.routeName),
    builder: (_) => const _CoachAiSheet(),
  );
}

/// Owns the sheet's [DraggableScrollableController]: 60% initial, snaps to
/// 60% / 93%, and pops the route when dragged to the minimum extent.
class _CoachAiSheet extends StatefulWidget {
  const _CoachAiSheet();

  static const initialSize = 0.6;
  static const minSize = 0.32;
  static const maxSize = 0.93;

  @override
  State<_CoachAiSheet> createState() => _CoachAiSheetState();
}

class _CoachAiSheetState extends State<_CoachAiSheet> {
  final _sheetController = DraggableScrollableController();
  bool _popped = false;

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

  @override
  Widget build(BuildContext context) {
    // Keyboard: lift the whole sheet above it — the fractions then apply to
    // the remaining space, so no fixed extent can overflow.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          if (n.extent <= n.minExtent + 0.005) _popOnce();
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          expand: false,
          initialChildSize: _CoachAiSheet.initialSize,
          minChildSize: _CoachAiSheet.minSize,
          maxChildSize: _CoachAiSheet.maxSize,
          snap: true,
          snapSizes: const [_CoachAiSheet.initialSize],
          builder: (context, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AiAssistantScreen(
              sheetMode: true,
              sheetScrollController: scrollController,
              sheetController: _sheetController,
              onSheetDismiss: _popOnce,
            ),
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
    this.sheetScrollController,
    this.sheetController,
    this.onSheetDismiss,
  });

  static const routeName = '/coach';

  /// True when presented via [showCoachAiSheet]: slim grabber header instead
  /// of the AppBar, and the message list drives the sheet's drag-resize.
  final bool sheetMode;

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
    });
  }

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
      service.sendMessage(autoMessage);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// In sheet mode the DraggableScrollableSheet's controller drives the
  /// message list so scrolling and sheet-resizing stay coordinated.
  ScrollController get _activeScrollController =>
      widget.sheetScrollController ?? _scrollController;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _activeScrollController;
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
      data: (service) => _buildBody(service),
      loading: () => _buildLoadingBody(),
      error: (e, _) => _buildErrorBody(e),
    );

    if (widget.sheetMode) {
      return Material(
        color: AppColors.ink,
        child: Column(
          children: [
            _buildSheetHeader(serviceAsync),
            Expanded(child: body),
          ],
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
              if (flingDown || sheet.size < 0.45) {
                widget.onSheetDismiss?.call();
                return;
              }
              final target = sheet.size < 0.75
                  ? _CoachAiSheet.initialSize
                  : _CoachAiSheet.maxSize;
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
              const PageTitle('Coach AI'),
              const SizedBox(width: 8),
              _StatusPill(isReady: serviceAsync.hasValue),
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

    // Listen to inputFocusRequested
    if (service.inputFocusRequested) {
      service.clearInputFocusRequest();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }

    final messages = service.messages;
    final hasMessages = messages.isNotEmpty;

    // Auto-scroll on new messages
    if (hasMessages) _scrollToBottom();

    final showSuggestionsPanel = _shouldShowSuggestionsPanel();

    // Discoverability chrome above the thread. The sheet skips it entirely
    // (quick chat, no cards); the tab keeps it.
    final topExtras = <Widget>[
      if (!widget.sheetMode) ...[
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
      // "Pick up where you left off" banner — shown when no active messages
      // and there is a recent unconfirmed plan
      if (!hasMessages)
        _PickUpBanner(
          historyRepository: service.historyRepository,
          onResume: (input) {
            service.sendMessage(input);
          },
        ),
    ];

    return Column(
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
                        constraints: BoxConstraints(maxHeight: extrasMaxHeight),
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
        Container(
          color: AppColors.ink,
          padding: EdgeInsets.only(
            bottom: widget.sheetMode
                ? MediaQuery.paddingOf(context).bottom + 8
                : mainTabFooterPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ),
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
          ),
        ),
      ],
    );
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
    return Center(
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
    );
  }

  Widget _buildErrorBody(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Could not load Coach AI.\n$e',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSoft, fontSize: 14),
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
  });

  final List<AiChatMessage> messages;
  final AiAssistantService service;
  final ScrollController scrollController;
  final bool isLoading;
  final void Function(String prompt) onSuggestedPrompt;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == messages.length) {
          // Extra loading indicator at bottom while processing
          return const ThinkingIndicator();
        }
        final msg = messages[i];
        return _MessageItem(
          message: msg,
          service: service,
          onSuggestedPrompt: onSuggestedPrompt,
        );
      },
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
        ? Colors.red.withValues(alpha: 0.12)
        : AppColors.amber.withValues(alpha: 0.12);
    final borderColor = isHard
        ? Colors.redAccent.withValues(alpha: 0.4)
        : AppColors.amber.withValues(alpha: 0.4);
    final textColor = isHard ? Colors.redAccent : AppColors.amber;

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
  });

  final AiChatMessage message;
  final AiAssistantService service;
  final void Function(String prompt) onSuggestedPrompt;

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
            isLoading: service.isLoading,
            onConfirm: () => service.confirmPlan(plan, message.id),
            onEdit: service.editPlan,
            onCancel: service.cancelPlan,
          ),
        ],
      );
    }

    if (message.hasDraftPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssistantMessageBubble(content: message.content),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssistantMessageBubble(content: message.content),
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
    final executor = ref.read(aiActionExecutorProvider);
    final result = await executor.undoLastAiBatch();
    if (!context.mounted) return;

    switch (result) {
      case UndoSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI changes have been undone.'),
            backgroundColor: AppColors.inkCard,
          ),
        );
        ref.invalidate(lastAiBatchProvider);
        ref.invalidate(canUndoLastAiBatchProvider);
        ref.invalidate(recentAiBatchesProvider);

      case UndoWarningTasksCompleted(:final completedTitles):
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
        if (proceed == true && context.mounted) {
          // Rollback already happened in undoLastAiBatch for warning case.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI changes undone (including completed tasks).'),
              backgroundColor: AppColors.inkCard,
            ),
          );
          ref.invalidate(lastAiBatchProvider);
          ref.invalidate(canUndoLastAiBatchProvider);
          ref.invalidate(recentAiBatchesProvider);
        }

      case UndoNotAvailable(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason), backgroundColor: AppColors.inkCard),
        );
    }
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          _AiHistorySheet(executor: ref.read(aiActionExecutorProvider)),
    );
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
  const _AiHistorySheet({required this.executor});
  final AiActionExecutor executor;

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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent AI changes',
              style: TextStyle(
                color: AppColors.fg,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                        Navigator.pop(context);
                        // Trigger undo through the outer bar's handler (invalidate is handled there)
                        final result = await executor.undoLastAiBatch();
                        if (!context.mounted) return;
                        final msg = switch (result) {
                          UndoSuccess() => 'AI changes undone.',
                          UndoWarningTasksCompleted() =>
                            'AI changes undone (some completed tasks reverted).',
                          UndoNotAvailable(:final reason) => reason,
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: AppColors.inkCard,
                          ),
                        );
                        ref.invalidate(lastAiBatchProvider);
                        ref.invalidate(canUndoLastAiBatchProvider);
                        ref.invalidate(recentAiBatchesProvider);
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
