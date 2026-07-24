import 'package:flutter/foundation.dart';

import '../scheduling/free_window_calculator.dart';
import 'activity_signal.dart';
import 'calendar_signal.dart';
import 'context_snapshot.dart';

/// Converts calendar busy intervals into the `{title, startTime, endTime}`
/// pseudo-block shape [FreeWindowCalculator] consumes, clamped to [day].
///
/// The title is the coarse time label ("your 14:00") — that is what nudge
/// copy may reference ("20 free minutes before your 14:00"); event
/// contents never exist on this side of the bridge. The `calendar: true`
/// marker lets the calculator distinguish pre-meeting gaps.
List<Map<String, dynamic>> calendarBusyToScheduleMaps(
  List<CalendarBusyInterval> intervals,
  DateTime day,
) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final maps = <Map<String, dynamic>>[];
  for (final interval in intervals) {
    final start = DateTime.fromMillisecondsSinceEpoch(interval.startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(interval.endMs);
    if (!end.isAfter(dayStart) || !start.isBefore(dayEnd)) continue;
    final clampedStart = start.isBefore(dayStart) ? dayStart : start;
    final clampedEnd = end.isAfter(dayEnd) ? dayEnd : end;
    final startMinute = clampedStart.hour * 60 + clampedStart.minute;
    final label = 'your ${FreeWindowCalculator.formatMinute(startMinute)}';
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    maps.add(<String, dynamic>{
      'title': label,
      'startTime': fmt(clampedStart),
      'endTime': clampedEnd == dayEnd ? '23:59' : fmt(clampedEnd),
      'calendar': true,
    });
  }
  return maps;
}

/// Assembles [ContextSnapshot]s on demand (humanizing Phase 4b, PRD §9).
///
/// All inputs arrive as injected functions so the service is pure wiring:
/// no Riverpod, no plugins — fully unit-testable. Snapshots are never
/// persisted; a capture is a read, not an event.
class ContextSnapshotService {
  ContextSnapshotService({
    required this.scheduleMapsForDay,
    required this.overrideMode,
    required this.isOnline,
    required this.calendarSignal,
    this.activitySignal,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Planned-schedule pseudo-blocks for a day (the Coach prompt's source).
  final Future<List<Map<String, dynamic>>> Function(DateTime day)
  scheduleMapsForDay;

  /// Active override mode name, null when none.
  final Future<String?> Function() overrideMode;

  /// Connectivity probe; null result means "couldn't tell".
  final Future<bool?> Function() isOnline;

  final CalendarSignalService calendarSignal;

  /// Tier-2 motion signal (Phase 6a); null keeps the snapshot activity-
  /// free — pre-Phase-6 callers and tests need no change.
  final ActivitySignalService? activitySignal;

  final DateTime Function() _now;

  /// Calendar busy intervals for one calendar day — the planner feed.
  /// Null when the signal is unavailable (nullable degradation).
  Future<List<CalendarBusyInterval>?> calendarBusyForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    return calendarSignal.busyIntervals(
      dayStart,
      dayStart.add(const Duration(days: 1)),
    );
  }

  /// One fresh snapshot of right now.
  Future<ContextSnapshot> capture() async {
    final now = _now();

    List<Map<String, dynamic>> scheduleMaps;
    try {
      scheduleMaps = await scheduleMapsForDay(now);
    } catch (e) {
      debugPrint('[ContextSnapshot] schedule fetch failed: $e');
      scheduleMaps = const [];
    }

    List<CalendarBusyInterval>? calendarBusy;
    try {
      calendarBusy = await calendarBusyForDay(now);
    } catch (_) {
      calendarBusy = null;
    }

    final allBusy = [
      ...scheduleMaps,
      if (calendarBusy != null) ...calendarBusyToScheduleMaps(calendarBusy, now),
    ];
    final nowMinute = now.hour * 60 + now.minute;
    final windows = FreeWindowCalculator.computeWindows(allBusy);
    int? freeMinutesNow;
    String? endsBefore;
    for (final w in windows) {
      if (w.startMinute <= nowMinute && nowMinute < w.endMinute) {
        freeMinutesNow = w.endMinute - nowMinute;
        endsBefore = w.beforeTitle;
        break;
      }
    }

    int? nextEventStartMs;
    if (calendarBusy != null) {
      for (final interval in calendarBusy) {
        if (interval.startMs > now.millisecondsSinceEpoch &&
            (nextEventStartMs == null || interval.startMs < nextEventStartMs)) {
          nextEventStartMs = interval.startMs;
        }
      }
    }

    String? mode;
    try {
      mode = await overrideMode();
    } catch (_) {
      mode = null;
    }

    bool? online;
    try {
      online = await isOnline();
    } catch (_) {
      online = null;
    }

    ActivityKind? activity;
    try {
      activity = (await activitySignal?.currentActivity(now: now))?.kind;
    } catch (_) {
      activity = null;
    }

    return ContextSnapshot(
      capturedAtMs: now.millisecondsSinceEpoch,
      online: online,
      overrideMode: mode,
      freeMinutesNow: freeMinutesNow,
      currentWindowEndsBefore: endsBefore,
      calendarBusyToday: calendarBusy,
      nextCalendarEventStartMs: nextEventStartMs,
      activity: activity,
    );
  }
}
