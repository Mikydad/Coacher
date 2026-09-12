import 'package:flutter/material.dart';

import '../../../../core/presentation/page_headers.dart';
import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';

/// Period label with ‹ › paging. › is disabled once the next period would
/// start after today.
class PeriodNav extends StatelessWidget {
  const PeriodNav({
    super.key,
    required this.period,
    required this.onPrevious,
    required this.onNext,
    this.trailing,
  });

  final ProgressPeriod period;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(period.key),
              children: [
                Flexible(
                  child: Text(
                    period.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SectionHeader.style.copyWith(
                      color: ProgressDesignTokens.onSurface,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        _Arrow(icon: Icons.chevron_left_rounded, onTap: onPrevious, tooltip: 'Previous'),
        _Arrow(icon: Icons.chevron_right_rounded, onTap: onNext, tooltip: 'Next'),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 26,
        color: onTap == null
            ? ProgressDesignTokens.onSurfaceVariant.withValues(alpha: 0.35)
            : ProgressDesignTokens.onSurface,
      ),
    );
  }
}
