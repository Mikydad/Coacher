import 'package:flutter/material.dart';

import '../../../planning/domain/add_task_duration.dart';
import '../../../planning/domain/sleep_task.dart';
import '../../application/add_task_duration_labels.dart';
import '../add_task_ui.dart';

/// Card matching the reminder section: a single toggle row when off, the
/// duration chips revealed beneath it when on. Sleep always has a length,
/// so it gets a static header instead of a switch. Chip labels/keys derive
/// from the shared duration helpers; picking the Custom chip defers to
/// [onCustomTap] (the State owns the dialog + resulting `setState`).
class AddTaskDurationSection extends StatelessWidget {
  const AddTaskDurationSection({
    super.key,
    required this.category,
    required this.duration,
    required this.customDurationMinutes,
    required this.durationEnabled,
    required this.onDurationEnabledChanged,
    required this.onPresetSelected,
    required this.onCustomTap,
  });

  final String? category;
  final String duration;
  final int customDurationMinutes;
  final bool durationEnabled;
  final ValueChanged<bool> onDurationEnabledChanged;

  /// Fired with the resolved chip *key* (e.g. '25 MIN') — never the Custom key.
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    final sleep = isSleepCategory(category);
    final showChips = sleep || durationEnabled;
    final labels = activeAddTaskDurationLabels(
      category: category,
      duration: duration,
      customMinutes: customDurationMinutes,
    );
    final options = activeAddTaskDurationOptions(category);

    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sleep)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AddTaskColors.accentDim.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: AddTaskColors.accentDim,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sleep length',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AddTaskColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pick a preset or tap Custom',
                            style: TextStyle(
                              fontSize: 12,
                              color: AddTaskColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              AddTaskToggleRow(
                icon: Icons.timer_outlined,
                iconColor: AddTaskColors.accentDim,
                title: 'Duration',
                subtitle: durationEnabled
                    ? 'Define your focus sprint'
                    : 'Reminder only — no time block',
                value: durationEnabled,
                onChanged: onDurationEnabledChanged,
              ),
            if (showChips) ...[
              const SizedBox(height: 2),
              AddTaskDurationSegment(
                options: labels,
                selected: addTaskDurationSegmentSelection(
                  category: category,
                  durationEnabled: durationEnabled,
                  duration: duration,
                  customMinutes: customDurationMinutes,
                ),
                onSelected: (label) {
                  final i = labels.indexOf(label);
                  if (i < 0) return;
                  final key = options[i];
                  if (isCustomDurationKey(key)) {
                    onCustomTap();
                    return;
                  }
                  onPresetSelected(key);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
