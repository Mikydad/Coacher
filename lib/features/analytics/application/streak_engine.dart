import '../../../core/utils/date_keys.dart';
import '../../coaching/application/enforcement_mode_policy.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import '../../context_override/domain/models/user_attention_state.dart';
import '../domain/models/analytics_event.dart';

class StreakSummary {
  const StreakSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDateKey,
    required this.completedDateKeys,
  });

  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedDateKey;
  final List<String> completedDateKeys;
}

/// Computes a [StreakSummary] from raw analytics events.
///
/// **EnforcementMode rules (FR-D-19):**
///
/// | Mode         | Grace period | On-time-only |
/// |--------------|-------------|--------------|
/// | flexible     | 1 missed day | no           |
/// | disciplined  | 0           | no           |
/// | extreme      | 0           | yes (before 22:00 local) |
///
/// [enforcementMode] defaults to [EnforcementMode.disciplined] — existing
/// callers without an explicit mode see no behavioral change.
StreakSummary computeStreakSummaryForEvents(
  Iterable<AnalyticsEvent> events, {
  DateTime? now,
  EnforcementMode enforcementMode = EnforcementMode.disciplined,
}) {
  final current = now ?? DateTime.now();
  final today = DateKeys.todayKey(current);
  final yesterday = DateKeys.yyyymmdd(
    DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(days: 1)),
  );

  final onlyOnTime = EnforcementModePolicy.onlyOnTimeCompletionsCountForStreak(
    enforcementMode,
  );

  final unique = <String>{};
  for (final event in events) {
    if (event.type != AnalyticsEventType.habitCompleted) continue;
    if (!_isValidDateKey(event.dateKey)) continue;
    // extreme mode: only count completions logged before 22:00 local time.
    if (onlyOnTime && !_isOnTime(event.timestampLocalIso)) continue;
    unique.add(event.dateKey);
  }
  if (unique.isEmpty) {
    return const StreakSummary(
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDateKey: null,
      completedDateKeys: <String>[],
    );
  }

  final gracePeriod = EnforcementModePolicy.missedDayGracePeriod(
    enforcementMode,
  );
  final sorted = unique.toList()..sort();

  // Compute longest streak respecting grace period.
  var longest = 1;
  var running = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = DateKeys.parseLocalDateKey(sorted[i - 1]);
    final next = DateKeys.parseLocalDateKey(sorted[i]);
    final gap = next.difference(prev).inDays;
    // gap == 1 → consecutive; gap <= 1 + gracePeriod → within grace window.
    if (gap <= 1 + gracePeriod) {
      running++;
    } else {
      running = 1;
    }
    if (running > longest) longest = running;
  }

  // Compute current streak anchored to today/yesterday, respecting grace.
  final keySet = sorted.toSet();
  var anchorKey = today;
  if (!keySet.contains(today) && keySet.contains(yesterday)) {
    anchorKey = yesterday;
  } else if (!keySet.contains(today)) {
    // flexible: allow one missed day — anchor to day-before-yesterday if present.
    if (gracePeriod >= 1) {
      final dayBeforeYesterday = DateKeys.yyyymmdd(
        DateTime(
          current.year,
          current.month,
          current.day,
        ).subtract(const Duration(days: 2)),
      );
      anchorKey = keySet.contains(dayBeforeYesterday) ? dayBeforeYesterday : '';
    } else {
      anchorKey = '';
    }
  }

  var currentStreak = 0;
  if (anchorKey.isNotEmpty) {
    var cursor = DateKeys.parseLocalDateKey(anchorKey);
    while (true) {
      final key = DateKeys.yyyymmdd(cursor);
      if (keySet.contains(key)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (gracePeriod >= 1) {
        // Peek one day further: if that day has a completion, bridge the gap.
        final prev = cursor.subtract(const Duration(days: 1));
        if (keySet.contains(DateKeys.yyyymmdd(prev))) {
          cursor = prev;
        } else {
          break;
        }
      } else {
        break;
      }
    }
  }

  return StreakSummary(
    currentStreak: currentStreak,
    longestStreak: longest,
    lastCompletedDateKey: sorted.isEmpty ? null : sorted.last,
    completedDateKeys: sorted,
  );
}

/// Returns true if the event's local ISO timestamp indicates a completion
/// before 22:00 — used for [EnforcementMode.extreme] on-time-only logic.
bool _isOnTime(String timestampLocalIso) {
  try {
    final dt = DateTime.parse(timestampLocalIso);
    return dt.hour < 22;
  } catch (_) {
    return true; // treat unparseable timestamps as on-time (safe default)
  }
}

bool _isValidDateKey(String key) {
  try {
    DateKeys.parseLocalDateKey(key);
    return true;
  } catch (_) {
    return false;
  }
}

// ─── Vacation-protected streak calculation ────────────────────────────────────

/// Computes a streak summary while protecting dates that fall inside a vacation
/// window from breaking the streak.
///
/// Vacation days are injected into the completed date set so gaps during
/// vacation do not appear as breaks.
///
/// When [vacationState] is null or has no vacation window, behaves identically
/// to [computeStreakSummaryForEvents].
StreakSummary computeStreakSummaryWithVacationProtection(
  Iterable<AnalyticsEvent> events, {
  UserAttentionState? vacationState,
  DateTime? now,
  EnforcementMode enforcementMode = EnforcementMode.disciplined,
}) {
  if (vacationState == null || !_hasVacationWindow(vacationState)) {
    return computeStreakSummaryForEvents(
      events,
      now: now,
      enforcementMode: enforcementMode,
    );
  }

  // Build protected date keys: every date within the vacation window.
  final protectedKeys = _vacationDateKeys(vacationState, now ?? DateTime.now());

  // Merge real completed events with protected vacation dates.
  // We create synthetic habitCompleted events for each protected date so
  // the existing engine logic handles them uniformly.
  const syntheticTs = '1970-01-01T00:00:00.000';
  final syntheticEvents = protectedKeys.map(
    (key) => AnalyticsEvent(
      id: 'vacation_protected_$key',
      entityId: '',
      entityKind: 'habit',
      type: AnalyticsEventType.habitCompleted,
      dateKey: key,
      timestampLocalIso: syntheticTs,
      sourceSurface: 'vacation_protection',
      idempotencyKey: 'vacation_protected_$key',
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  );

  return computeStreakSummaryForEvents(
    [...events, ...syntheticEvents],
    now: now,
    enforcementMode: enforcementMode,
  );
}

bool _hasVacationWindow(UserAttentionState state) {
  return state.lastOverrideActivatedAt != null &&
      (state.isVacationActive || state.lastAttentionResetAt != null);
}

/// Generate all `"yyyyMMdd"` date keys between vacation start and end (or now).
List<String> _vacationDateKeys(UserAttentionState state, DateTime now) {
  final startMs = state.lastOverrideActivatedAt;
  if (startMs == null) return const [];
  final endMs = state.isVacationActive
      ? now.millisecondsSinceEpoch
      : (state.lastAttentionResetAt ?? now.millisecondsSinceEpoch);

  var cursor = DateTime.fromMillisecondsSinceEpoch(startMs);
  final end = DateTime.fromMillisecondsSinceEpoch(endMs);
  final keys = <String>[];
  while (!cursor.isAfter(end)) {
    if (_isValidDateKey(DateKeys.yyyymmdd(cursor))) {
      keys.add(DateKeys.yyyymmdd(cursor));
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return keys;
}
