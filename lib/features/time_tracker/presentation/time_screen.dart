import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart' show insightCacheRepositoryProvider;
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/presentation/swipe_actions.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../education/presentation/help_dot.dart';
import '../application/time_tracker_providers.dart';
import '../domain/day_summary.dart';
import '../domain/duration_format.dart';
import '../domain/models/activity_event.dart';
import '../domain/timeline_builder.dart';
import '../domain/week_periods.dart';
import 'track_activity_sheet.dart';

/// The Time page (PRD/Time_Tracker §5.2 + V1.2 §5): one day's timeline
/// with the gaps left honest, a per-activity summary at the bottom, a day
/// pager, and since V1.2 a Day | Week toggle, planned-vs-actual on
/// timer-sourced rows, and the only place AI time observations ever show.
/// Today: view + create + edit + delete. Previous days: view only
/// (decision F4). Never a score, never a streak, never a judgment.
///
/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.
class TimeScreen extends ConsumerStatefulWidget {
  const TimeScreen({super.key});

  static const routeName = '/time';

  @override
  ConsumerState<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends ConsumerState<TimeScreen> {
  @override
  void initState() {
    super.initState();
    // The page always opens on today (day view); paging is in-page state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(timelineDayKeyProvider.notifier).state = DateKeys.todayKey();
      ref.read(timelineWeekKeyProvider.notifier).state =
          WeekPeriods.of(DateTime.now()).key;
    });
  }

  void _shiftDay(int days) {
    final current = DateKeys.parseLocalDateKey(
      ref.read(timelineDayKeyProvider),
    );
    final next = DateTime(current.year, current.month, current.day + days);
    ref.read(timelineDayKeyProvider.notifier).state = DateKeys.yyyymmdd(next);
  }

  void _shiftWeek(int weeks) {
    final current = weekPeriodForKey(ref.read(timelineWeekKeyProvider));
    final next = weeks < 0
        ? WeekPeriods.previous(current)
        : WeekPeriods.next(current);
    ref.read(timelineWeekKeyProvider.notifier).state = next.key;
  }

  Future<void> _delete(ActivityEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(event.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const ValueKey('time_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(timeTrackerActionsProvider).delete(event.id);
  }

  Future<void> _dismissObservation(String scopeId) async {
    await dismissTimeObservation(
      ref.read(insightCacheRepositoryProvider),
      scopeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(timelineModeProvider);
    final dateKey = ref.watch(timelineDayKeyProvider);
    final isToday = dateKey == DateKeys.todayKey();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const PageTitle('Time'),
        centerTitle: true,
        actions: const [HelpAppBarButton('time')],
      ),
      floatingActionButton: mode == TimelineMode.day && isToday
          ? FloatingActionButton.extended(
              key: const ValueKey('time_track_fab'),
              heroTag: 'time_track_fab',
              onPressed: () => showTrackActivitySheet(context),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              icon: const Icon(Icons.add),
              label: const Text('Track'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          _ModeToggle(
            mode: mode,
            onChanged: (m) => ref.read(timelineModeProvider.notifier).state = m,
          ),
          const SizedBox(height: 14),
          if (mode == TimelineMode.day)
            _DayBody(
              dateKey: dateKey,
              isToday: isToday,
              onPrevious: () => _shiftDay(-1),
              onNext: isToday ? null : () => _shiftDay(1),
              onDelete: _delete,
              onDismissObservation: _dismissObservation,
            )
          else
            _WeekBody(
              onPrevious: () => _shiftWeek(-1),
              onNext: () => _shiftWeek(1),
              onDismissObservation: _dismissObservation,
            ),
        ],
      ),
    );
  }
}

