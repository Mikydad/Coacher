import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import '../ai_assistant_screen.dart';

/// The omnipresent Coach AI button — one per main tab, always bottom-right.
///
/// Coach is no longer a place you navigate to; it's an assistant at hand
/// (decision log 2026-07-16). Tapping opens the ask-bar peek of the coach
/// sheet: type → send → the sheet grows to show the answer.
///
/// [mini] is the satellite form for tabs that already own a primary FAB
/// (Goals / Community / Accountability): the coach button stacks above the
/// page's own action, same spot on every tab.
///
/// Carries the red "blocked plan" dot that used to sit on the Coach nav
/// icon — now visible from every working tab instead of one nav slot.
class CoachAiFab extends ConsumerWidget {
  const CoachAiFab({super.key, this.mini = false});

  final bool mini;

  static Color get _accent => AppColors.cyan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBlockedPlan =
        ref
            .watch(resolvedAiAssistantProvider)
            .whenOrNull(
              data: (svc) => svc.pendingPlan?.isBlockedByContext == true,
            ) ??
        false;

    // Proactive suggestions moved off Home behind this button (2026-08-23):
    // a quiet accent dot says "the coach has something", and a tap lands on
    // the suggestions panel instead of the bare ask bar.
    final hasSuggestions =
        ref
            .watch(proactiveSuggestionsProvider)
            .whenOrNull(data: (s) => activeProactiveSuggestions(s).isNotEmpty) ??
        false;

    // Long-press = straight into Voice Mode (2026-08-22): the same
    // programmatic entry Siri uses; a plain tap keeps opening typed chat.
    final fab = GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showCoachAiSheet(
          context,
          args: const CoachRouteArgs(startVoiceMode: true),
        );
      },
      child: FloatingActionButton(
        // Multiple instances live in the tab IndexedStack at once — opt out
        // of Hero animation entirely so route transitions never collide.
        heroTag: null,
        mini: mini,
        onPressed: () => showCoachAiSheet(
          context,
          askBar: true,
          args: hasSuggestions
              ? const CoachRouteArgs(openSuggestionsPanel: true)
              : null,
        ),
        elevation: 0,
        highlightElevation: 0,
        splashColor: _accent.withValues(alpha: 0.12),
        backgroundColor: AppColors.inkCard,
        shape: CircleBorder(
          side: BorderSide(color: _accent.withValues(alpha: 0.35)),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: _accent,
          size: mini ? 18 : 22,
        ),
      ),
    );

    if (!hasBlockedPlan && !hasSuggestions) return fab;
    // Red (blocked plan) outranks the accent suggestions dot.
    final dotColor = hasBlockedPlan ? Colors.redAccent : _accent;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        fab,
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

/// Satellite arrangement for tabs that own a primary FAB: mini coach
/// button above, the page's own action below.
class CoachSatelliteFabs extends StatelessWidget {
  const CoachSatelliteFabs({super.key, required this.pageFab});

  final Widget pageFab;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const CoachAiFab(mini: true),
        const SizedBox(height: 10),
        pageFab,
      ],
    );
  }
}
