import 'package:flutter/material.dart';

import '../../../../core/utils/friendly_date.dart';
import '../../domain/models/ai_action.dart';
import '../../domain/models/ai_planned_changes.dart';

import '../../../../core/presentation/app_colors.dart';

class PlannedChangesCard extends StatelessWidget {
  const PlannedChangesCard({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    this.isExecuted = false,
    this.isCancelled = false,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    this.isLoading = false,
  });

  final AiPlannedChanges plan;
  final bool isCurrentPlan;
  final bool isExecuted;
  final bool isCancelled;
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
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLANNED CHANGES PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10 * 11,
              color: AppColors.textSoft,
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
          // Buttons only on the LIVE plan. A cancelled, superseded, or
          // applied card is inert — a stale Confirm was one accidental tap
          // from executing a rejected delete-plan (2026-08-22 bug batch).
          if (isCurrentPlan && !isExecuted && !isCancelled) ...[
            const SizedBox(height: 16),
            _ActionButtons(
              onConfirm: onConfirm,
              onEdit: onEdit,
              onCancel: onCancel,
              isLoading: isLoading,
              hasConflicts: plan.hasConflicts,
              isBlocked: plan.isBlockedByContext,
            ),
          ] else if (isExecuted) ...[
            const SizedBox(height: 12),
            const _ExecutedLabel(),
          ] else if (isCancelled) ...[
            const SizedBox(height: 12),
            const _CancelledLabel(),
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
                  style: TextStyle(fontSize: 14, color: AppColors.grayBright),
                ),
              ),
            ],
          ),
          if (action.reasonLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                action.reasonLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSoft,
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
      case ActionType.createIntention:
      case ActionType.rememberFact:
        return (icon: Icons.add_rounded, color: AppColors.accentDim);

      case ActionType.updateFact:
        return (icon: Icons.edit_rounded, color: AppColors.textSoft);

      case ActionType.forgetFact:
        return (icon: Icons.remove_rounded, color: Colors.redAccent);

      case ActionType.deleteTask:
      case ActionType.deleteGoal:
      case ActionType.removeReminder:
        return (icon: Icons.remove_rounded, color: Colors.redAccent);

      case ActionType.editTask:
      case ActionType.moveTask:
      case ActionType.modifyGoal:
      case ActionType.rescheduleReminder:
        return (icon: Icons.edit_rounded, color: AppColors.textSoft);

      case ActionType.activateContextOverride:
      case ActionType.endContextOverride:
        return (icon: Icons.shield_rounded, color: AppColors.cyan);

      case ActionType.suggestFreeTimeBlock:
      case ActionType.moveConflictingTasks:
        return (icon: Icons.schedule_rounded, color: AppColors.cyan);
    }
  }

  String _describeAction(AiAction action) => describePlannedAction(action);
}

/// A reminder time is only worth printing when it actually looks like a
/// clock time — model drift has produced junk like "min" here, which
/// rendered as the nonsense preview line "… at min".
String? _timeLabel(dynamic raw) {
  final s = raw?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return RegExp(r'\d').hasMatch(s) ? s : null;
}

/// Human-readable one-liner for a planned action. Shared by the preview
/// card rows and the draft-plan summary under suggestion bubbles — an
/// "Apply this plan" button must never appear with nothing describing what
/// it applies (2026-08-22 bug batch).
String describePlannedAction(AiAction action) {
  final p = action.parameters;
  switch (action.actionType) {
    case ActionType.createTask:
      final title = p['title'] ?? 'Task';
      final time = p['time'] != null ? ' (${p['time']})' : '';
      // "on Sunday", never "on 2026-08-30" (2026-08-25).
      final date = p['date'] != null
          ? ' on ${friendlyDateKey('${p['date']}')}'
          : '';
      return 'Add $title$time$date';

    case ActionType.editTask:
      return 'Edit "${p['title'] ?? 'task'}"';

    case ActionType.moveTask:
      final dest = p['destinationDate'];
      return 'Move "${p['taskTitle'] ?? 'task'}" to '
          '${dest != null ? friendlyDateKey('$dest') : '?'}';

    case ActionType.deleteTask:
      return 'Delete "${p['taskTitle'] ?? 'task'}"';

    case ActionType.createGoal:
      // The deadline used to be silently dropped from the preview.
      final deadline = p['deadline'];
      return 'Create goal "${p['title'] ?? 'Goal'}"'
          '${deadline != null ? ' — by ${friendlyDateKey('$deadline')}' : ''}';

    case ActionType.modifyGoal:
      return 'Update goal "${p['goalTitle'] ?? 'goal'}"';

    case ActionType.deleteGoal:
      return 'Remove goal "${p['goalTitle'] ?? 'goal'}"';

    case ActionType.addReminder:
      final at = _timeLabel(p['reminderTime']);
      return 'Add reminder for "${p['taskTitle'] ?? 'task'}"'
          '${at != null ? ' at $at' : ''}';

    case ActionType.removeReminder:
      return 'Remove reminder for "${p['taskTitle'] ?? 'task'}"';

    case ActionType.rescheduleReminder:
      final to = _timeLabel(p['reminderTime']);
      return 'Reschedule reminder for "${p['taskTitle'] ?? 'task'}"'
          '${to != null ? ' to $to' : ''}';

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

    // Normally auto-committed and never previewed; described anyway in
    // case an intention rides along in a mixed batch.
    case ActionType.createIntention:
      return 'Remember "${p['title'] ?? 'promise'}"';

    case ActionType.rememberFact:
      return 'Remember "${p['content'] ?? 'fact'}"';

    case ActionType.updateFact:
      return 'Update memory to "${p['newContent'] ?? '?'}"';

    case ActionType.forgetFact:
      return 'Forget "${p['factRef'] ?? 'memory'}"';
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
        : AppColors.amber.withValues(alpha: 0.15);
    final textColor = isBlocking ? Colors.redAccent : AppColors.amber;
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
          const Icon(
            Icons.delete_forever_rounded,
            size: 14,
            color: Colors.redAccent,
          ),
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
  });

  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool hasConflicts;
  final bool isBlocked;

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
        : AppColors.accentBright;
    final confirmFg = isBlocked ? AppColors.fg : AppColors.accentDeep;

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
        const SizedBox(height: 10),
        // EDIT PLAN + CANCEL — side by side
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSoft,
                  side: BorderSide(color: AppColors.fg.withValues(alpha: 0.15)),
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
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 14,
          color: AppColors.textSoft,
        ),
        SizedBox(width: 6),
        Text(
          'Applied',
          style: TextStyle(fontSize: 12, color: AppColors.textSoft),
        ),
      ],
    );
  }
}

// ─── Cancelled label ──────────────────────────────────────────────────────────

class _CancelledLabel extends StatelessWidget {
  const _CancelledLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cancel_outlined, size: 14, color: AppColors.textSoft),
        SizedBox(width: 6),
        Text(
          'Cancelled',
          style: TextStyle(fontSize: 12, color: AppColors.textSoft),
        ),
      ],
    );
  }
}
