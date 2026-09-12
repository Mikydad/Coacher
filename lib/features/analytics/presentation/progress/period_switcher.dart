import 'package:flutter/material.dart';

import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';

const _labels = {
  ProgressHorizon.day: 'Day',
  ProgressHorizon.week: 'Week',
  ProgressHorizon.month: 'Month',
  ProgressHorizon.quarter: 'Quarter',
  ProgressHorizon.year: 'Year',
};

/// Five-segment horizon control. Selection animates in place; the content
/// below it is the caller's `AnimatedSwitcher`.
class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ProgressHorizon value;
  final ValueChanged<ProgressHorizon> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final h in ProgressHorizon.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: h == value,
                label: _labels[h],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: h == value
                          ? ProgressDesignTokens.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        _labels[h]!,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: h == value
                              ? ProgressDesignTokens.onSurface
                              : ProgressDesignTokens.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: h == value
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
