import 'package:flutter/material.dart';

import '../../domain/models/ai_action.dart';
import '../../domain/models/ai_planned_changes.dart';

class PlannedChangesCard extends StatelessWidget {
  const PlannedChangesCard({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    this.isExecuted = false,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    this.isLoading = false,
  });

  final AiPlannedChanges plan;
  final bool isCurrentPlan;
  final bool isExecuted;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLANNED CHANGES PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10 * 11,
              color: Color(0xFFADAAAA),
            ),
          ),
          const SizedBox(height: 12),
          // Action rows
          ...plan.actions.map((action) => _ActionRow(action: action)),
          // Hard context-block rows (red)
          if (plan.isBlockedByContext) ...[
            const SizedBox(height: 8),
            ...plan.blockedByContext.map(
              (c) => _ConflictRow(message: c, isBlocking: true),
            ),
            const SizedBox(height: 4),
            const _BlockedDisclaimer(),
          ],
          // Soft conflict warnings (amber)
          if (plan.hasConflicts) ...[
            const SizedBox(height: 8),
            ...plan.conflicts.map(
              (c) => _ConflictRow(message: c, isBlocking: false),
            ),
          ],
          // High-risk warning
          if (plan.hasHighRiskActions) ...[
            const SizedBox(height: 8),
            _HighRiskWarning(count: plan.highRiskCount),
          ],
          // Confirm on any unexecuted card; Edit/Cancel only on the latest plan.
          if (!isExecuted) ...[
            const SizedBox(height: 16),
            _ActionButtons(
              onConfirm: onConfirm,
              onEdit: onEdit,
              onCancel: onCancel,
              isLoading: isLoading,
              hasConflicts: plan.hasConflicts,
              isBlocked: plan.isBlockedByContext,
              showEditCancel: isCurrentPlan,
            ),
          ] else if (isExecuted) ...[
            const SizedBox(height: 12),
            const _ExecutedLabel(),
          ],
        ],
      ),
    );
  }
}

// ─── Action row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final AiAction action;

  @override
  Widget build(BuildContext context) {
    final (:icon, :color) = _iconForAction(action);
    final description = _describeAction(action);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          ),
          if (action.reasonLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                action.reasonLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFADAAAA),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _iconForAction(AiAction action) {
    switch (action.actionType) {
      case ActionType.createTask:
      case ActionType.createGoal:
      case ActionType.addReminder:
        return (icon: Icons.add_rounded, color: const Color(0xFFB2ED00));

      case ActionType.deleteTask:
      case ActionType.deleteGoal:
      case ActionType.removeReminder:
        return (icon: Icons.remove_rounded, color: Colors.redAccent);

      case ActionType.editTask:
      case ActionType.moveTask:
      case ActionType.modifyGoal:
      case ActionType.rescheduleReminder:
        return (icon: Icons.edit_rounded, color: const Color(0xFFADAAAA));

      case ActionType.activateContextOverride:
      case ActionType.endContextOverride:
        return (icon: Icons.shield_rounded, color: const Color(0xFF00E3FD));

      case ActionType.suggestFreeTimeBlock:
      case ActionType.moveConflictingTasks:
        return (icon: Icons.schedule_rounded, color: const Color(0xFF00E3FD));
    }
  }

  String _describeAction(AiAction action) {
    final p = action.parameters;
    switch (action.actionType) {
      case ActionType.createTask:
        final title = p['title'] ?? 'Task';
        final time = p['time'] != null ? ' (${p['time']})' : '';
        final date = p['date'] != null ? ' on ${p['date']}' : '';
        return 'Add $title$time$date';

      case ActionType.editTask:
        return 'Edit "${p['title'] ?? 'task'}"';

      case ActionType.moveTask:
        return 'Move "${p['taskTitle'] ?? 'task'}" to ${p['destinationDate'] ?? '?'}';

      case ActionType.deleteTask:
        return 'Delete "${p['taskTitle'] ?? 'task'}"';

      case ActionType.createGoal:
        return 'Create goal "${p['title'] ?? 'Goal'}"';

      case ActionType.modifyGoal:
        return 'Update goal "${p['goalTitle'] ?? 'goal'}"';

      case ActionType.deleteGoal:
        return 'Remove goal "${p['goalTitle'] ?? 'goal'}"';

      case ActionType.addReminder:
        return 'Add reminder for "${p['taskTitle'] ?? 'task'}" at ${p['reminderTime'] ?? '?'}';

      case ActionType.removeReminder:
        return 'Remove reminder for "${p['taskTitle'] ?? 'task'}"';

      case ActionType.rescheduleReminder:
        return 'Reschedule reminder for "${p['taskTitle'] ?? 'task'}" to ${p['reminderTime'] ?? '?'}';

      case ActionType.activateContextOverride:
        final type = p['overrideType'] ?? 'focus';
        final dur = p['durationMinutes'];
        return 'Enable ${type.toString().replaceFirst(type[0], type[0].toUpperCase())} mode'
            '${dur != null ? ' for $dur min' : ''}';

      case ActionType.endContextOverride:
        return 'End active mode';

      case ActionType.suggestFreeTimeBlock:
        return 'Find free time slot (${p['durationMinutes'] ?? '?'} min)';

      case ActionType.moveConflictingTasks:
        return 'Resolve schedule conflicts';
    }
  }
}

