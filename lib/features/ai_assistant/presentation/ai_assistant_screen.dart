import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ai_assistant_providers.dart';
import '../application/ai_assistant_service.dart';
import '../domain/models/ai_chat_message.dart';
import 'widgets/ai_input_card.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/planned_changes_card.dart';
import 'widgets/quick_directives_row.dart';
import 'widgets/suggested_prompts_section.dart';

/// Optional route arguments for pre-filling the input (e.g. from a proactive
/// suggestion card on Home — see Phase 4).
class CoachRouteArgs {
  const CoachRouteArgs({this.preDraftedText});

  final String? preDraftedText;
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

  @override
  void initState() {
    super.initState();
    // Pre-fill from route arguments (Phase 4 proactive cards)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CoachRouteArgs && args.preDraftedText != null) {
        _inputController.text = args.preDraftedText!;
        _inputFocusNode.requestFocus();
      }
    });
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
      leading: const BackButton(color: Color(0xFFADAAAA)),
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

    return Column(
      children: [
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

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message, required this.service});

  final AiChatMessage message;
  final AiAssistantService service;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return const ThinkingIndicator();

    if (message.hasPreviewCard) {
      return PlannedChangesCard(
        plan: message.plannedChanges!,
        isCurrentPlan: message.isCurrentPlan,
        isLoading: service.isLoading,
        onConfirm: service.confirmPlan,
        onEdit: service.editPlan,
        onCancel: service.cancelPlan,
      );
    }

    if (message.role == ChatRole.user) {
      return UserMessageBubble(content: message.content);
    }

    return AssistantMessageBubble(content: message.content);
  }
}
