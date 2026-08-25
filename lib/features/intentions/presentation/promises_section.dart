import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/activity_moment_rules.dart';
import '../application/intentions_providers.dart';
import '../data/opportunity_plan_repository.dart';
import '../domain/models/intention.dart';
import 'activity_ask_card.dart';
import 'calendar_ask_card.dart';
import 'intention_quick_add_sheet.dart';
import 'on_your_radar_section.dart';

/// The Promises strip (humanizing Phase 1) — top of Home, the ambient
/// answer to "what did I say I'd do?". Each row shows the planned moment
/// and its reason; this surface is also the delivery floor when
/// notifications are denied or the budget is exhausted (PRD §4.5).
///
/// Only the most imminent promise shows by default (2026-08-22): soonest
/// upcoming day first, ties (and undated promises) broken by most recently
/// updated. The rest collapse behind a chevron, radar-section style.
class PromisesSection extends ConsumerStatefulWidget {
  const PromisesSection({super.key});

  @override
  ConsumerState<PromisesSection> createState() => _PromisesSectionState();
}

class _PromisesSectionState extends ConsumerState<PromisesSection> {
  bool _expanded = false;

  /// Day (local midnight ms) of the promise's next planned moment; undated
  /// promises sort after every dated one.
  static int _nextMomentDay(Intention i, OpportunityPlan? plan, int nowMs) {
    int? momentMs = i.isPinned ? i.pinnedAtMs : null;
    if (momentMs == null) {
      final future =
          (plan?.slots ?? const []).where((s) => s.deliverAtMs > nowMs).toList()
            ..sort((a, b) => a.deliverAtMs.compareTo(b.deliverAtMs));
      if (future.isNotEmpty) momentMs = future.first.deliverAtMs;
    }
    if (momentMs == null) return 1 << 62;
    final dt = DateTime.fromMillisecondsSinceEpoch(momentMs);
    return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final plans =
        ref.watch(opportunityPlansProvider).valueOrNull ??
        const <String, OpportunityPlan>{};
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final open = [...ref.watch(openIntentionsProvider)]
      ..sort((a, b) {
        final byDay = _nextMomentDay(
          a,
          plans[a.id],
          nowMs,
        ).compareTo(_nextMomentDay(b, plans[b.id], nowMs));
        if (byDay != 0) return byDay;
        return b.updatedAtMs.compareTo(a.updatedAtMs);
      });

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
                _PromiseRow(intention: open.first, plan: plans[open.first.id]),
                if (open.length > 1) ...[
                  Divider(height: 1, color: AppColors.fg12, indent: 52),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${open.length - 1} MORE',
                            style: TextStyle(
                              color: AppColors.fg54,
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
                              color: AppColors.fg54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_expanded
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            children: [
                              for (var i = 1; i < open.length; i++) ...[
                                Divider(
                                  height: 1,
                                  color: AppColors.fg12,
                                  indent: 52,
                                ),
                                _PromiseRow(
                                  intention: open[i],
                                  plan: plans[open[i].id],
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        // Just-in-time calendar ask (Phase 4b): first open promise is the
        // first moment calendar access has a nameable benefit.
        if (open.isNotEmpty) const CalendarAskCard(),
        // Just-in-time motion ask (Phase 6a): first CALL-shaped promise is
        // the first moment motion access has a nameable benefit. Its
        // provider hides it while the calendar ask is undecided, so two
        // permission cards never stack (Q6 progressive ladder).
        if (open.any(
          (i) => i.activityTags.any(handsFreeCompatibleTags.contains),
        ))
          const ActivityAskCard(),
        // "On your radar" (Phase 7b) — dormant understandings + today's
        // reflection observation, collapsed by default, hidden when empty.
        const OnYourRadarSection(),
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                      // Tombstone first — a throw inside notification
                      // cleanup must never leave the promise alive.
                      await ref
                          .read(intentionsRepositoryProvider)
                          .deleteIntention(intention.id);
                      try {
                        await ref
                            .read(intentionNudgeSyncServiceProvider)
                            .cancelForIntention(intention.id);
                      } catch (_) {
                        // Best-effort; rearmIfStale reconciles slots later.
                      }
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
