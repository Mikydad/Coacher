import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../focus/presentation/focus_selection_screen.dart';
import '../../timer/presentation/timer_session_screen.dart';
import 'extension_policy.dart';
import 'next_task_ranker.dart';
import 'planned_task_collect.dart';
import 'planned_task_providers.dart';

enum NextTaskDecision { startNow, extraTime, moveWithReason }

Future<void> runAutoNextTaskFlow(
  BuildContext context,
  WidgetRef ref, {
  required String completedTaskId,
  required int completionPercent,
}) async {
  if (completionPercent != 100) return;
  final rows = await readFreshTodayPlannedRows(ref);
  if (!context.mounted) return;
  final candidates = rows.where((r) => r.task.id != completedTaskId).toList();
  final next = NextTaskRanker.chooseNext(candidates, preferUserSequence: true);
  if (next == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great work. No next task available right now.')),
    );
    return;
  }
  final decision = await showDialog<NextTaskDecision>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Start next task?'),
        content: Text('Next up: ${next.task.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, NextTaskDecision.moveWithReason),
            child: const Text('Move to later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, NextTaskDecision.extraTime),
            child: const Text('Need extra time'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, NextTaskDecision.startNow),
            child: const Text('Start now'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || decision == null) return;
  switch (decision) {
    case NextTaskDecision.startNow:
      await ref.read(planningRepositoryProvider).logFlowTransitionEvent(
        FlowTransitionEvent(
          id: StableId.generate('flowev'),
          taskId: next.task.id,
          type: FlowTransitionType.startNow,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (!context.mounted) return;
      ref.read(activeExecutionTaskIdProvider.notifier).state = next.task.id;
      ref.read(activeExecutionTaskLabelProvider.notifier).state = next.task.title;
      ref.read(executionControllerProvider.notifier).setTask(
        id: next.task.id,
        label: next.task.title,
        durationMinutes: next.task.durationMinutes,
      );
      await Navigator.pushNamed(
        context,
        TimerSessionScreen.routeName,
        arguments: const TimerLaunchArgs(autoStartDelaySeconds: 10),
      );
      return;
    case NextTaskDecision.extraTime:
      final handled = await _handleExtraTime(context, ref, row: next);
      if (!context.mounted) return;
      if (handled) {
        await _returnToFocusList(context);
      }
      return;
    case NextTaskDecision.moveWithReason:
      final handled = await _handleMoveWithReason(context, ref, row: next);
      if (!context.mounted) return;
      if (handled) {
        await _returnToFocusList(context);
      }
      return;
  }
}

Future<Routine?> _routineForPlannedRow(WidgetRef ref, PlannedTaskRow row) async {
  final planning = ref.read(planningRepositoryProvider);
  try {
    final routines = await planning.getRoutinesForDate(row.dateKey);
    for (final r in routines) {
      if (r.id == row.routineId) return r;
    }
  } catch (_) {}
  return null;
}

Future<bool> _handleExtraTime(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTaskRow row,
}) async {
  final t = row.task;
  final planning = ref.read(planningRepositoryProvider);
  final blocks = await planning.getBlocks(row.routineId);
  var urgency = 50;
  for (final b in blocks) {
    if (b.id == row.blockId) {
      urgency = b.urgencyScore;
      break;
    }
  }
  final routineForPolicy = await _routineForPlannedRow(ref, row);
  if (!context.mounted) return false;
  final policy = ExtensionPolicy.forTask(
    task: t,
    resolver: ref.read(routineModePolicyResolverProvider),
    blockUrgencyScore: urgency,
    routine: routineForPolicy,
  );
  if (!context.mounted) return false;
  final extension = await _promptExtensionRequest(
    context,
    allowedMaxMinutes: policy.allowedMaxMinutes,
    requireReason: policy.requiresReason,
    requireReflection: policy.requiresReflectionPrompt,
  );
  if (extension == null) return false;
  final extraMinutes = extension.minutes;
  final updated = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: (t.durationMinutes + extraMinutes).clamp(1, 24 * 60),
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: t.status,
    createdAtMs: t.createdAtMs,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: _appendExtraTimeNote(
      existing: t.notes,
      extraMinutes: extraMinutes,
      reason: extension.reason,
      reflection: extension.reflection,
    ),
    sequenceIndex: t.sequenceIndex,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  await planning.upsertTask(updated);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: row.task.id,
      type: FlowTransitionType.extraTime,
      planChangeIntent: PlanChangeIntent.logical,
      reasonNote:
          '[+${extraMinutes}m] ${extension.reason}${extension.reflection == null ? '' : ' | ${extension.reflection}'}',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(row.task.id);
  invalidateTaskListProviders(ref);
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Added $extraMinutes minutes to "${row.task.title}".')),
  );
  return true;
}

Future<({int minutes, String reason, String? reflection})?> _promptExtensionRequest(
  BuildContext context, {
  required int allowedMaxMinutes,
  required bool requireReason,
  required bool requireReflection,
}) async {
  final options = [15, 30, 45, 60].where((m) => m <= allowedMaxMinutes).toList();
  if (options.isEmpty) return null;
  var selectedMinutes = options.first;
  var reasonText = '';
  var reflectionText = '';
  String? errorText;
  final result = await showDialog<({int minutes, String reason, String? reflection})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Request extra time'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedMinutes,
                  items: [
                    for (final m in options) DropdownMenuItem(value: m, child: Text('+$m minutes')),
                  ],
                  onChanged: (v) => setState(() => selectedMinutes = v ?? options.first),
                  decoration: InputDecoration(labelText: 'Allowed (max +$allowedMaxMinutes min)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 2,
                  onChanged: (v) => reasonText = v,
                  decoration: InputDecoration(
                    labelText: requireReason ? 'Reason (required)' : 'Reason',
                    hintText: 'Why do you need more time?',
                  ),
                ),
                if (requireReflection) ...[
                  const SizedBox(height: 10),
                  TextField(
                    maxLines: 2,
                    onChanged: (v) => reflectionText = v,
                    decoration: const InputDecoration(
                      labelText: 'What did you promise yourself? (required)',
                      hintText: 'Short commitment reminder to stay aligned.',
                    ),
                  ),
                ],
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final reason = reasonText.trim();
              final reflection = reflectionText.trim();
              if (requireReason && reason.isEmpty) {
                setState(() => errorText = 'Reason is required.');
                return;
              }
              if (requireReflection && reflection.isEmpty) {
                setState(() => errorText = 'Reflection is required.');
                return;
              }
              Navigator.pop(
                ctx,
                (
                  minutes: selectedMinutes,
                  reason: reason.isEmpty ? 'No reason provided' : reason,
                  reflection: reflection.isEmpty ? null : reflection,
                ),
              );
            },
            child: const Text('Approve extension'),
          ),
        ],
      ),
    ),
  );
  return result;
}

