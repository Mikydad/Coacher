import 'package:flutter/material.dart';

import '../application/scheduling_slot_suggestions.dart';
import '../../../core/presentation/app_colors.dart';

/// Inline panel to reschedule the conflicting entity.
class ConflictMovePanel extends StatelessWidget {
  const ConflictMovePanel({
    super.key,
    required this.entityTitle,
    required this.currentRangeLabel,
    required this.suggestions,
    required this.durationMinutes,
    required this.onApplySuggestion,
    required this.onCustomTime,
    this.busy = false,
  });

  final String entityTitle;
  final String currentRangeLabel;
  final List<TimeSlotSuggestion> suggestions;
  final int durationMinutes;
  final void Function(TimeSlotSuggestion suggestion) onApplySuggestion;
  final VoidCallback onCustomTime;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fg.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fg12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move $entityTitle',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Current: $currentRangeLabel',
            style: TextStyle(fontSize: 12, color: AppColors.fg60),
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            Text(
              'No open slots found today. Try custom time.',
              style: TextStyle(fontSize: 12, color: AppColors.fg54),
            )
          else
            for (final slot in suggestions) ...[
              _SuggestionChip(
                label: slot.label,
                range: formatSchedulingTimeRange(slot.startAt, slot.endAt),
                onTap: busy ? null : () => onApplySuggestion(slot),
              ),
              const SizedBox(height: 8),
            ],
          OutlinedButton.icon(
            onPressed: busy ? null : onCustomTime,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Custom time…'),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.range, this.onTap});

  final String label;
  final String range;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fg.withAlpha(8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.fg54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      range,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Apply'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
