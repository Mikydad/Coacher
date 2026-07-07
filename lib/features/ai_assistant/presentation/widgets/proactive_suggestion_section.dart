import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai_assistant_providers.dart';
import '../../application/proactive_suggestion_display.dart';
import 'proactive_suggestion_card.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Shows proactive suggestions on Home: one card by default, expandable in place
/// to reveal the full list (no Coach tab detour).
class ProactiveSuggestionSection extends ConsumerStatefulWidget {
  const ProactiveSuggestionSection({super.key});

  @override
  ConsumerState<ProactiveSuggestionSection> createState() =>
      _ProactiveSuggestionSectionState();
}

class _ProactiveSuggestionSectionState
    extends ConsumerState<ProactiveSuggestionSection> {
  bool _expanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _collapse() {
    _collapseTimer?.cancel();
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  void _expand() {
    setState(() => _expanded = true);
    _scheduleAutoCollapse();
  }

  void _scheduleAutoCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(kHomeSuggestionsAutoCollapseDuration, () {
      if (mounted) _collapse();
    });
  }

  void _onExpandedInteraction() {
    if (_expanded) _scheduleAutoCollapse();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(proactiveSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const _SkeletonCard(),
      error: (e, _) => swallowedAsyncError(
        'proactive_suggestion_section',
        e,
        const SizedBox.shrink(),
      ),
      data: (suggestions) {
        final active = activeProactiveSuggestions(suggestions);
        if (active.isEmpty) return const SizedBox.shrink();

        if (active.length <= kHomeProactiveSuggestionLimit && _expanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _collapse();
          });
        }

        final visible = _expanded
            ? active
            : active.take(kHomeProactiveSuggestionLimit).toList();
        final hiddenCount = active.length - kHomeProactiveSuggestionLimit;
        final showExpandLink = !_expanded && hiddenCount > 0;
        final showCollapseLink =
            _expanded && active.length > kHomeProactiveSuggestionLimit;

        return Listener(
          onPointerDown: (_) => _onExpandedInteraction(),
          child: AnimatedSize(
            duration: kHomeSuggestionsExpandDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in visible)
                  ProactiveSuggestionCard(
                    key: ValueKey(s.id),
                    suggestion: s,
                    onDismiss: () {},
                  ),
                if (showExpandLink)
                  _SuggestionsExpandLink(
                    label: hiddenCount == 1
                        ? 'Show 1 more'
                        : 'Show $hiddenCount more',
                    icon: Icons.expand_more_rounded,
                    onPressed: _expand,
                  ),
                if (showCollapseLink)
                  _SuggestionsExpandLink(
                    label: 'Show less',
                    icon: Icons.expand_less_rounded,
                    onPressed: _collapse,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionsExpandLink extends StatelessWidget {
  const _SuggestionsExpandLink({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  static const _kAccent = AppColors.accentDim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _kAccent,
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
              Icon(icon, size: 18),
            ],
          ),
        ),
      ),
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
        color: AppColors.inkWarm,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.gray3A, width: 3),
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
        color: AppColors.inkSoft,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
