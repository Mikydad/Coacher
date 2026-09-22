import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_ui.dart';
import '../../../../core/tier/tier_providers.dart';
import '../../../../core/tier/upgrade_prompt.dart';
import '../../../../core/utils/date_keys.dart';
import '../../application/progress_period_providers.dart';
import '../../application/progress_period_series.dart';
import '../../application/progress_selection.dart';
import '../../domain/progress_period.dart';
import 'day_detail_card.dart';
import 'day_suggestions_card.dart';
import 'day_hero.dart';
import 'direction_line.dart';
import 'month_bars.dart';
import 'month_calendar_grid.dart';
import 'period_heatmap.dart';
import 'period_nav.dart';
import 'period_rollup_card.dart';
import 'period_switcher.dart';
import 'progress_period_skeleton.dart';
import 'progress_pro_gate.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';
import 'scope_split_card.dart';
import 'week_ring_strip.dart';

const _kSwitch = Duration(milliseconds: 260);

/// Switcher → nav → hero → rollup → split → (day detail). Everything below
/// the switcher animates on period change; nothing snaps.
class ProgressPeriodBody extends ConsumerWidget {
  const ProgressPeriodBody({super.key, this.ringSweep = 1.0});

  /// Intro animation value for the Day hero arc.
  final double ringSweep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(progressSelectionProvider);
    final controller = ref.read(progressSelectionProvider.notifier);
    final seriesAsync = ref.watch(
      progressPeriodSeriesProvider(selection.period),
    );
    final period = selection.period;
    // Day is free; history (Week and beyond) is Pro. Dormant until
    // tier enforcement ships, like every other gate.
    final blocked =
        period.horizon != ProgressHorizon.day &&
        !ref.watch(tierGateProvider).canViewProgressHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSwitcher(
          value: selection.horizon,
          onChanged: controller.setHorizon,
        ),
        const SizedBox(height: 18),
        ProgressProGate(
          blocked: blocked,
          onUnlock: () => showTierLimitSheet(
            context,
            title: 'Progress history is Pro',
            message:
                'Today is always free. Week, month, quarter and year views — '
                'every past day as a ring, with what happened that day — '
                'come with SidePal Pro.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PeriodNav(
                period: period,
                onPrevious: controller.previous,
                onNext: period.next.startsAfterToday() ? null : controller.next,
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: _kSwitch,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('${period.horizon.name}:${period.key}'),
                  child: seriesAsync.when(
                    skipLoadingOnReload: true,
                    loading: () =>
                        ProgressPeriodSkeleton(horizon: period.horizon),
                    error: (e, _) => swallowedAsyncError(
                      'progress_period_body',
                      e,
                      ProgressTonalCard(
                        child: Text(
                          'Could not load this period.',
                          style: TextStyle(
                            color: ProgressDesignTokens.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    data: (series) => _PeriodContent(
                      series: series,
                      selection: selection,
                      onTapDay: controller.toggleDay,
                      ringSweep: ringSweep,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodContent extends StatelessWidget {
  const _PeriodContent({
    required this.series,
    required this.selection,
    required this.onTapDay,
    required this.ringSweep,
  });

  final ProgressPeriodSeries series;
  final ProgressSelection selection;
  final ValueChanged<String> onTapDay;
  final double ringSweep;

  @override
  Widget build(BuildContext context) {
    final todayKey = DateKeys.todayKey();
    final selected = selection.selectedDateKey;
    final selectedPoint = selected == null ? null : series.pointFor(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(todayKey),
        // The tapped day's detail sits right under the rings, so a tap
        // changes what is beneath the thumb; the period totals follow,
        // each labelled with the period they cover.
        AnimatedSize(
          duration: _kSwitch,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: _kSwitch,
            child: selectedPoint == null || !selection.supportsDayDetail
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(selectedPoint.dateKey),
                    padding: const EdgeInsets.only(top: 12),
                    child: DayDetailCard(point: selectedPoint),
                  ),
          ),
        ),
        const SizedBox(height: ProgressDesignTokens.sectionSpacing),
        PeriodRollupCard(series: series),
        const SizedBox(height: 12),
        ScopeSplitCard(
          goalRate: series.goalRate,
          taskRate: series.taskRate,
          scopeLabel: series.period.scopeLabel(),
        ),
      ],
    );
  }

  Widget _hero(String todayKey) {
    switch (series.period.horizon) {
      case ProgressHorizon.day:
        final point = series.days.first;
        return Column(
          children: [
            DayHero(
              point: point,
              isToday: point.dateKey == todayKey,
              sweep: ringSweep,
            ),
            // Suggestions live here now (2026-09-22), today only.
            if (point.dateKey == todayKey) const DaySuggestionsCard(),
          ],
        );
      case ProgressHorizon.week:
        return ProgressTonalCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: WeekRingStrip(
            days: series.days,
            selectedDateKey: selection.selectedDateKey,
            onTapDay: onTapDay,
            todayKey: todayKey,
          ),
        );
      case ProgressHorizon.month:
        return ProgressTonalCard(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          child: MonthCalendarGrid(
            period: series.period,
            days: series.days,
            selectedDateKey: selection.selectedDateKey,
            onTapDay: onTapDay,
            todayKey: todayKey,
          ),
        );
      case ProgressHorizon.quarter:
      case ProgressHorizon.year:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DirectionLine(period: series.period),
            ProgressTonalCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: PeriodHeatmap(series: series, todayKey: todayKey),
            ),
            const SizedBox(height: 12),
            ProgressTonalCard(
              child: MonthBars(period: series.period, rates: series.monthRates),
            ),
          ],
        );
    }
  }
}
