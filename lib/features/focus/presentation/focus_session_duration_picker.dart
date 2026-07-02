import 'package:flutter/material.dart';

import '../../add_task/presentation/custom_duration_dialog.dart';
import '../../execution/application/execution_day_loader.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/models/task_item.dart';

/// Quick duration picker before starting Focus on a reminder-only task.
Future<int?> showFocusSessionDurationPicker(
  BuildContext context, {
  required String taskTitle,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: const Color(0xFF131313),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Focus session length',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                taskTitle,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in const [
                    (15, '15m'),
                    (25, '25m'),
                    (45, '45m'),
                    (60, '1h'),
                  ])
                    _DurationChip(
                      label: option.$2,
                      onTap: () => Navigator.pop(ctx, option.$1),
                    ),
                  _DurationChip(
                    label: 'Custom',
                    onTap: () async {
                      final picked = await showCustomDurationDialog(
                        ctx,
                        initialMinutes: 25,
                      );
                      if (picked != null && ctx.mounted) {
                        Navigator.pop(ctx, picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF201F1F),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB7FF00),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

String focusTaskSubtitle(int durationMinutes) {
  if (taskHasFocusDuration(durationMinutes)) {
    return '${durationMinutes}m target';
  }
  return 'Reminder only';
}

String focusTaskListSubtitle({
  required ExecutionTaskItem task,
  required Map<String, int> scores,
}) {
  final durationPart = focusTaskSubtitle(task.durationMinutes);
  if (task.status != TaskStatus.partial) return durationPart;

  final percent = scores[task.id];
  if (percent != null) {
    return 'Partial · $percent% · $durationPart';
  }
  return 'Partial · $durationPart';
}
