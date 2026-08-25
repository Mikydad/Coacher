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
/// Full-size on every tab (2026-08-25 — the mini satellite form was too
/// quiet to find); on tabs that own a primary FAB it stacks above the
/// page's own action, same spot everywhere.
///
/// Carries the red "blocked plan" dot that used to sit on the Coach nav
/// icon — now visible from every working tab instead of one nav slot.
class CoachAiFab extends ConsumerWidget {
  const CoachAiFab({super.key});

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
      // Solid accent + a soft glow: the coach is the app's one primary
      // action, and the old ink-on-ink outline disappeared into the page.
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          // Multiple instances live in the tab IndexedStack at once — opt out
          // of Hero animation entirely so route transitions never collide.
          heroTag: null,
          onPressed: () => showCoachAiSheet(
            context,
            askBar: true,
            args: hasSuggestions
                ? const CoachRouteArgs(openSuggestionsPanel: true)
                : null,
          ),
          elevation: 0,
          highlightElevation: 0,
          splashColor: AppColors.onAccent.withValues(alpha: 0.12),
          backgroundColor: _accent,
          shape: const CircleBorder(),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.onAccent,
            size: 26,
          ),
        ),
      ),
    );

    if (!hasBlockedPlan && !hasSuggestions) return fab;
    // Red (blocked plan) outranks the suggestions dot; on the solid accent
    // disc the suggestions dot flips to the on-accent tone to stay visible.
    final dotColor = hasBlockedPlan ? Colors.redAccent : AppColors.onAccent;
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

/// Satellite arrangement for tabs that own a primary FAB: coach button
/// above, the page's own action below.
class CoachSatelliteFabs extends StatelessWidget {
  const CoachSatelliteFabs({super.key, required this.pageFab});

  final Widget pageFab;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const CoachAiFab(),
        const SizedBox(height: 10),
        pageFab,
      ],
    );
  }
}
