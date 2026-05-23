import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import 'proactive_suggestion_card.dart';
import 'proactive_suggestions_coach_panel.dart';

/// Shows the top proactive suggestion on Home, with a link to the full list
/// on the Coach screen when more exist.
class ProactiveSuggestionSection extends ConsumerWidget {
  const ProactiveSuggestionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(proactiveSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const _SkeletonCard(),
      error: (_, _) => const SizedBox.shrink(),
      data: (suggestions) {
        final active = activeProactiveSuggestions(suggestions);
        if (active.isEmpty) return const SizedBox.shrink();

        final onHome = active.take(kHomeProactiveSuggestionLimit).toList();
        final remaining = active.length - onHome.length;

        return Column(
          children: [
            for (final s in onHome)
              ProactiveSuggestionCard(
                key: ValueKey(s.id),
                suggestion: s,
                onDismiss: () {},
              ),
            SeeAllSuggestionsInCoachLink(remainingCount: remaining),
          ],
        );
      },
    );
  }
}

// ─── Skeleton loading card ────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF201f1f),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF3A3A3A),
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBar(width: 180, height: 14),
            const SizedBox(height: 8),
            _shimmerBar(width: 240, height: 11),
            const SizedBox(height: 8),
            _shimmerBar(width: 240, height: 11),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
