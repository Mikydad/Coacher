import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import '../ai_assistant_screen.dart';
import 'proactive_suggestion_card.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Proactive suggestions at the top of the Coach screen.
///
/// Empty chat: the suggestions ARE the content — an expandable list, open
/// by default ([initiallyExpanded]). Conversation underway ([compact],
/// 2026-09-22, Miko): a small card only, never an inline list — the list
/// and the thread fought for the sheet's height and the cards were
/// clipped. Tapping the card (or the "see all in Coach" intent) opens the
/// list as its own sheet over the coach.
class ProactiveSuggestionsCoachPanel extends ConsumerStatefulWidget {
  const ProactiveSuggestionsCoachPanel({
    super.key,
    this.initiallyExpanded = true,
    this.compact = false,
  });

  final bool initiallyExpanded;

  /// True once the thread has messages: render the little card and open
  /// the list in a sheet instead of expanding inline.
  final bool compact;

  @override
  ConsumerState<ProactiveSuggestionsCoachPanel> createState() =>
      _ProactiveSuggestionsCoachPanelState();
}

class _ProactiveSuggestionsCoachPanelState
    extends ConsumerState<ProactiveSuggestionsCoachPanel> {
  static Color get _kAccent => AppColors.accentDim;
  static Color get _kVariant => AppColors.textSoft;

  late bool _expanded = widget.initiallyExpanded;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _honourOpenIntent();
  }

  @override
  void didUpdateWidget(ProactiveSuggestionsCoachPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow intent changes (first message sent → collapse; "see all in
    // Coach" → expand) while still letting the user toggle manually.
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
      _honourOpenIntent();
    }
  }

  /// "See all in Coach" while a conversation is underway: the list opens
  /// as a sheet (never inline). After the frame — this runs from build.
  void _honourOpenIntent() {
    if (!widget.compact || !widget.initiallyExpanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSheet();
    });
  }

  Future<void> _openSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      await showProactiveSuggestionsSheet(context);
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(proactiveSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => swallowedAsyncError(
        'proactive_suggestions_coach_panel',
        e,
        const SizedBox.shrink(),
      ),
      data: (all) {
        final active = activeProactiveSuggestions(all);
        if (active.isEmpty) return const SizedBox.shrink();

        if (widget.compact) return _compactCard(active.length);

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'SUGGESTIONS FOR TODAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                          color: _kVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${active.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: _kVariant,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: active.length == 1 ? 140 : 320,
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: active.length <= 2
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            children: active
                                .map(
                                  (s) => ProactiveSuggestionCard(
                                    key: ValueKey('coach_${s.id}'),
                                    suggestion: s,
                                    onDismiss: () {},
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The little card a live conversation shows instead of the list.
  Widget _compactCard(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Material(
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const ValueKey('coach_suggestions_compact_card'),
          borderRadius: BorderRadius.circular(14),
          onTap: _openSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: _kAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SUGGESTIONS FOR TODAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: _kVariant,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: _kVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The suggestions list as its own sheet over the coach (a live thread
/// never hosts it inline). Watches the provider so a dismissal inside the
/// sheet updates the list — and the compact card's count — at once.
Future<void> showProactiveSuggestionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SuggestionsListSheet(),
  );
}

class _SuggestionsListSheet extends ConsumerWidget {
  const _SuggestionsListSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref
        .watch(proactiveSuggestionsProvider)
        .maybeWhen(data: activeProactiveSuggestions, orElse: () => const []);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    'SUGGESTIONS FOR TODAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: AppColors.textSoft,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${active.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDim,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing left for today.',
                        style: TextStyle(color: AppColors.textSoft),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final s in active)
                          ProactiveSuggestionCard(
                            key: ValueKey('coach_sheet_${s.id}'),
                            suggestion: s,
                            onDismiss: () {},
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link shown on Home when more than one suggestion exists.
class SeeAllSuggestionsInCoachLink extends ConsumerWidget {
  const SeeAllSuggestionsInCoachLink({super.key, required this.remainingCount});

  final int remainingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (remainingCount <= 0) return const SizedBox.shrink();

    final label = remainingCount == 1
        ? 'See 1 more in Coach'
        : 'See all $remainingCount more in Coach';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            openCoachAi(
              context,
              ref,
              args: const CoachRouteArgs(openSuggestionsPanel: true),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentDim,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
