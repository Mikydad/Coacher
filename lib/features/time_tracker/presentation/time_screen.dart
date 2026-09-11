import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/presentation/swipe_actions.dart';
import '../../../core/utils/date_keys.dart';
import '../../education/presentation/help_dot.dart';
import '../application/time_tracker_providers.dart';
import '../domain/day_summary.dart';
import '../domain/duration_format.dart';
import '../domain/models/activity_event.dart';
import '../domain/timeline_builder.dart';
import 'track_activity_sheet.dart';

/// The Time page (PRD/Time_Tracker §5.2): one day's timeline with the gaps
/// left honest, a per-activity summary at the bottom, and a day pager.
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
    // The page always opens on today; paging is in-page state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(timelineDayKeyProvider.notifier).state = DateKeys.todayKey();
      }
    });
  }

  void _shiftDay(int days) {
    final current = DateKeys.parseLocalDateKey(
      ref.read(timelineDayKeyProvider),
    );
    final next = DateTime(current.year, current.month, current.day + days);
    ref.read(timelineDayKeyProvider.notifier).state = DateKeys.yyyymmdd(next);
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

  @override
  Widget build(BuildContext context) {
    final dateKey = ref.watch(timelineDayKeyProvider);
    final todayKey = DateKeys.todayKey();
    final isToday = dateKey == todayKey;
    final rows = ref.watch(timelineRowsProvider(dateKey));
    final summary = ref.watch(daySummaryProvider(dateKey));
    final loaded = ref.watch(dayEventsProvider(dateKey)).hasValue;

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
      floatingActionButton: isToday
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
          _DayPager(
            dateKey: dateKey,
            isToday: isToday,
            onPrevious: () => _shiftDay(-1),
            onNext: isToday ? null : () => _shiftDay(1),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Timeline'),
          const SizedBox(height: 10),
          if (loaded && rows.isEmpty)
            _EmptyTimeline(isToday: isToday)
          else
            for (final row in rows)
              switch (row) {
                ActivityRow() => _ActivityTile(
                  row: row,
                  editable: isToday,
                  onEdit: () =>
                      showTrackActivitySheet(context, edit: row.event),
                  onDelete: () => _delete(row.event),
                ),
                UntrackedRow() => _UntrackedTile(row: row),
              },
          if (!summary.isEmpty) ...[
            const SizedBox(height: 28),
            const SectionHeader('Summary'),
            const SizedBox(height: 10),
            _SummaryBlock(summary: summary),
          ],
        ],
      ),
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

    return Row(
      children: [
        IconButton(
          key: const ValueKey('time_prev_day'),
          tooltip: 'Previous day',
          icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSoft),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            key: const ValueKey('time_day_label'),
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
          key: const ValueKey('time_next_day'),
          tooltip: 'Next day',
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

class _ActivityTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

    String? detail;
    if (intended != null) {
      final planned = 'Planned ${formatActivityDuration(intended)}';
      detail = actual == null
          ? planned
          : '$planned · Actual ${formatActivityDuration(actual)}';
    }

    // Min height 56 (device test 2026-09-12): the shared swipe pane stacks
    // an icon over a label (~40 px) and overflowed on 39 px rows, and the
    // rows read as cramped. Rows now breathe and the pane always fits.
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
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
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
  const _UntrackedTile({required this.row});

  final UntrackedRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              '${formatActivityDuration(row.length)} untracked',
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

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final head = StringBuffer(
      'You logged ${formatActivityDuration(summary.logged)}',
    );
    if (summary.untracked > Duration.zero) {
      head.write(' · Untracked ${formatActivityDuration(summary.untracked)}');
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
        for (final line in summary.lines)
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
