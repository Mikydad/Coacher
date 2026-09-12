import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';
import '../../../planning/domain/models/task_item.dart';
import '../../../time_tracker/application/time_tracker_providers.dart';
import '../../../time_tracker/presentation/time_screen.dart';
import '../../application/blended_discipline.dart';
import '../../application/progress_day_detail.dart';
import '../../application/progress_period_series.dart';
import '../../domain/progress_period.dart';
import '../../../../core/utils/date_keys.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

/// "What happened that day?" — tasks, goal check-ins, time logged.
/// Time logged is a supporting fact only (decision 2026-09-12).
class DayDetailCard extends ConsumerWidget {
  const DayDetailCard({super.key, required this.point});

  final ProgressDayPoint point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(progressDayDetailProvider(point.dateKey));
    final dayLabel = ProgressPeriod.forDate(
      ProgressHorizon.day,
      DateKeys.parseLocalDateKey(point.dateKey),
    ).scopeLabel();
    return ProgressTonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: ProgressDesignTokens.primaryDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goals ${_pct(point.goalRate)} · Tasks ${_pct(point.taskRate)}',
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StateChip(state: point.state, blended: point.blended),
            ],
          ),
          const SizedBox(height: 16),
          detailAsync.when(
            skipLoadingOnReload: true,
            loading: () => const _DetailPlaceholder(),
            error: (e, _) => swallowedAsyncError(
              'day_detail_card',
              e,
              Text(
                'Could not load this day.',
                style: TextStyle(color: ProgressDesignTokens.onSurfaceVariant),
              ),
            ),
            data: (detail) => _DetailBody(detail: detail),
          ),
        ],
      ),
    );
  }

  static String _pct(double? v) => v == null ? '—' : '${(v * 100).round()}%';
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});
  final ProgressDayDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MicroLabel(
          'Tasks',
          trailing: detail.tasks.isEmpty
              ? null
              : '${detail.tasksDone}/${detail.tasks.length}',
        ),
        const SizedBox(height: 8),
        if (detail.tasks.isEmpty)
          const _EmptyLine('No tasks were planned.')
        else
          for (final t in detail.tasks) _TaskRow(task: t),
        const SizedBox(height: 16),
        const _MicroLabel('Goal check-ins'),
        const SizedBox(height: 8),
        if (detail.checkIns.isEmpty)
          const _EmptyLine('No check-ins logged.')
        else
          for (final c in detail.checkIns) _CheckInRow(checkIn: c),
        const SizedBox(height: 16),
        const _MicroLabel('Time logged'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref.read(timelineDayKeyProvider.notifier).state = detail.dateKey;
            Navigator.of(context).pushNamed(TimeScreen.routeName);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: ProgressDesignTokens.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  detail.timeLoggedLabel,
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: ProgressDesignTokens.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final ProgressDayTask task;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (task.status) {
      TaskStatus.completed => (
        Icons.check_circle_rounded,
        ProgressDesignTokens.primaryDim,
      ),
      TaskStatus.partial => (Icons.adjust_rounded, AppColors.amber),
      TaskStatus.inProgress => (
        Icons.play_circle_outline_rounded,
        ProgressDesignTokens.secondary,
      ),
      TaskStatus.notStarted => (
        Icons.radio_button_unchecked_rounded,
        ProgressDesignTokens.onSurfaceVariant,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: task.isDone
                    ? ProgressDesignTokens.onSurface
                    : ProgressDesignTokens.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (task.isHabitAnchor) ...[
            const SizedBox(width: 8),
            _Tag('habit', color: ProgressDesignTokens.primaryDim),
          ],
          if (task.priority == 1) ...[
            const SizedBox(width: 8),
            _Tag('P1', color: AppColors.coral),
          ],
        ],
      ),
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({required this.checkIn});
  final ProgressDayCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final v = checkIn.value;
    final valueLabel = v == null
        ? null
        : (v == v.roundToDouble()
              ? v.toInt().toString()
              : v.toStringAsFixed(1));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            checkIn.metCommitment
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            size: 18,
            color: checkIn.metCommitment
                ? ProgressDesignTokens.primaryDim
                : ProgressDesignTokens.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              checkIn.goalTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ProgressDesignTokens.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (valueLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: TextStyle(
                color: ProgressDesignTokens.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state, required this.blended});
  final RingState state;
  final double? blended;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      RingState.qualified => ('MET', ProgressDesignTokens.primaryDim),
      RingState.partial => ('PARTIAL', AppColors.amber),
      RingState.missed => ('MISSED', AppColors.coral),
      RingState.quiet => ('QUIET', ProgressDesignTokens.onSurfaceVariant),
      RingState.protected => ('PROTECTED', ProgressDesignTokens.secondary),
      RingState.future => ('UPCOMING', ProgressDesignTokens.onSurfaceVariant),
    };
    final pct = blended == null ? '' : '${(blended! * 100).round()}% · ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$pct$label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: ProgressDesignTokens.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );
    return Row(
      children: [
        Text(text.toUpperCase(), style: style),
        const Spacer(),
        if (trailing != null) Text(trailing!, style: style),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: ProgressDesignTokens.onSurfaceVariant,
        fontSize: 13,
        height: 1.3,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
      width: w,
      height: 12,
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(80),
        const SizedBox(height: 10),
        bar(200),
        const SizedBox(height: 8),
        bar(160),
      ],
    );
  }
}
