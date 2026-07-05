import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/main_tab_navigation.dart';
import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import '../ai_assistant_screen.dart';
import 'proactive_suggestion_card.dart';

import '../../../../core/presentation/app_colors.dart';

/// Full list of proactive suggestions at the top of the Coach screen.
class ProactiveSuggestionsCoachPanel extends ConsumerWidget {
  const ProactiveSuggestionsCoachPanel({super.key});

  static const _kAccent = AppColors.accentDim;
  static const _kVariant = AppColors.textSoft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(proactiveSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (all) {
        final active = activeProactiveSuggestions(all);
        if (active.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
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
            ],
          ),
        );
      },
    );
  }
}

/// Link shown on Home when more than one suggestion exists.
class SeeAllSuggestionsInCoachLink extends ConsumerWidget {
  const SeeAllSuggestionsInCoachLink({
    super.key,
    required this.remainingCount,
  });

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
