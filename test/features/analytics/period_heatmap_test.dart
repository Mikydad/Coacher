import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/blended_discipline.dart';
import 'package:sidepal/features/analytics/application/progress_period_series.dart';
import 'package:sidepal/features/analytics/domain/progress_period.dart';
import 'package:sidepal/features/analytics/presentation/progress/period_heatmap.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';

void main() {
  group('HeatmapLayout', () {
    test('Q3 2026 spans 14 ISO-week columns with three month labels', () {
      final q = ProgressPeriod.forDate(ProgressHorizon.quarter, DateTime(2026, 8, 1));
      final l = HeatmapLayout(q);
      // 1 Jul 2026 is a Wednesday → grid starts Mon 29 Jun; 30 Sep is a
      // Wednesday → last column starts Mon 28 Sep.
      expect(l.gridStart, DateTime(2026, 6, 29));
      expect(l.columns, 14);
      expect(l.monthLabels.values.toList(), ['Jul', 'Aug', 'Sep']);
      expect(l.monthLabels.keys.first, 0);
      expect(l.dateAt(0, 2), DateTime(2026, 7, 1));
      expect(l.dateAt(13, 2), DateTime(2026, 9, 30));
    });

    test('a year spans 53 columns at most and labels twelve months', () {
      for (final y in [2024, 2026, 2027]) {
        final l = HeatmapLayout(ProgressPeriod.forDate(ProgressHorizon.year, DateTime(y, 5, 5)));
        expect(l.columns, inInclusiveRange(52, 54), reason: '$y');
        expect(l.monthLabels.length, 12, reason: '$y');
      }
    });
  });

  testWidgets('PeriodHeatmap paints without overflow at phone width', (tester) async {
    final year = ProgressPeriod.forDate(ProgressHorizon.year, DateTime(2026, 9, 12));
    final series = assembleProgressPeriodSeries(
      period: year,
      goalByKey: const {},
      taskByKey: const {},
      protectedDateKeys: const {},
      mode: EnforcementMode.flexible,
      now: DateTime(2026, 9, 12),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 335, child: PeriodHeatmap(series: series, todayKey: '2026-09-12')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(series.days.first.state, RingState.quiet);
  });
}