// ─── Day | Week toggle ────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final TimelineMode mode;
  final ValueChanged<TimelineMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<TimelineMode>(
        key: const ValueKey('time_mode_toggle'),
        segments: const [
          ButtonSegment(value: TimelineMode.day, label: Text('Day')),
          ButtonSegment(value: TimelineMode.week, label: Text('Week')),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Day view ─────────────────────────────────────────────────────────────────

class _DayBody extends ConsumerWidget {
  const _DayBody({
    required this.dateKey,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onDelete,
    required this.onDismissObservation,
  });

  final String dateKey;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final Future<void> Function(ActivityEvent) onDelete;
  final Future<void> Function(String scopeId) onDismissObservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(timelineRowsProvider(dateKey));
    final summary = ref.watch(daySummaryProvider(dateKey));
    final loaded = ref.watch(dayEventsProvider(dateKey)).hasValue;
    final dayScope = timeObservationScopeId('day', dateKey);
    final observation = ref.watch(timeObservationProvider(dayScope));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayPager(
          dateKey: dateKey,
          isToday: isToday,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(height: 20),
        const SectionHeader('Timeline'),
        const SizedBox(height: 10),
        if (loaded && rows.isEmpty)
          _EmptyTimeline(isToday: isToday)
        else
          // Newest first (Miko, 2026-09-12): the current entry is the first
          // thing on screen. Display order only — the builder, the Coach's
          // text and the reflection snapshot stay chronological.
          for (final row in rows.reversed)
            switch (row) {
              ActivityRow() => _ActivityTile(
                row: row,
                editable: isToday,
                onEdit: () => showTrackActivitySheet(context, edit: row.event),
                onDelete: () => onDelete(row.event),
              ),
              UntrackedRow() => _UntrackedTile(
                row: row,
                // V1.1 gap tap: "what happened here?" — opens the sheet at
                // the gap's start. Today only; previous days stay inert.
                onTap: isToday
                    ? () => showTrackActivitySheet(
                        context,
                        presetStartMs: row.fromMs,
                      )
                    : null,
              ),
            },
        if (!summary.isEmpty) ...[
          const SizedBox(height: 28),
          const SectionHeader('Summary'),
          const SizedBox(height: 10),
          _SummaryBlock(
            logged: summary.logged,
            untracked: summary.untracked,
            lines: summary.lines,
            categoryLines: summary.categoryLines,
          ),
        ],
        if (observation != null) ...[
          const SizedBox(height: 24),
          _ObservationBlock(
            heading: 'Something I noticed',
            insight: observation,
            onDismiss: () => onDismissObservation(dayScope),
          ),
        ],
      ],
    );
  }
}

class _DayPager extends StatelessWidget {
  const _DayPager({
    required this.dateKey,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
  });

  final String dateKey;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final day = DateKeys.parseLocalDateKey(dateKey);
    final loc = MaterialLocalizations.of(context);
    final formatted = loc.formatMediumDate(day);
    final yesterday = DateKeys.yyyymmdd(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final prefix = isToday
        ? 'Today'
        : dateKey == yesterday
        ? 'Yesterday'
        : null;
    final label = prefix == null ? formatted : '$prefix · $formatted';
    return _Pager(
      label: label,
      labelKey: const ValueKey('time_day_label'),
      prevKey: const ValueKey('time_prev_day'),
      nextKey: const ValueKey('time_next_day'),
      onPrevious: onPrevious,
      onNext: onNext,
    );
  }
}

// ─── Week view (read-only) ────────────────────────────────────────────────────