Future<bool> _handleMoveWithReason(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTaskRow row,
}) async {
  final reasons = OverrideReasonCategory.values;
  OverrideReasonCategory selectedReason = reasons.first;
  var noteText = '';
  String? errorText;
  final choice = await showDialog<({OverrideReasonCategory reason, String note})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Move task with reason'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<OverrideReasonCategory>(
                    initialValue: selectedReason,
                    items: [
                      for (final r in reasons) DropdownMenuItem(value: r, child: Text(r.label)),
                    ],
                    onChanged: (v) => setState(() => selectedReason = v ?? reasons.first),
                    decoration: const InputDecoration(labelText: 'Reason category'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    maxLines: 2,
                    onChanged: (v) => noteText = v,
                    decoration: const InputDecoration(
                      labelText: 'Logical reason (1-2 sentences)',
                      hintText: 'Explain why this move is the best decision now.',
                    ),
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final note = noteText.trim();
                try {
                  FlowTransitionEvent.validateReasonNote(note);
                } catch (_) {
                  setState(() => errorText = 'Give a clear reason in 1-2 sentences.');
                  return;
                }
                Navigator.pop(ctx, (reason: selectedReason, note: note));
              },
              child: const Text('Move task'),
            ),
          ],
        );
      },
    ),
  );
  if (choice == null) return false;

  final t = row.task;
  final planning = ref.read(planningRepositoryProvider);
  final moved = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: t.durationMinutes,
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: t.status,
    createdAtMs: t.createdAtMs,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: _appendMoveReason(
      existing: t.notes,
      reason: choice.reason,
      explanation: choice.note,
    ),
    sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 1000,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  await planning.upsertTask(moved);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: t.id,
      type: FlowTransitionType.moveWithReason,
      planChangeIntent: PlanChangeIntent.logical,
      reasonCategory: choice.reason,
      reasonNote: choice.note,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(t.id);
  invalidateTaskListProviders(ref);
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Moved "${t.title}" to later: ${choice.reason.label}.')),
  );
  return true;
}

String _appendMoveReason({
  required String? existing,
  required OverrideReasonCategory reason,
  required String explanation,
}) {
  final stamp = DateTime.now().toIso8601String();
  final entry = '[Moved $stamp] ${reason.label}: $explanation';
  if (existing == null || existing.trim().isEmpty) return entry;
  return '$existing\n$entry';
}

String _appendExtraTimeNote({
  required String? existing,
  required int extraMinutes,
  required String reason,
  required String? reflection,
}) {
  final stamp = DateTime.now().toIso8601String();
  final reflectPart = reflection == null ? '' : ' | Reflection: $reflection';
  final entry = '[ExtraTime $stamp] +${extraMinutes}m | Reason: $reason$reflectPart';
  if (existing == null || existing.trim().isEmpty) return entry;
  return '$existing\n$entry';
}

Future<void> _returnToFocusList(BuildContext context) async {
  await Navigator.pushNamedAndRemoveUntil(
    context,
    FocusSelectionScreen.routeName,
    (route) => route.settings.name == FocusSelectionScreen.routeName,
  );
}
