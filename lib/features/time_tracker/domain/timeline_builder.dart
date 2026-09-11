import 'models/activity_event.dart';

/// Turns a day's activity events into timeline rows — the ONE place that
/// decides how long anything lasted. Pure Dart.
///
/// Priority for an event's end (decision F1 + 2):
///   explicit end → next event (≤ 2 h) → 2-hour cap → untracked gap.
///
/// Beyond the cap the activity is credited NOTHING (crediting exactly two
/// hours would be its own false precision) and an [UntrackedRow] says how
/// long SidePal doesn't know about. SidePal distinguishes recorded
/// information from inferred information; it never manufactures certainty.

/// Beyond this, the next event no longer ends the previous one.
const Duration kActivityGapCap = Duration(hours: 2);

/// A sliver between an explicit end and the next log is noise, not an
/// untracked period, below this.
const Duration kUntrackedMinGap = Duration(minutes: 15);

enum EndSource {
  /// `endedAtMs` was set (timer stop or user edit).
  explicit,

  /// Ended when the next event started (within the cap).
  nextEvent,

  /// Next event was beyond the cap: no duration, untracked row follows.
  capped,

  /// Last event, no explicit end: "Ongoing".
  ongoing,
}

sealed class TimelineRow {
  const TimelineRow();
}

class ActivityRow extends TimelineRow {
  const ActivityRow({
    required this.event,
    required this.endMs,
    required this.endSource,
  });

  final ActivityEvent event;

  /// Resolved end; null for `capped` and `ongoing`.
  final int? endMs;
  final EndSource endSource;

  /// Known duration, null when the end is unknown. Never inferred.
  Duration? get actual {
    final end = endMs;
    if (end == null) return null;
    return Duration(milliseconds: end - event.startedAtMs);
  }

  Duration? get intended => event.intendedMinutes == null
      ? null
      : Duration(minutes: event.intendedMinutes!);

  bool get isOngoing => endSource == EndSource.ongoing;
}

class UntrackedRow extends TimelineRow {
  const UntrackedRow({required this.fromMs, required this.toMs});

  final int fromMs;
  final int toMs;

  Duration get length => Duration(milliseconds: toMs - fromMs);
}

/// [events] may be unsorted and may include tombstones; both are handled.
List<TimelineRow> buildTimeline(List<ActivityEvent> events) {
  final sorted = events.where((e) => e.active).toList()
    ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
  final rows = <TimelineRow>[];
  final capMs = kActivityGapCap.inMilliseconds;
  final minGapMs = kUntrackedMinGap.inMilliseconds;

  for (var i = 0; i < sorted.length; i++) {
    final e = sorted[i];
    final n = i + 1 < sorted.length ? sorted[i + 1] : null;

    final explicitEnd = e.endedAtMs;
    if (explicitEnd != null) {
      // An explicit end can't run past the next start (the user may have
      // logged the next thing before a timer was stopped).
      final end = n != null && n.startedAtMs < explicitEnd
          ? n.startedAtMs
          : explicitEnd;
      rows.add(ActivityRow(event: e, endMs: end, endSource: EndSource.explicit));
      if (n != null && n.startedAtMs - end >= minGapMs) {
        rows.add(UntrackedRow(fromMs: end, toMs: n.startedAtMs));
      }
      continue;
    }

    if (n == null) {
      rows.add(ActivityRow(event: e, endMs: null, endSource: EndSource.ongoing));
      continue;
    }

    final gap = n.startedAtMs - e.startedAtMs;
    if (gap <= capMs) {
      rows.add(
        ActivityRow(event: e, endMs: n.startedAtMs, endSource: EndSource.nextEvent),
      );
    } else {
      rows.add(ActivityRow(event: e, endMs: null, endSource: EndSource.capped));
      rows.add(UntrackedRow(fromMs: e.startedAtMs, toMs: n.startedAtMs));
    }
  }
  return rows;
}
