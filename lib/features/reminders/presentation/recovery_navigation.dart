import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../tasks_hub/presentation/task_detail_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import 'recovery_card.dart';

/// "Do now" on a Recovery Card row.
///
/// An occurrence knows only its entity id, so the task's routine/block/day
/// are resolved from today's rows. If the task is not in today's plan (it was
/// moved, or the row is from an earlier day), the Tasks Hub is the honest
/// fallback — better than a dead button.
Future<void> openRecoveryTask(
  BuildContext context,
  WidgetRef ref,
  String entityId,
) async {
  final rows = ref.read(todayAllTasksRowsProvider).valueOrNull;
  final row = rows?.where((r) => r.task.id == entityId).firstOrNull;

  if (row == null) {
    await Navigator.pushNamed(context, TasksHubScreen.routeName);
    return;
  }
  await Navigator.pushNamed(
    context,
    TaskDetailScreen.routeName,
    arguments: TaskDetailArgs.fromRow(row),
  );
}

/// The strongest recovery moment (§3.6): a focus session just ended.
///
/// Shows the same content as the Home card, as a sheet, and only when there
/// is genuinely something open. Returns immediately when the card would be
/// empty, so finishing a session with a clear plate is never interrupted.
Future<void> showRecoveryPromptIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final view = ref.read(recoveryViewProvider).valueOrNull;
  if (view == null || view.isEmpty) return;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RecoveryCard(
              onOpenTask: (entityId) async {
                Navigator.pop(sheetContext);
                if (!context.mounted) return;
                await openRecoveryTask(context, ref, entityId);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}