class _WeekBody extends ConsumerWidget {
  const _WeekBody({
    required this.onPrevious,
    required this.onNext,
    required this.onDismissObservation,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function(String scopeId) onDismissObservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekKey = ref.watch(timelineWeekKeyProvider);
    final week = weekPeriodForKey(weekKey);
    final thisWeek = WeekPeriods.of(DateTime.now());
    final isThisWeek = week.key == thisWeek.key;
    final summary = ref.watch(weekSummaryProvider(weekKey));
    final loaded = ref.watch(weekEventsProvider(weekKey)).hasValue;
    final weekScope = timeObservationScopeId('week', weekKey);
    final weekObservation = ref.watch(timeObservationProvider(weekScope));
    // The monthly Direction mirror: shown on the current week for the
    // month that just ended (the loop writes it on the first pass of a
    // new month). Direction itself stays quiet.
    final now = DateTime.now();
    final prevMonth = WeekPeriods.monthOf(
      DateTime.fromMillisecondsSinceEpoch(WeekPeriods.monthOf(now).startMs - 1),
    );
    final monthScope = timeObservationScopeId('month', prevMonth.key);
    final monthObservation = isThisWeek
        ? ref.watch(timeObservationProvider(monthScope))
        : null;

    final loc = MaterialLocalizations.of(context);
    final range =
        '${loc.formatMediumDate(week.start)} – ${loc.formatMediumDate(week.lastDay)}';
    final label = isThisWeek ? 'This week · $range' : range;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pager(
          label: label,
          labelKey: const ValueKey('time_week_label'),
          prevKey: const ValueKey('time_prev_week'),
          nextKey: const ValueKey('time_next_week'),
          onPrevious: onPrevious,
          onNext: isThisWeek ? null : onNext,
        ),
        const SizedBox(height: 20),
        const SectionHeader('Your week'),
        const SizedBox(height: 10),
        if (loaded && summary.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nothing logged this week.',
              key: const ValueKey('time_week_empty'),
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          )
        else ...[
          Text(
            '${summary.daysWithEntries} of 7 days with entries',
            key: const ValueKey('time_week_days'),
            style: TextStyle(color: AppColors.textSoft, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _SummaryBlock(
            logged: summary.logged,
            untracked: summary.untracked,
            lines: summary.lines,
            categoryLines: summary.categoryLines,
          ),
        ],
        if (weekObservation != null) ...[
          const SizedBox(height: 24),
          _ObservationBlock(
            heading: 'Something I noticed',
            insight: weekObservation,
            onDismiss: () => onDismissObservation(weekScope),
          ),
        ],
        if (monthObservation != null) ...[
          const SizedBox(height: 24),
          _ObservationBlock(
            heading: 'Your month · ${prevMonth.label}',
            insight: monthObservation,
            onDismiss: () => onDismissObservation(monthScope),
          ),
        ],
      ],
    );
  }
}

// ─── Shared pieces ────────────────────────────────────────────────────────────

class _Pager extends StatelessWidget {
  const _Pager({
    required this.label,
    required this.labelKey,
    required this.prevKey,
    required this.nextKey,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final Key labelKey;
  final Key prevKey;
  final Key nextKey;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: prevKey,
          tooltip: 'Previous',
          icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSoft),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            key: labelKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        IconButton(
          key: nextKey,
          tooltip: 'Next',
          icon: Icon(
            Icons.chevron_right_rounded,
            color: onNext == null ? AppColors.fg38 : AppColors.textSoft,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

String _clock(BuildContext context, int ms) {
  final loc = MaterialLocalizations.of(context);
  return loc.formatTimeOfDay(
    TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms)),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Tall enough for the shared swipe pane (icon over label) and for rows to
/// read as separate entries.
const double kActivityRowMinHeight = 56;

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({
    required this.row,
    required this.editable,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityRow row;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = row.event;
    final actual = row.actual;
    final intended = row.intended;

    final String trailing;
    switch (row.endSource) {
      case EndSource.ongoing:
        trailing = 'Ongoing';
      case EndSource.capped:
        trailing = '';
      case EndSource.explicit:
      case EndSource.nextEvent:
        trailing = formatActivityDuration(actual!);
    }

    final details = <({String text, Key? key})>[];
    if (intended != null) {
      final planned = 'Planned ${formatActivityDuration(intended)}';
      details.add((
        text: actual == null
            ? planned
            : '$planned · Actual ${formatActivityDuration(actual)}',
        key: null,
      ));
    }
    // V1.2 planned-vs-actual: timer-sourced rows only (exact task link).
    final entityId = e.sourceEntityId ?? '';
    if (e.isTimerSourced && entityId.isNotEmpty) {
      final block = ref.watch(plannedBlockForEntityProvider(entityId)).valueOrNull;
      if (block != null && DateKeys.todayKey(block.startAt) == e.dateKey) {
        final line = StringBuffer(
          'Planned ${_clock(context, block.startAt.millisecondsSinceEpoch)}'
          '–${_clock(context, block.computedEndAt.millisecondsSinceEpoch)}'
          ' · Started ${_clock(context, e.startedAtMs)}',
        );
        if (e.endedAtMs != null) {
          line.write(' · Ended ${_clock(context, e.endedAtMs!)}');
        }
        details.add((
          text: line.toString(),
          key: const ValueKey('time_planned_vs_actual'),
        ));
      }
    }

    final tile = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kActivityRowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 74,
              child: Text(
                _clock(context, e.startedAtMs),
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.text,
                          style: TextStyle(
                            color: AppColors.fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (e.isTimerSourced) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.timer_outlined,
                          key: const ValueKey('time_timer_glyph'),
                          size: 13,
                          color: AppColors.textSoft,
                        ),
                      ],
                    ],
                  ),
                  for (final d in details) ...[
                    const SizedBox(height: 2),
                    Text(
                      d.text,
                      key: d.key,
                      style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: TextStyle(
                color: row.isOngoing ? AppColors.accent : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontStyle: row.isOngoing ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );

    if (!editable) return tile;
    return SwipeActionsRow(
      id: e.id,
      groupTag: 'time-rows',
      onEdit: onEdit,
      onDelete: onDelete,
      child: tile,
    );
  }
}

class _UntrackedTile extends StatelessWidget {
  const _UntrackedTile({required this.row, this.onTap});

  final UntrackedRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('time_untracked_${row.fromMs}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Text(
                '?',
                style: TextStyle(
                  color: AppColors.fg38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                onTap == null
                    ? '${formatActivityDuration(row.length)} untracked'
                    : '${formatActivityDuration(row.length)} untracked · tap to fill in',
                key: const ValueKey('time_untracked_row'),
                style: TextStyle(
                  color: AppColors.fg38,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        isToday ? 'Nothing logged yet.' : 'Nothing logged.',
        key: const ValueKey('time_empty'),
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

/// Totals: category chips (when any rule matches) above the by-activity
/// list. Shared by the day and week views.
class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.logged,
    required this.untracked,
    required this.lines,
    required this.categoryLines,
  });

  final Duration logged;
  final Duration untracked;
  final List<SummaryLine> lines;
  final List<SummaryLine> categoryLines;

  @override
  Widget build(BuildContext context) {
    final head = StringBuffer('You logged ${formatActivityDuration(logged)}');
    if (untracked > Duration.zero) {
      head.write(' · Untracked ${formatActivityDuration(untracked)}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          head.toString(),
          key: const ValueKey('time_summary_head'),
          style: TextStyle(
            color: AppColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (categoryLines.isNotEmpty) ...[
          Wrap(
            key: const ValueKey('time_summary_categories'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final line in categoryLines)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fg.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${line.label} ${formatActivityDuration(line.total)}',
                    style: TextStyle(
                      color: AppColors.fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _MicroLabel('By activity'),
          const SizedBox(height: 6),
        ],
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    line.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                Text(
                  formatActivityDuration(line.total),
                  style: TextStyle(
                    color: AppColors.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Something I noticed" — an AI-inferred, tone-checked observation. Shown
/// only here (decision 9); labelled INFERRED; dismiss clears it for good.
class _ObservationBlock extends StatelessWidget {
  const _ObservationBlock({
    required this.heading,
    required this.insight,
    required this.onDismiss,
  });

  final String heading;
  final GeneratedInsight insight;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('time_observation'),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.fg.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: _MicroLabel(heading)),
                    const SizedBox(width: 8),
                    Text(
                      'INFERRED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.fg38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  insight.message,
                  key: const ValueKey('time_observation_message'),
                  style: TextStyle(
                    color: AppColors.fg,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('time_observation_dismiss'),
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, size: 16, color: AppColors.textSoft),
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textSoft,
      ),
    );
  }
}
