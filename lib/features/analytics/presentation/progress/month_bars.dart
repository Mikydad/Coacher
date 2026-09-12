import 'package:flutter/material.dart';

import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// One thin bar per month of a quarter (3) or year (12). Null = quiet.
class MonthBars extends StatelessWidget {
  const MonthBars({super.key, required this.period, required this.rates});

  final ProgressPeriod period;
  final List<double?> rates;

  @override
  Widget build(BuildContext context) {
    final firstMonth = period.start.month;
    return Column(
      children: [
        for (var i = 0; i < rates.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    _shortMonths[(firstMonth - 1 + i) % 12],
                    style: TextStyle(
                      color: ProgressDesignTokens.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: (rates[i] ?? 0).clamp(0.0, 1.0),
                        backgroundColor:
                            ProgressDesignTokens.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ProgressDesignTokens.primaryDim,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text(
                    rates[i] == null ? '—' : '${(rates[i]! * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: rates[i] == null
                          ? ProgressDesignTokens.onSurfaceVariant
                          : ProgressDesignTokens.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
