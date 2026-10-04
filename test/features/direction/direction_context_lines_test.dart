import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/direction/domain/direction_context_lines.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';

DirectionEntry _entry(DirectionHorizon h, DateTime at, String text) {
  return DirectionEntry.forPeriod(
    DirectionPeriods.current(h, at),
    text: text,
    nowMs: at.millisecondsSinceEpoch,
  );
}

void main() {
  final now = DateTime(2026, 9, 11, 22);

  test('nothing set → no lines, three empty slots', () {
    expect(buildDirectionContextLines(const [], now), isEmpty);
    final slots = resolveDirectionSlots(const [], now);
    expect(slots.length, 3);
    for (final s in slots.values) {
      expect(s.current, isNull);
      expect(s.suggestion, isNull);
      expect(s.hasText, isFalse);
    }
  });

  test('current-period entries render in year → quarter → month order', () {
    final lines = buildDirectionContextLines([
      _entry(DirectionHorizon.month, now, 'Get SidePal ready for launch'),
      _entry(DirectionHorizon.year, now, 'Build a successful business'),
      _entry(DirectionHorizon.quarter, now, 'Launch SidePal'),
    ], now);
    expect(lines, [
      'This year (2026): Build a successful business',
      'This quarter (Q3 2026): Launch SidePal',
      'This month (September): Get SidePal ready for launch',
    ]);
  });

  test('empty horizons are simply omitted', () {
    final lines = buildDirectionContextLines([
      _entry(DirectionHorizon.month, now, 'Ship it'),
      _entry(DirectionHorizon.year, now, ''),
    ], now);
    expect(lines, ['This month (September): Ship it']);
  });

  test('a previous period is NEVER sent as context', () {
    final august = DateTime(2026, 8, 20);
    final entries = [
      _entry(DirectionHorizon.month, august, 'Get SidePal ready for launch'),
      _entry(DirectionHorizon.year, DateTime(2025, 3, 1), 'Old year'),
    ];
    expect(buildDirectionContextLines(entries, now), isEmpty);

    // …but it IS the page's suggestion (history ≠ current direction).
    final slots = resolveDirectionSlots(entries, now);
    final month = slots[DirectionHorizon.month]!;
    expect(month.current, isNull);
    expect(month.suggestion, 'Get SidePal ready for launch');
    expect(month.previousPeriod.label, 'August');
    // Year: 2025 is not "previous" text for 2026 only if it's the previous
    // period — it is, so it is suggested; still never context.
    expect(slots[DirectionHorizon.year]!.suggestion, 'Old year');
  });

  test('suggestion disappears once the current period has text', () {
    final august = DateTime(2026, 8, 20);
    final slots = resolveDirectionSlots([
      _entry(DirectionHorizon.month, august, 'August focus'),
      _entry(DirectionHorizon.month, now, 'September focus'),
    ], now);
    final month = slots[DirectionHorizon.month]!;
    expect(month.text, 'September focus');
    expect(month.suggestion, isNull);
  });

  test('a cleared current entry still surfaces the suggestion', () {
    final august = DateTime(2026, 8, 20);
    final slots = resolveDirectionSlots([
      _entry(DirectionHorizon.month, august, 'August focus'),
      _entry(DirectionHorizon.month, now, ''),
    ], now);
    final month = slots[DirectionHorizon.month]!;
    expect(month.current, isNotNull);
    expect(month.hasText, isFalse);
    expect(month.suggestion, 'August focus');
  });

  test('mostSpecificDirectionSlot falls back month → quarter → year', () {
    final onlyYear = resolveDirectionSlots([
      _entry(DirectionHorizon.year, now, 'Year'),
    ], now);
    expect(mostSpecificDirectionSlot(onlyYear)!.text, 'Year');

    final all = resolveDirectionSlots([
      _entry(DirectionHorizon.year, now, 'Year'),
      _entry(DirectionHorizon.quarter, now, 'Quarter'),
      _entry(DirectionHorizon.month, now, 'Month'),
    ], now);
    expect(mostSpecificDirectionSlot(all)!.text, 'Month');
    expect(
      mostSpecificDirectionSlot(resolveDirectionSlots(const [], now)),
      isNull,
    );
  });

  test('previous period with text and no answer → closeout on the slot', () {
    final august = _entry(DirectionHorizon.month, DateTime(2026, 8, 5), 'Rest');
    final slots = resolveDirectionSlots([august], now);
    expect(slots[DirectionHorizon.month]!.closeout?.id, august.id);
    expect(slots[DirectionHorizon.month]!.previous?.id, august.id);

    final answered = august.copyWith(
      outcome: DirectionOutcome.partly,
      outcomeAtMs: 1,
    );
    final done = resolveDirectionSlots([answered], now);
    expect(done[DirectionHorizon.month]!.closeout, isNull);
    expect(
      done[DirectionHorizon.month]!.previous?.outcome,
      DirectionOutcome.partly,
    );
    // The suggestion still carries the text for "Keep".
    expect(done[DirectionHorizon.month]!.suggestion, 'Rest');
  });
}
