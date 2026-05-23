import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../application/ai_assistant_providers.dart';
import '../application/ai_assistant_service.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_planned_changes.dart';
import 'widgets/ai_input_card.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/planned_changes_card.dart';
import 'widgets/proactive_suggestions_coach_panel.dart';
import 'widgets/quick_directives_row.dart';
import 'widgets/suggested_prompts_section.dart';
import '../../../app/application/main_tab_navigation.dart';
import '../application/proactive_suggestion_display.dart';

/// Optional route arguments for pre-filling the input (e.g. from a proactive
/// suggestion card on Home — see Phase 4).
class CoachRouteArgs {
  const CoachRouteArgs({
    this.preDraftedText,
    this.openSuggestionsPanel = false,
  });

  final String? preDraftedText;

  /// When true, shows the full proactive suggestions list at the top of Coach
  /// (e.g. from Home "See all in Coach").
  final bool openSuggestionsPanel;
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  static const routeName = '/coach';

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _openSuggestionsPanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCoachLaunchArgs(
        ModalRoute.of(context)?.settings.arguments,
      );
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
      _inputFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: _buildAppBar(serviceAsync),
      body: serviceAsync.when(
        data: (service) => _buildBody(service),
        loading: () => _buildLoadingBody(),
        error: (e, _) => _buildErrorBody(e),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<AiAssistantService> serviceAsync,
  ) {
    final isReady = serviceAsync.hasValue;
    return AppBar(
      backgroundColor: const Color(0xFF0E0E0E),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'Coach AI',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        _StatusPill(isReady: isReady),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody(AiAssistantService service) {
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

    return Column(
      children: [
        if (showSuggestionsPanel) const ProactiveSuggestionsCoachPanel(),
        // "Pick up where you left off" banner — shown when no active messages
        // and there is a recent unconfirmed plan
        if (!hasMessages)
          _PickUpBanner(
            historyRepository: service.historyRepository,
            onResume: (input) {
              service.sendMessage(input);
            },
          ),
        // Conversation thread
        Expanded(
          child: hasMessages
              ? _MessageList(
                  messages: messages,
                  service: service,
                  scrollController: _scrollController,
                  isLoading: service.isLoading,
                )
              : _EmptyState(
                  onPromptSelected: (p) {
                    _inputController.text = p;
                    _inputFocusNode.requestFocus();
                  },
                ),
        ),
        // Fixed bottom: input + quick directives
        Container(
          color: const Color(0xFF0E0E0E),
          padding: const EdgeInsets.only(bottom: 12),
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
              const SizedBox(height: 10),
              QuickDirectivesRow(
                onSelected: (text) {
                  _inputController.text = text;
                  _inputFocusNode.requestFocus();
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowSuggestionsPanel() {
    if (_openSuggestionsPanel) return true;
    final suggestions = ref.watch(proactiveSuggestionsProvider).valueOrNull;
    if (suggestions == null) return false;
    return activeProactiveSuggestions(suggestions).length > 1;
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF00E3FD), strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Initialising Coach AI…',
            style: TextStyle(color: Color(0xFFADAAAA), fontSize: 14),
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
          style: const TextStyle(color: Color(0xFFADAAAA), fontSize: 14),
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
              ? const Color(0xFF00E3FD).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
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
              color: isReady ? const Color(0xFF00E3FD) : const Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isReady ? 'READY' : 'LOADING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isReady ? const Color(0xFF00E3FD) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state (shown before first message) ─────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPromptSelected});

  final void Function(String) onPromptSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tell me what you want and I\'ll organise it for you.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SuggestedPromptsSection(onSelected: onPromptSelected),
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
  });

  final List<AiChatMessage> messages;
  final AiAssistantService service;
  final ScrollController scrollController;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == messages.length) {
          // Extra loading indicator at bottom while processing
          return const ThinkingIndicator();
        }
        final msg = messages[i];
        return _MessageItem(message: msg, service: service);
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
        color: const Color(0xFFFFA726).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 14,
            color: Color(0xFFFFA726),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You had a pending plan — want to continue?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFFA726),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.onResume(_pendingInput!);
              setState(() => _dismissed = true);
            },
            child: const Text(
              'Resume',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFA726),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFFADAAAA),
            ),
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
        : const Color(0xFFFFA726).withValues(alpha: 0.12);
    final borderColor = isHard
        ? Colors.redAccent.withValues(alpha: 0.4)
        : const Color(0xFFFFA726).withValues(alpha: 0.4);
    final textColor =
        isHard ? Colors.redAccent : const Color(0xFFFFA726);

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
            isHard
                ? Icons.block_rounded
                : Icons.warning_amber_rounded,
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
  const _MessageItem({required this.message, required this.service});

  final AiChatMessage message;
  final AiAssistantService service;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return const ThinkingIndicator();

    if (message.hasPreviewCard) {
      final plan = message.plannedChanges!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conflict summary banner (shown above the card when there are warnings)
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

    if (message.role == ChatRole.user) {
      return UserMessageBubble(content: message.content);
    }

    return AssistantMessageBubble(content: message.content);
  }
}
