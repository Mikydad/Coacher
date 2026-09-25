import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/recovery_triage_service.dart';
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
class RecoveryCard extends ConsumerStatefulWidget {
  const RecoveryCard({super.key, this.onOpenTask, this.onResolve});

  /// Tapping a row's primary action. Injectable so the timer-end prompt can
  /// reuse this card with its own navigation.
  final void Function(String entityId, String entityKind)? onOpenTask;

  /// Disposition chosen from a row's overflow (FR-R-41/42). Injectable for
  /// the same reason, and so widget tests can observe the contract without a
  /// navigator.
  final void Function(RecoveryRow row, ReminderResolutionKind kind)? onResolve;

  @override
  ConsumerState<RecoveryCard> createState() => _RecoveryCardState();
}

class _RecoveryCardState extends ConsumerState<RecoveryCard> {
  /// Collapsed by default (Miko, 2026-09-15): the card leads with the one
  /// row that matters most; "N MORE" reveals the rest. The headline still
  /// carries the full count, so nothing is hidden about how much is owed.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(recoveryViewProvider).valueOrNull;
    if (view == null || view.isEmpty) return const SizedBox.shrink();

    // FR-R-62: the deterministic order renders NOW; if the one bounded
    // triage call has answered, its ranking enhances in place. valueOrNull
    // means a pending or failed call changes nothing. The call's headline
    // is no longer shown (plain-language pass, 2026-09-25): the subtitle
    // stays fixed so the card always says the same plain thing.
    final triage = ref.watch(recoveryTriageProvider).valueOrNull;
    final ordered = triage == null
        ? view.rows
        : RecoveryTriageService.applyOrder(view.rows, triage);

    final capped = ordered.take(RecoveryViewBuilder.maxRows).toList();
    final shown = _expanded ? capped : capped.take(1).toList();
    final overflow = _expanded ? ordered.length - capped.length : 0;
    final hasMore = ordered.length > 1;

    // Redesign 2026-09-14: a clean white card — headline, muted subtitle,
    // hairline, then the rows. No translucent gray fill, so it never reads
    // as disabled.
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              shown.isEmpty ? 'Today' : _headline(view.rows.length),
              hero: true,
              subtitle: shown.isEmpty
                  ? null
                  : "Tasks you didn't complete or reschedule.",
            ),
            if (shown.isNotEmpty)
              Divider(height: 28, thickness: 1, color: AppColors.divider),
            for (final row in shown)
              _RecoveryRowTile(
                row: row,
                onDo: () => widget.onOpenTask?.call(
                  row.occurrence.entityId,
                  row.occurrence.entityKind,
                ),
                onDismiss: row.insistence.canDismiss
                    ? () => ref
                          .read(reminderOccurrenceServiceProvider)
                          .dismissForToday(row.occurrence.entityId)
                    : null,
                onResolve: widget.onResolve == null
                    ? null
                    : (kind) => widget.onResolve!(row, kind),
              ),
            if (hasMore)
              InkWell(
                key: const ValueKey('recovery_more'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        _expanded
                            ? 'SHOW LESS'
                            : '${ordered.length - shown.length} MORE',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 260),
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  '+$overflow more waiting',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (view.routineDigestLine != null) ...[
              if (shown.isNotEmpty)
                Divider(height: 16, thickness: 1, color: AppColors.divider),
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
}

String _headline(int count) =>
    count == 1 ? '1 unfinished task' : '$count unfinished tasks';

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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recoveryRowSubtitle(row),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // One primary action per row (FR-R-50); everything else lives in
          // the task's own screen.
          AppSoftPill(label: 'Do now', onPressed: onDo),
          const SizedBox(width: 4),
          // A fixed slot whatever lives here (×, ⋯ or nothing) so the
          // "Do now" pills line up down the card (Miko, 2026-09-15).
          SizedBox(width: 36, height: 36, child: _trailing()),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (onDismiss != null) {
      return IconButton(
        tooltip: 'Not today',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        onPressed: onDismiss,
        icon: Icon(
          CupertinoIcons.xmark,
          size: 15,
          color: AppColors.textSecondary,
        ),
      );
    }
    // Flexible needs no disposition at all (FR-R-40), so it gets no
    // overflow: the gentlest mode should not sprout a menu.
    if (onResolve != null && !row.insistence.canDismiss) {
      return PopupMenuButton<ReminderResolutionKind>(
        tooltip: 'Other options',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36),
        icon: Icon(
          CupertinoIcons.ellipsis,
          size: 16,
          color: AppColors.textSecondary,
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
      );
    }
    return const SizedBox.shrink();
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
