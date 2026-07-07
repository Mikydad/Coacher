import '../domain/models/scheduled_time_block.dart';

/// A suggested free window on a plan day.
class TimeSlotSuggestion {
  const TimeSlotSuggestion({
    required this.startAt,
    required this.durationMinutes,
    required this.label,
    this.suggestionIndex = 0,
  });

  final DateTime startAt;
  final int durationMinutes;

  /// `Suggested` or `Alternative`.
  final String label;

  /// `0`, `1`, or use [SchedulingSlotSuggestionIndex.custom] for custom picker.
  final int suggestionIndex;

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));
}

/// Analytics / logging index for which chip was applied.
abstract final class SchedulingSlotSuggestionIndex {
  static const int suggested = 0;
  static const int alternative = 1;
  static const String custom = 'custom';
}

/// How to search for alternative slots.
enum SlotSearchDirection {
  /// Start at [afterTime] and scan forward (move existing item).
  forwardFrom,

  /// Prefer a gap ending at or before [anchorTime] (move proposed item).
  preferBeforeAnchor,
}

const _slotStep = Duration(minutes: 15);

/// Finds up to two non-overlapping start times on [planDay].
List<TimeSlotSuggestion> suggestAlternativeSlots({
  required DateTime planDay,
  required int durationMinutes,
  required List<ScheduledTimeBlock> blocksOnDay,
  required DateTime afterTime,
  Set<String> ignoreEntityIds = const {},
  SlotSearchDirection direction = SlotSearchDirection.forwardFrom,
  DateTime? anchorTime,
}) {
  if (durationMinutes < 1) return const [];

  final dayStart = DateTime(planDay.year, planDay.month, planDay.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final occupied =
      blocksOnDay
          .where((b) => !ignoreEntityIds.contains(b.entityId))
          .map((b) => (start: b.startAt, end: b.computedEndAt))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  if (direction == SlotSearchDirection.preferBeforeAnchor &&
      anchorTime != null) {
    return _suggestPreferBeforeAnchor(
      dayStart: dayStart,
      dayEnd: dayEnd,
      anchor: anchorTime,
      durationMinutes: durationMinutes,
      occupied: occupied,
      forwardSeed: afterTime.isBefore(dayStart) ? dayStart : afterTime,
    );
  }

  return _suggestForward(
    dayStart: dayStart,
    dayEnd: dayEnd,
    durationMinutes: durationMinutes,
    occupied: occupied,
    afterTime: afterTime,
  );
}

List<TimeSlotSuggestion> _suggestForward({
  required DateTime dayStart,
  required DateTime dayEnd,
  required int durationMinutes,
  required List<({DateTime start, DateTime end})> occupied,
  required DateTime afterTime,
}) {
  var seed = afterTime.isBefore(dayStart) ? dayStart : afterTime;

  final first = _nextFreeStart(
    candidate: seed,
    durationMinutes: durationMinutes,
    dayEnd: dayEnd,
    occupied: occupied,
  );
  if (first == null) return const [];

  final results = <TimeSlotSuggestion>[
    _toSuggestion(
      start: first,
      durationMinutes: durationMinutes,
      label: 'Suggested',
      index: SchedulingSlotSuggestionIndex.suggested,
    ),
  ];

  final secondSeed = first.add(Duration(minutes: durationMinutes));
  final second = _nextFreeStart(
    candidate: secondSeed,
    durationMinutes: durationMinutes,
    dayEnd: dayEnd,
    occupied: occupied,
  );
  if (second != null && second != first) {
    results.add(
      _toSuggestion(
        start: second,
        durationMinutes: durationMinutes,
        label: 'Alternative',
        index: SchedulingSlotSuggestionIndex.alternative,
      ),
    );
  }

  return results;
}

List<TimeSlotSuggestion> _suggestPreferBeforeAnchor({
  required DateTime dayStart,
  required DateTime dayEnd,
  required DateTime anchor,
  required int durationMinutes,
  required List<({DateTime start, DateTime end})> occupied,
  required DateTime forwardSeed,
}) {
  final results = <TimeSlotSuggestion>[];
  final duration = Duration(minutes: durationMinutes);

  var endTarget = roundDateTimeToFiveMinutes(anchor);
  if (endTarget.isAfter(dayEnd)) endTarget = dayEnd;

  while (!endTarget.subtract(duration).isBefore(dayStart)) {
    var start = endTarget.subtract(duration);
    if (start.isBefore(dayStart)) break;
    start = roundDateTimeToFiveMinutes(start);
    if (!_overlaps(start, duration, occupied) &&
        !start.add(duration).isAfter(anchor)) {
      results.add(
        _toSuggestion(
          start: start,
          durationMinutes: durationMinutes,
          label: 'Suggested',
          index: SchedulingSlotSuggestionIndex.suggested,
        ),
      );
      break;
    }
    endTarget = endTarget.subtract(_slotStep);
  }

  final forward = _suggestForward(
    dayStart: dayStart,
    dayEnd: dayEnd,
    durationMinutes: durationMinutes,
    occupied: occupied,
    afterTime: forwardSeed,
  );

  for (final slot in forward) {
    if (results.length >= 2) break;
    final duplicate = results.any((r) => r.startAt == slot.startAt);
    if (!duplicate) {
      results.add(
        TimeSlotSuggestion(
          startAt: slot.startAt,
          durationMinutes: slot.durationMinutes,
          label: results.isEmpty ? 'Suggested' : 'Alternative',
          suggestionIndex: results.isEmpty
              ? SchedulingSlotSuggestionIndex.suggested
              : SchedulingSlotSuggestionIndex.alternative,
        ),
      );
    }
  }

  return results;
}

TimeSlotSuggestion _toSuggestion({
  required DateTime start,
  required int durationMinutes,
  required String label,
  required int index,
}) {
  return TimeSlotSuggestion(
    startAt: roundDateTimeToFiveMinutes(start),
    durationMinutes: durationMinutes,
    label: label,
    suggestionIndex: index,
  );
}

DateTime? _nextFreeStart({
  required DateTime candidate,
  required int durationMinutes,
  required DateTime dayEnd,
  required List<({DateTime start, DateTime end})> occupied,
}) {
  var t = roundDateTimeToFiveMinutes(candidate);
  final duration = Duration(minutes: durationMinutes);

  while (!t.add(duration).isAfter(dayEnd)) {
    if (!_overlaps(t, duration, occupied)) return t;
    t = t.add(_slotStep);
  }
  return null;
}

bool _overlaps(
  DateTime start,
  Duration duration,
  List<({DateTime start, DateTime end})> occupied,
) {
  final end = start.add(duration);
  for (final slot in occupied) {
    if (start.isBefore(slot.end) && end.isAfter(slot.start)) return true;
  }
  return false;
}

/// Rounds [dt] to the nearest 5-minute boundary (seconds/ms cleared).
DateTime roundDateTimeToFiveMinutes(DateTime dt) {
  final totalMinutes = dt.hour * 60 + dt.minute;
  final rounded = ((totalMinutes + 2.5) ~/ 5) * 5;
  final hour = (rounded ~/ 60) % 24;
  final minute = rounded % 60;
  return DateTime(dt.year, dt.month, dt.day, hour, minute);
}

/// Formats a local time range for conflict UI (5-minute rounded display).
String formatSchedulingTimeRange(DateTime start, DateTime end) {
  final rs = roundDateTimeToFiveMinutes(start);
  final re = roundDateTimeToFiveMinutes(end);
  String two(int v) => v.toString().padLeft(2, '0');
  final s = '${two(rs.hour)}:${two(rs.minute)}';
  final e = '${two(re.hour)}:${two(re.minute)}';
  return '$s – $e';
}
