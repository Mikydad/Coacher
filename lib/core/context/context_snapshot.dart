import 'package:flutter/foundation.dart';

import '../scheduling/free_window_calculator.dart';
import 'calendar_signal.dart';

/// The formalized Context Engine value object (humanizing Phase 4b,
/// PRD §9): one immutable snapshot of "what is true right now", assembled
/// by `ContextSnapshotService` and consumed by the planner,
/// seize-the-moment, and `AiPayloadAssembler`.
///
/// Contract: **every signal field is nullable** — null means "this signal
/// doesn't exist right now" (permission denied, platform without the
/// channel, fetch failed) and consumers degrade with scripted copy, never
/// a claim. [capturedAtMs] is the freshness timestamp; snapshots are
/// never persisted and raw signals never leave the device — only the
/// [coarseLabels] enter AI payloads.
@immutable
class ContextSnapshot {
  const ContextSnapshot({
    required this.capturedAtMs,
    this.online,
    this.overrideMode,
    this.freeMinutesNow,
    this.currentWindowEndsBefore,
    this.calendarBusyToday,
    this.nextCalendarEventStartMs,
  });

  /// When this snapshot was assembled (epoch ms). Consumers should treat
  /// snapshots older than a few minutes as stale and re-capture.
  final int capturedAtMs;

  /// Connectivity at capture time. Null when the check failed.
  final bool? online;

  /// Active context-override mode name ('focus', 'sleep', …); null when
  /// no override is in effect.
  final String? overrideMode;

  /// Minutes remaining in the free window the user is in RIGHT NOW,
  /// after subtracting both planned blocks and calendar busy intervals.
  /// Null when the user is not currently in a free window.
  final int? freeMinutesNow;

  /// What ends the current free window ("Dinner", "your 14:00"); null
  /// when the window runs to the end of the waking day.
  final String? currentWindowEndsBefore;

  /// Today's calendar busy intervals — **null when the calendar signal is
  /// unavailable** (Tier-1 nullable degradation, PRD §9), empty when the
  /// calendar is genuinely clear.
  final List<CalendarBusyInterval>? calendarBusyToday;

  /// Start of the next calendar event from capture time; null when none
  /// remain today or the signal is unavailable.
  final int? nextCalendarEventStartMs;

  bool get hasCalendarSignal => calendarBusyToday != null;

  /// Coarse, non-identifying labels — the ONLY calendar/context shape
  /// allowed into AI payloads ("free_25m", never event contents).
  List<String> coarseLabels() {
    final labels = <String>[];
    final free = freeMinutesNow;
    if (free != null) labels.add('free_${free}m');
    final nextMs = nextCalendarEventStartMs;
    if (nextMs != null) {
      final next = DateTime.fromMillisecondsSinceEpoch(nextMs);
      final minute = next.hour * 60 + next.minute;
      labels.add(
        'next_calendar_event_${FreeWindowCalculator.formatMinute(minute)}',
      );
    }
    final mode = overrideMode;
    if (mode != null) labels.add('mode_$mode');
    if (online == false) labels.add('offline');
    return labels;
  }
}
