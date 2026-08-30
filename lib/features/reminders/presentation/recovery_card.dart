import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/recovery_view.dart';
import '../domain/models/reminder_occurrence_enums.dart';

/// The Recovery Card (FR-R-50): what SidePal still owes you.
///
/// This is the surface that makes "SidePal forgot" untrue. Everything the
/// state machine marked Overdue lands here, ordered criticality-first then
/// longest-waiting, and stays until it is genuinely dealt with.
///
/// Design: the task leads, not alarm iconography (PRD §8). Extreme's
/// non-dismissible contract is conveyed by persistent presence and copy — not
/// by shouting in red. The only accent is the existing amber token, and only
/// for genuinely critical rows.
class RecoveryCard extends ConsumerWidget {
  const RecoveryCard({super.key, this.onOpenTask, this.onResolve});

  /// Tapping a row's primary action. Injectable so the timer-end prompt can
  /// reuse this card with its own navigation.
  final void Function(String entityId)? onOpenTask;

  /// Disposition chosen from a row's overflow (FR-R-41/42). Injectable for
  /// the same reason, and so widget tests can observe the contract without a
  /// navigator.
  final void Function(RecoveryRow row, ReminderResolutionKind kind)? onResolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(recoveryViewProvider).valueOrNull;
    if (view == null || view.isEmpty) return const SizedBox.shrink();

    final shown = view.rows.take(RecoveryViewBuilder.maxRows).toList();
    final overflow = view.rows.length - shown.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.fg.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              shown.isEmpty ? 'Today' : _headline(view.rows.length),
              subtitle: shown.isEmpty
                  ? null
                  : 'Still open — do one now, or move it.',
            ),
            if (shown.isNotEmpty) const SizedBox(height: 4),
            for (final row in shown)
              _RecoveryRowTile(
                row: row,
                onDo: () => onOpenTask?.call(row.occurrence.entityId),
                onDismiss: row.insistence.canDismiss
                    ? () => ref
                          .read(reminderOccurrenceServiceProvider)
                          .dismissForToday(row.occurrence.entityId)
                    : null,
                onResolve: onResolve == null
                    ? null
                    : (kind) => onResolve!(row, kind),
              ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  '+$overflow more waiting',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            if (view.routineDigestLine != null) ...[
              if (shown.isNotEmpty)
                Divider(height: 16, color: AppColors.fg.withAlpha(20)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  view.routineDigestLine!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _headline(int count) =>
      count == 1 ? '1 task needs you' : '$count tasks need you';
}

class _RecoveryRowTile extends StatelessWidget {
  const _RecoveryRowTile({
    required this.row,
    required this.onDo,
    this.onDismiss,
    this.onResolve,
  });

  final RecoveryRow row;
  final VoidCallback onDo;
  final void Function(ReminderResolutionKind kind)? onResolve;

  /// Null for Disciplined and Extreme — their contract is that the row does
  /// not go away just because you looked at it.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (row.isCritical)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 16,
                color: AppColors.amber,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recoveryRowSubtitle(row),
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // One primary action per row (FR-R-50); everything else lives in
          // the task's own screen.
          TextButton(onPressed: onDo, child: const Text('Do now')),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Not today',
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: Icon(
                CupertinoIcons.xmark,
                size: 15,
                color: AppColors.textMuted,
              ),
            )
          // Flexible needs no disposition at all (FR-R-40), so it gets no
          // overflow: the gentlest mode should not sprout a menu.
          else if (onResolve != null && !row.insistence.canDismiss)
            PopupMenuButton<ReminderResolutionKind>(
              tooltip: 'Other options',
              padding: EdgeInsets.zero,
              icon: Icon(
                CupertinoIcons.ellipsis,
                size: 16,
                color: AppColors.textMuted,
              ),
              onSelected: onResolve,
              // D4: unstaked Extreme is Do / Reschedule-with-reason ONLY.
              // Offering Skip — even with a reason — is the one-tap give-up
              // the contract excludes; Disciplined keeps it (FR-R-41 lists
              // Skip among its dispositions).
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: ReminderResolutionKind.rescheduled,
                  child: Text('Move to tomorrow'),
                ),
                if (row.insistence != RecoveryInsistence.demanding)
                  const PopupMenuItem(
                    value: ReminderResolutionKind.skipped,
                    child: Text('Skip'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

}

/// How long a row has waited, plus — for the stricter modes — what it is
/// actually asking for. Top-level so the copy is testable without pumping a
/// widget tree.
String recoveryRowSubtitle(RecoveryRow row, {DateTime? now}) {
  final waited = recoveryWaitedLabel(row.occurrence.overdueSinceMs, now: now);
  return switch (row.insistence) {
    RecoveryInsistence.dismissible => waited,
    RecoveryInsistence.persistent => '$waited · needs a decision',
    RecoveryInsistence.demanding => '$waited · do it or reschedule',
  };
}

String recoveryWaitedLabel(int? sinceMs, {DateTime? now}) {
  if (sinceMs == null) return 'Overdue';
  final since = DateTime.fromMillisecondsSinceEpoch(sinceMs);
  final minutes = (now ?? DateTime.now()).difference(since).inMinutes;
  if (minutes < 1) return 'Just missed';
  if (minutes < 60) return 'Waiting ${minutes}m';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'Waiting ${hours}h';
  final days = hours ~/ 24;
  return days == 1 ? 'Waiting since yesterday' : 'Waiting ${days}d';
}
