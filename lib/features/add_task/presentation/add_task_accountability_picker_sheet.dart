import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/add_task_mode_resolution.dart';
import 'add_task_ui.dart';

/// Bottom-sheet picker for the task's accountability (enforcement) mode.
/// Resolves to the picked mode id, or null when dismissed.
Future<String?> showAccountabilityPickerSheet(
  BuildContext context, {
  required String selectedModeId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AddTaskColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.fg.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Accountability',
              style: TextStyle(
                fontSize: 5,
                fontWeight: FontWeight.w700,
                color: AddTaskColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How we remind you and follow up on this task',
              style: TextStyle(fontSize: 12, color: AddTaskColors.muted),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < kAddTaskModeChoiceIds.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AddTaskEnforcementTile(
                modeId: kAddTaskModeChoiceIds[i],
                label: kAddTaskModeLabels[i],
                description: kAddTaskModeDescriptions[i],
                isSelected: selectedModeId == kAddTaskModeChoiceIds[i],
                onTap: () => Navigator.pop(ctx, kAddTaskModeChoiceIds[i]),
              ),
            ],
          ],
        ),
      );
    },
  );
}
