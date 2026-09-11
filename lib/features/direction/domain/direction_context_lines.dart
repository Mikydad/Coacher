import 'direction_periods.dart';
import 'models/direction_entry.dart';

/// The user's current direction, resolved against a clock — the ONE place
/// that decides what "current" means for the page, the strip, the Home
/// card and all three AI readers.
///
/// **Key rule (Miko, 2026-09-11):** a previous Direction can inform history
/// or be offered as a suggestion, but it must never be treated as the user's
/// current Direction unless the user explicitly carries it forward. So
/// [DirectionSlot.suggestion] exists for the page only; nothing here ever
/// promotes it to context.
class DirectionSlot {
  const DirectionSlot({
    required this.period,
    required this.current,
    required this.suggestion,
  });

  /// The calendar period for this horizon at `now`.
  final DirectionPeriod period;

  /// The entry for [period], if the user ever wrote one (may be cleared).
  final DirectionEntry? current;

  /// Previous period's text, offered on the page as "Last month: … · Keep".
  /// Only present when [current] is null or empty AND the previous period
  /// had text. Never context.
  final String? suggestion;

  /// The previous period, for labelling the suggestion ("Last month").
  DirectionPeriod get previousPeriod => DirectionPeriods.previous(period);

  bool get hasText => current?.isNotEmpty ?? false;
  String get text => current?.text ?? '';
}

const List<DirectionHorizon> kDirectionHorizonOrder = [
  DirectionHorizon.year,
  DirectionHorizon.quarter,
  DirectionHorizon.month,
];

/// Resolve the three current slots from every stored row (history included).
Map<DirectionHorizon, DirectionSlot> resolveDirectionSlots(
  List<DirectionEntry> entries,
  DateTime now,
) {
  final byId = {for (final e in entries) e.id: e};
  final slots = <DirectionHorizon, DirectionSlot>{};
  for (final horizon in kDirectionHorizonOrder) {
    final period = DirectionPeriods.current(horizon, now);
    final current = byId[directionEntryId(horizon, period.key)];
    String? suggestion;
    if (current == null || current.isEmpty) {
      final prev = DirectionPeriods.previous(period);
      final prevEntry = byId[directionEntryId(horizon, prev.key)];
      if (prevEntry != null && prevEntry.isNotEmpty) {
        suggestion = prevEntry.text;
      }
    }
    slots[horizon] = DirectionSlot(
      period: period,
      current: current,
      suggestion: suggestion,
    );
  }
  return slots;
}

/// Compact, ordered lines for the AI readers (Coach, insight phrasing,
/// Thinking Loop):
///
/// ```
/// This year (2026): Build a successful business
/// This quarter (Q3 2026): Launch SidePal
/// This month (September): Get SidePal ready for launch
/// ```
///
/// Current period only. Empty horizons are omitted; a previous period is
/// NEVER sent as context (history ≠ current direction). Empty list when
/// nothing is set — callers omit the whole block.
List<String> buildDirectionContextLines(
  List<DirectionEntry> entries,
  DateTime now,
) {
  final slots = resolveDirectionSlots(entries, now);
  final lines = <String>[];
  for (final horizon in kDirectionHorizonOrder) {
    final slot = slots[horizon]!;
    if (!slot.hasText) continue;
    lines.add('${_horizonPhrase(horizon)} (${slot.period.label}): ${slot.text}');
  }
  return lines;
}

String _horizonPhrase(DirectionHorizon h) => switch (h) {
  DirectionHorizon.year => 'This year',
  DirectionHorizon.quarter => 'This quarter',
  DirectionHorizon.month => 'This month',
};

/// The strip / Profile-subtitle fallback order: month → quarter → year.
DirectionSlot? mostSpecificDirectionSlot(
  Map<DirectionHorizon, DirectionSlot> slots,
) {
  for (final h in kDirectionHorizonOrder.reversed) {
    final slot = slots[h];
    if (slot != null && slot.hasText) return slot;
  }
  return null;
}
