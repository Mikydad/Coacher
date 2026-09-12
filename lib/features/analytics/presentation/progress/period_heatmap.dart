import 'package:flutter/material.dart';

import '../../../../core/utils/date_keys.dart';
import '../../application/blended_discipline.dart';
import '../../application/progress_period_series.dart';
import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Column layout for a week-column heatmap: one column per ISO week from
/// the Monday on/before the period's first day to the Sunday on/after its
/// last day. Pure; unit-tested.
class HeatmapLayout {
  HeatmapLayout(this.period)
    : gridStart = DateTime(
        period.start.year,
        period.start.month,
        period.start.day - (period.start.weekday - 1),
      ) {
    final lastMonday = DateTime(
      period.end.year,
      period.end.month,
      period.end.day - (period.end.weekday - 1),
    );
    columns = _weeksBetween(gridStart, lastMonday) + 1;
    monthLabels = _monthLabels();
  }

  final ProgressPeriod period;

  /// Monday of the first column (may precede the period).
  final DateTime gridStart;
  late final int columns;

  /// Column index → short month name, for months whose 1st falls in that
  /// column. Two labels never share a column.
  late final Map<int, String> monthLabels;

  DateTime dateAt(int column, int row) => DateTime(
    gridStart.year,
    gridStart.month,
    gridStart.day + column * 7 + row,
  );

  Map<int, String> _monthLabels() {
    final out = <int, String>{};
    var cursor = DateTime(period.start.year, period.start.month, 1);
    while (!cursor.isAfter(period.end)) {
      final monday = DateTime(cursor.year, cursor.month, cursor.day - (cursor.weekday - 1));
      out[_weeksBetween(gridStart, monday)] = _shortMonths[cursor.month - 1];
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return out;
  }

  static int _weeksBetween(DateTime mondayA, DateTime mondayB) {
    final a = DateTime.utc(mondayA.year, mondayA.month, mondayA.day);
    final b = DateTime.utc(mondayB.year, mondayB.month, mondayB.day);
    return b.difference(a).inDays ~/ 7;
  }
}

/// Quarter (≈13 columns) and Year (≈53 columns) at a glance: weeks as
/// columns, Monday → Sunday as rows, cell colour = blended rate. Density,
/// not individual days — cells are not tappable (PRD §7).
class PeriodHeatmap extends StatelessWidget {
  const PeriodHeatmap({super.key, required this.series, this.todayKey});

  final ProgressPeriodSeries series;
  final String? todayKey;

  static const double _gap = 2;
  static const double _labelHeight = 16;

  @override
  Widget build(BuildContext context) {
    final layout = HeatmapLayout(series.period);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - _gap * (layout.columns - 1)) /
                layout.columns)
            .clamp(3.0, 22.0);
        final height = _labelHeight + cell * 7 + _gap * 6;
        return Semantics(
          label: '${series.period.label} heatmap',
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _HeatmapPainter(
                layout: layout,
                byKey: {for (final d in series.days) d.dateKey: d},
                todayKey: todayKey ?? DateKeys.todayKey(),
                cell: cell,
                gap: _gap,
                labelHeight: _labelHeight,
                textStyle: TextStyle(
                  color: ProgressDesignTokens.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.layout,
    required this.byKey,
    required this.todayKey,
    required this.cell,
    required this.gap,
    required this.labelHeight,
    required this.textStyle,
  });

  final HeatmapLayout layout;
  final Map<String, ProgressDayPoint> byKey;
  final String todayKey;
  final double cell;
  final double gap;
  final double labelHeight;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final quiet = ProgressDesignTokens.surfaceContainerHigh;
    final missed = ProgressDesignTokens.surfaceContainerHighest;
    final met = ProgressDesignTokens.primaryDim;
    final protected = ProgressDesignTokens.secondary.withValues(alpha: 0.35);
    final radius = Radius.circular(cell >= 8 ? 2.5 : 1);

    // Month labels; skip one that would overlap the previous label.
    double lastLabelEnd = -1e9;
    for (final entry in layout.monthLabels.entries) {
      final x = entry.key * (cell + gap);
      final tp = TextPainter(
        text: TextSpan(text: entry.value, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (x < lastLabelEnd + 4) continue;
      tp.paint(canvas, Offset(x, 0));
      lastLabelEnd = x + tp.width;
    }

    for (var c = 0; c < layout.columns; c++) {
      for (var r = 0; r < 7; r++) {
        final date = layout.dateAt(c, r);
        final key = DateKeys.yyyymmdd(date);
        if (!layout.period.contains(key)) continue;
        final p = byKey[key];
        final state = p?.state ?? RingState.future;
        final Color? color = switch (state) {
          RingState.future => null,
          RingState.quiet => quiet,
          RingState.missed => missed,
          RingState.protected => protected,
          RingState.qualified => met,
          RingState.partial => Color.lerp(
            missed,
            met,
            0.25 + 0.75 * (p?.blended ?? 0).clamp(0.0, 1.0),
          ),
        };
        final rect = Rect.fromLTWH(
          c * (cell + gap),
          labelHeight + r * (cell + gap),
          cell,
          cell,
        );
        if (color != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, radius),
            Paint()..color = color,
          );
        } else {
          // Upcoming: a faint outline so the period's shape stays readable.
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(0.5), radius),
            Paint()
              ..color = quiet.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
        if (key == todayKey) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(1), radius),
            Paint()
              ..color = met
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.byKey != byKey ||
      old.cell != cell ||
      old.todayKey != todayKey ||
      old.layout.period != layout.period;
}
