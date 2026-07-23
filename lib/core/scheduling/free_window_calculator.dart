/// Shared free-window computation, extracted from AiPayloadAssembler in
/// Phase 1 (PRD §4.3) so the Coach prompt and the OpportunityPlanner use the
/// same definition of "free".
///
/// Pure Dart, deterministic, no I/O — identical results in airplane mode.
library;

/// One free gap inside the waking day, in minutes-of-day.
class FreeWindow {
  const FreeWindow({
    required this.startMinute,
    required this.endMinute,
    this.beforeTitle,
  });

  final int startMinute;
  final int endMinute;

  /// Title of the busy block that ends this gap; null when the gap runs to
  /// the end of the waking day. Powers "20 free minutes before Dinner".
  final String? beforeTitle;

  int get durationMinutes => endMinute - startMinute;
}

class FreeWindowCalculator {
  const FreeWindowCalculator._();

  static const int dayStartMinute = 7 * 60; // 07:00
  static const int dayEndMinute = 22 * 60; // 22:00
  static const int minWindowMinutes = 30;

  /// Structured free windows between scheduled blocks inside the waking day.
  ///
  /// [scheduleMaps] is the `{ title, startTime, endTime }` shape ("HH:mm")
  /// the assembler produces from planned rows. For today pass
  /// [fromMinuteOfDay] so already-past windows are excluded. Windows shorter
  /// than [minWindowMinutes] are dropped.
  static List<FreeWindow> computeWindows(
    List<Map<String, dynamic>> scheduleMaps, {
    int fromMinuteOfDay = 0,
  }) {
    int? parseMinute(Object? hhmm) {
      if (hhmm is! String) return null;
      final parts = hhmm.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    // Collect busy intervals (clamped to the day), keeping titles.
    final busy = <(int, int, String?)>[];
    for (final block in scheduleMaps) {
      final start = parseMinute(block['startTime']);
      if (start == null) continue;
      final end = parseMinute(block['endTime']) ?? (start + 30);
      final clampedStart = start.clamp(0, 24 * 60);
      final clampedEnd = end < start ? clampedStart : end.clamp(0, 24 * 60);
      busy.add((clampedStart, clampedEnd, block['title'] as String?));
    }
    busy.sort((a, b) => a.$1.compareTo(b.$1));

    // Merge overlaps; a merged interval keeps the earliest block's title
    // (that block is what the preceding gap runs into).
    final merged = <(int, int, String?)>[];
    for (final interval in busy) {
      if (merged.isEmpty || interval.$1 > merged.last.$2) {
        merged.add(interval);
      } else if (interval.$2 > merged.last.$2) {
        merged[merged.length - 1] = (
          merged.last.$1,
          interval.$2,
          merged.last.$3,
        );
      }
    }

    final windows = <FreeWindow>[];
    var cursor = fromMinuteOfDay > dayStartMinute
        ? fromMinuteOfDay
        : dayStartMinute;
    for (final interval in [...merged, (dayEndMinute, dayEndMinute, null)]) {
      final gapEnd = interval.$1 < dayEndMinute ? interval.$1 : dayEndMinute;
      if (gapEnd - cursor >= minWindowMinutes) {
        windows.add(
          FreeWindow(
            startMinute: cursor,
            endMinute: gapEnd,
            beforeTitle: interval.$1 < dayEndMinute ? interval.$3 : null,
          ),
        );
      }
      if (interval.$2 > cursor) cursor = interval.$2;
      if (cursor >= dayEndMinute) break;
    }
    return windows;
  }

  /// Human-readable strings like "14:00–16:30 (2h 30m)" — the exact shape
  /// the Coach prompt consumed before extraction. At most 4 are returned.
  static List<String> computeFormatted(
    List<Map<String, dynamic>> scheduleMaps, {
    int fromMinuteOfDay = 0,
  }) {
    return computeWindows(scheduleMaps, fromMinuteOfDay: fromMinuteOfDay)
        .map((w) => '${formatMinute(w.startMinute)}–'
            '${formatMinute(w.endMinute)} (${formatSpan(w.durationMinutes)})')
        .take(4)
        .toList();
  }

  static String formatMinute(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  static String formatSpan(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
