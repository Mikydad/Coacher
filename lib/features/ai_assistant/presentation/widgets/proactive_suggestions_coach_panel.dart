import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/main_tab_navigation.dart';
import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import '../ai_assistant_screen.dart';
import 'proactive_suggestion_card.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Collapsible list of proactive suggestions at the top of the Coach screen.
///
/// Starts expanded when [initiallyExpanded] (the chat is empty, so the
/// suggestions ARE the content) and collapses to a single header row once a
/// conversation is underway — the transcript gets the space back. Tapping the
/// header toggles it any time.
class ProactiveSuggestionsCoachPanel extends ConsumerStatefulWidget {
  const ProactiveSuggestionsCoachPanel({
    super.key,
    this.initiallyExpanded = true,
  });

  final bool initiallyExpanded;

  @override
  ConsumerState<ProactiveSuggestionsCoachPanel> createState() =>
      _ProactiveSuggestionsCoachPanelState();
}

class _ProactiveSuggestionsCoachPanelState
    extends ConsumerState<ProactiveSuggestionsCoachPanel> {
  static Color get _kAccent => AppColors.accentDim;
  static Color get _kVariant => AppColors.textSoft;

  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(ProactiveSuggestionsCoachPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow intent changes (first message sent → collapse; "see all in
    // Coach" → expand) while still letting the user toggle manually.
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
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
            navigateToMainTab(
              context,
              ref,
              index: MainTabIndex.coach,
              coachArgs: const CoachRouteArgs(openSuggestionsPanel: true),
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
