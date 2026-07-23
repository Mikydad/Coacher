import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/intentions_providers.dart';
import '../data/opportunity_plan_repository.dart';
import '../domain/models/intention.dart';
import 'intention_quick_add_sheet.dart';

/// The Promises strip (humanizing Phase 1) — top of Home, the ambient
/// answer to "what did I say I'd do?". Each row shows the planned moment
/// and its reason; this surface is also the delivery floor when
/// notifications are denied or the budget is exhausted (PRD §4.5).
class PromisesSection extends ConsumerWidget {
  const PromisesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openIntentionsProvider);
    final radar = ref.watch(radarIntentionsProvider);
    final plans =
        ref.watch(opportunityPlansProvider).valueOrNull ??
        const <String, OpportunityPlan>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PROMISES',
              style: TextStyle(
                color: AppColors.fg54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => showIntentionQuickAddSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 18, color: AppColors.fg70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (open.isEmpty)
          Text(
            'Nothing promised right now — say it to Coach or tap +.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfacePanel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.fg12),
            ),
            child: Column(
              children: [
                for (var i = 0; i < open.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppColors.fg12, indent: 52),
                  _PromiseRow(intention: open[i], plan: plans[open[i].id]),
                ],
              ],
            ),
          ),
        // "On your radar" — dormant standing understandings. Empty until
        // Phase 2 extraction ships; hidden entirely when empty.
        if (radar.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'ON YOUR RADAR',
            style: TextStyle(
              color: AppColors.fg54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          for (final intention in radar)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· ${intention.title}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _PromiseRow extends ConsumerWidget {
  const _PromiseRow({required this.intention, this.plan});

  final Intention intention;
  final OpportunityPlan? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subline = _sublineFor(intention, plan);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _showDetailSheet(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.radio_button_unchecked,
                size: 22,
                color: AppColors.cyan,
              ),
              tooltip: 'Done',
              onPressed: () => _markDone(context, ref),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intention.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDone(BuildContext context, WidgetRef ref) async {
    await ref
        .read(intentionsRepositoryProvider)
        .updateStatus(
          intention.id,
          IntentionStatus.done,
          completedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
    await ref
        .read(intentionNudgeSyncServiceProvider)
        .cancelForIntention(intention.id);
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfacePanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intention.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _windowLine(intention),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (plan != null && plan!.slots.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final slot in plan!.slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '· ${_slotTimeLabel(slot.deliverAtMs)} — ${slot.reasonText}',
                    style: TextStyle(color: AppColors.fg70, fontSize: 13),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _markDone(context, ref);
                    },
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(intentionNudgeSyncServiceProvider)
                          .cancelForIntention(intention.id);
                      await ref
                          .read(intentionsRepositoryProvider)
                          .deleteIntention(intention.id);
                    },
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _sublineFor(Intention intention, OpportunityPlan? plan) {
    if (intention.isPinned) {
      return 'Pinned · ${_slotTimeLabel(intention.pinnedAtMs!)}';
    }
    final slots = plan?.slots ?? const [];
    if (slots.isEmpty) return 'Finding a good moment…';
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = slots.where((s) => s.deliverAtMs > now).toList()
      ..sort((a, b) => a.deliverAtMs.compareTo(b.deliverAtMs));
    if (next.isEmpty) return 'Finding a good moment…';
    final s = next.first;
    return '${_slotTimeLabel(s.deliverAtMs)} · ${s.reasonText}';
  }

  static String _windowLine(Intention intention) {
    final end = DateTime.fromMillisecondsSinceEpoch(intention.windowEndMs);
    return 'By ${_dayLabel(end)}';
  }

  static String _slotTimeLabel(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '${_dayLabel(dt)} $hm';
  }

  static String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[dt.weekday - 1];
  }
}
