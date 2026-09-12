import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/blended_discipline.dart';
import 'package:sidepal/features/analytics/application/progress_period_series.dart';
import 'package:sidepal/features/analytics/domain/progress_period.dart';
import 'package:sidepal/features/analytics/presentation/progress/day_ring.dart';
import 'package:sidepal/features/analytics/presentation/progress/month_calendar_grid.dart';
import 'package:sidepal/features/analytics/presentation/progress/period_switcher.dart';
import 'package:sidepal/features/analytics/presentation/progress/week_ring_strip.dart';

ProgressDayPoint _point(String key, RingState state, [double? v]) =>
    ProgressDayPoint(dateKey: key, goal: null, task: null, blended: v, state: state);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 375, child: child)),
);

void main() {
  const today = '2026-09-12';

  testWidgets('week strip renders seven rings Monday first and reports taps', (tester) async {
    final week = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2026, 9, 12));
    final days = [
      for (final k in week.dateKeys)
        _point(k, k.compareTo(today) > 0 ? RingState.future : RingState.qualified, 1.0),
    ];
    String? tapped;
    await tester.pumpWidget(
      _host(
        WeekRingStrip(
          days: days,
          selectedDateKey: today,
          todayKey: today,
          onTapDay: (k) => tapped = k,
        ),
      ),
    );
    expect(find.byType(DayRing), findsNWidgets(7));
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // Monday 7 Sep
    await tester.tap(find.text('8'));
    expect(tapped, '2026-09-08');
  });

  testWidgets('month grid: in-month days tappable, leading days muted and inert', (tester) async {
    final month = ProgressPeriod.forDate(ProgressHorizon.month, DateTime(2026, 9, 12));
    final days = [
      for (final k in month.dateKeys)
        _point(k, k.compareTo(today) > 0 ? RingState.future : RingState.partial, 0.5),
    ];
    final taps = <String>[];
    await tester.pumpWidget(
      _host(
        MonthCalendarGrid(
          period: month,
          days: days,
          selectedDateKey: null,
          todayKey: today,
          onTapDay: taps.add,
        ),
      ),
    );
    // 42 cells: 31 in September + 11 leading/trailing.
    expect(find.byType(DayRing), findsNWidgets(42));
    // 1 Sep 2026 is a Tuesday → Monday 31 Aug leads the grid.
    final leading = tester.widget<DayRing>(find.byType(DayRing).first);
    expect(leading.dayNumber, 31);
    expect(leading.muted, isTrue);
    expect(leading.onTap, isNull);

    await tester.tap(
      find.byWidgetPredicate((w) => w is DayRing && !w.muted && w.dayNumber == 3),
    );
    expect(taps, ['2026-09-03']);

    // Future day: not tappable.
    final future = tester.widgetList<DayRing>(find.byType(DayRing))
        .firstWhere((r) => !r.muted && r.dayNumber == 20);
    expect(future.onTap, isNull);
  });

  testWidgets('switcher shows five horizons and reports the tapped one', (tester) async {
    ProgressHorizon? picked;
    await tester.pumpWidget(
      _host(
        PeriodSwitcher(value: ProgressHorizon.day, onChanged: (h) => picked = h),
      ),
    );
    for (final l in ['Day', 'Week', 'Month', 'Quarter', 'Year']) {
      expect(find.text(l), findsOneWidget);
    }
    await tester.tap(find.text('Quarter'));
    expect(picked, ProgressHorizon.quarter);
  });
}
