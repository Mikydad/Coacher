import '../../../core/utils/date_keys.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../context_override/domain/models/user_attention_state.dart';

/// Calendar-day keys where streak rules are frozen or excused (override / vacation).
///
/// Protected days bridge gaps when walking backward for [currentStreakDays]
/// and count as qualifying when computing [bestStreakDays].
Set<String> buildStreakProtectedDateKeys({
  required UserAttentionState? attention,
  required DateTime rangeStartInclusive,
  required DateTime rangeEndInclusive,
}) {
  if (attention == null) return {};

  final keys = <String>{};
  final activatedMs = attention.lastOverrideActivatedAt;
  if (activatedMs == null) return keys;

  final activated = DateTime.fromMillisecondsSinceEpoch(activatedMs);

  if (attention.hasActiveOverride) {
    if (overrideTypeProtectsStreak(attention.activeOverride)) {
      final end = attention.overrideExpiresAt ?? rangeEndInclusive;
      keys.addAll(
        _dateKeysInRange(
          start: activated,
          end: end,
          clipStart: rangeStartInclusive,
          clipEnd: rangeEndInclusive,
        ),
      );
    }
    return keys;
  }

  final resetMs = attention.lastAttentionResetAt;
  if (resetMs != null) {
    final ended = DateTime.fromMillisecondsSinceEpoch(resetMs);
    keys.addAll(
      _dateKeysInRange(
        start: activated,
        end: ended,
        clipStart: rangeStartInclusive,
        clipEnd: rangeEndInclusive,
      ),
    );
  }

  return keys;
}

Iterable<String> _dateKeysInRange({
  required DateTime start,
  required DateTime end,
  required DateTime clipStart,
  required DateTime clipEnd,
}) sync* {
  final from = _dateOnly(start.isAfter(clipStart) ? start : clipStart);
  final to = _dateOnly(end.isBefore(clipEnd) ? end : clipEnd);
  if (to.isBefore(from)) return;

  var cursor = from;
  while (!cursor.isAfter(to)) {
    yield DateKeys.yyyymmdd(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Overrides that freeze or excuse streak evaluation when active.
bool overrideTypeProtectsStreak(ContextOverride type) {
  return switch (type) {
    ContextOverride.vacation => true,
    ContextOverride.meeting => true,
    ContextOverride.focus => true,
    ContextOverride.sleep => false,
    ContextOverride.doNotDisturb => false,
    ContextOverride.none => false,
  };
}