// ─── Conflict row ─────────────────────────────────────────────────────────────

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({required this.message, required this.isBlocking});

  final String message;
  final bool isBlocking;

  @override
  Widget build(BuildContext context) {
    final bg = isBlocking
        ? Colors.red.withValues(alpha: 0.15)
        : const Color(0xFFFFA726).withValues(alpha: 0.15);
    final textColor = isBlocking ? Colors.redAccent : const Color(0xFFFFA726);
    final icon = isBlocking ? Icons.block_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── High-risk warning ────────────────────────────────────────────────────────

class _HighRiskWarning extends StatelessWidget {
  const _HighRiskWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_forever_rounded, size: 14, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This will permanently delete $count item${count > 1 ? 's' : ''}.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    required this.isLoading,
    required this.hasConflicts,
    this.isBlocked = false,
    this.showEditCancel = true,
  });

  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool hasConflicts;
  final bool isBlocked;
  final bool showEditCancel;

  @override
  Widget build(BuildContext context) {
    final String confirmLabel;
    if (isBlocked) {
      confirmLabel = 'CONFIRM ANYWAY ▶';
    } else if (hasConflicts) {
      confirmLabel = 'CONFIRM ANYWAY ▶';
    } else {
      confirmLabel = 'CONFIRM CHANGES ▶';
    }

    final confirmBg = isBlocked
        ? Colors.red.withValues(alpha: 0.85)
        : const Color(0xFFBEFC00);
    final confirmFg =
        isBlocked ? Colors.white : const Color(0xFF445D00);

    return Column(
      children: [
        // CONFIRM CHANGES — full width
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmBg,
              foregroundColor: confirmFg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: confirmFg,
                    ),
                  )
                : Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        if (showEditCancel) ...[
        const SizedBox(height: 10),
        // EDIT PLAN + CANCEL — side by side
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFADAAAA),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('EDIT PLAN', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('CANCEL', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        ],
      ],
    );
  }
}

// ─── Blocked disclaimer ───────────────────────────────────────────────────────

class _BlockedDisclaimer extends StatelessWidget {
  const _BlockedDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        'This task will be created but reminders may be suppressed.',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: Colors.redAccent.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

// ─── Executed label ───────────────────────────────────────────────────────────

class _ExecutedLabel extends StatelessWidget {
  const _ExecutedLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFFADAAAA)),
        SizedBox(width: 6),
        Text(
          'Applied',
          style: TextStyle(fontSize: 12, color: Color(0xFFADAAAA)),
        ),
      ],
    );
  }
}
