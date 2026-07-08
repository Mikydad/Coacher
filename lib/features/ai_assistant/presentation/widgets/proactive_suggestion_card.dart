import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/domain/models/analytics_event.dart';
import '../../../../app/application/main_tab_navigation.dart';
import '../../../ai_assistant/presentation/ai_assistant_screen.dart';
import '../../application/ai_assistant_providers.dart';
import '../../domain/models/proactive_suggestion.dart';

/// Displays a single proactive suggestion with "Let's do it" and "Not now"
/// actions. Slides in on mount and slides out on dismissal.
class ProactiveSuggestionCard extends ConsumerStatefulWidget {
  const ProactiveSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onDismiss,
  });

  final ProactiveSuggestion suggestion;
  final VoidCallback onDismiss;

  @override
  ConsumerState<ProactiveSuggestionCard> createState() =>
      _ProactiveSuggestionCardState();
}

class _ProactiveSuggestionCardState
    extends ConsumerState<ProactiveSuggestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  static const _kAccent = Color(0xFFB2ED00);
  static const _kSurface = Color(0xFF262B33);
  static const _kVariant = Color(0xFFADAAAA);

  @override
  void initState() {
    super.initState();
    // Log that the suggestion was shown on screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      logProactiveEvent(
        ref,
        AnalyticsEventType.proactiveSuggestionShown,
        props: {
          'suggestionType': widget.suggestion.type.name,
          'confidence': widget.suggestion.confidence,
        },
      );
      final ruleCode = widget.suggestion.optimisationRuleCode;
      if (ruleCode != null) {
        logProactiveEvent(
          ref,
          AnalyticsEventType.scheduleOptimisationSuggested,
          props: {'ruleCode': ruleCode},
        );
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  void _letsDoIt(BuildContext context) {
    logProactiveEvent(
      ref,
      AnalyticsEventType.proactiveSuggestionAccepted,
      props: {'suggestionType': widget.suggestion.type.name},
    );
    navigateToMainTab(
      context,
      ref,
      index: MainTabIndex.coach,
      coachArgs: CoachRouteArgs(
        preDraftedText: widget.suggestion.preDraftedInput,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: const BorderSide(color: _kAccent, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.suggestion.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.suggestion.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // "Not now" — ghost dismiss
                    GestureDetector(
                      onTap: () {
                        logProactiveEvent(
                          ref,
                          AnalyticsEventType.proactiveSuggestionDismissed,
                          props: {
                            'suggestionType': widget.suggestion.type.name,
                          },
                        );
                        ref
                            .read(dismissedSuggestionRepositoryProvider)
                            .logDismissal(widget.suggestion.type)
                            .then((_) {
                          ref.invalidate(proactiveSuggestionsProvider);
                        });
                        _dismiss();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Not now',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // "Let's do it" — primary pill
                    GestureDetector(
                      onTap: () => _letsDoIt(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "Let's do it",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
