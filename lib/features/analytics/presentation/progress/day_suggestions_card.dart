import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';
import '../../../ai_assistant/application/ai_assistant_providers.dart';
import '../../../ai_assistant/application/proactive_suggestion_display.dart';
import '../../../ai_assistant/presentation/widgets/proactive_suggestion_card.dart';
import 'progress_shared_widgets.dart';

/// "Suggestions for today" on the Progress DAY view (2026-09-22, Miko): the
/// coach chat no longer hosts them. Collapsed by default to one line with
/// the count; tap to expand the cards in place. Hidden when nothing is
/// active. The Day view renders it only for today.
class DaySuggestionsCard extends ConsumerStatefulWidget {
  const DaySuggestionsCard({super.key});

  static const headerKey = ValueKey('progress_day_suggestions_header');

  @override
  ConsumerState<DaySuggestionsCard> createState() => _DaySuggestionsCardState();
}

class _DaySuggestionsCardState extends ConsumerState<DaySuggestionsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(proactiveSuggestionsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => swallowedAsyncError(
        'day_suggestions_card',
        e,
        const SizedBox.shrink(),
      ),
      data: (all) {
        final active = activeProactiveSuggestions(all);
        if (active.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ProgressTonalCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  key: DaySuggestionsCard.headerKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.accentDim,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SUGGESTIONS FOR TODAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.9,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ),
                        Text(
                          '${active.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentDim,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: AppColors.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_expanded
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              for (final s in active)
                                ProactiveSuggestionCard(
                                  key: ValueKey('progress_${s.id}'),
                                  suggestion: s,
                                  onDismiss: () {},
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
