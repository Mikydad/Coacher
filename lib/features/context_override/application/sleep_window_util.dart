import '../domain/models/context_override.dart';
import '../domain/models/user_attention_state.dart';

/// Returns true if [now] falls within the configured daily sleep window.
///
/// The window is defined by `"HH:mm"` 24-hour strings (e.g. `"23:00"` start,
/// `"07:00"` end). Handles midnight crossover correctly.
///
/// Returns false when either [windowStart] or [windowEnd] is null or empty.
bool isWithinSleepWindow(DateTime now, String? windowStart, String? windowEnd) {
  if (windowStart == null || windowStart.isEmpty) return false;
  if (windowEnd == null || windowEnd.isEmpty) return false;

  final start = _parseHHmm(windowStart);
  final end = _parseHHmm(windowEnd);
  if (start == null || end == null) return false;

  final nowMinutes = now.hour * 60 + now.minute;

  if (start <= end) {
    // Same-day window: e.g. 01:00–07:00.
    return nowMinutes >= start && nowMinutes < end;
  } else {
    // Midnight-crossover window: e.g. 23:00–07:00.
    return nowMinutes >= start || nowMinutes < end;
  }
}

/// Parses a `"HH:mm"` string into total minutes since midnight.
/// Returns null on parse failure.
int? _parseHHmm(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

// ─── Effective override ───────────────────────────────────────────────────────

/// The single source of truth for "what override is actually active right now?"
///
/// Evaluation order:
/// 1. If `state.activeOverride` is non-none AND not expired → return it.
/// 2. Else if current time is within the configured sleep window → return `sleep`.
/// 3. Otherwise → return `none`.
ContextOverride effectiveOverride(UserAttentionState state, DateTime now) {
  if (state.hasActiveOverride && !state.isExpired(now)) {
    return state.activeOverride;
  }
  if (state.hasSleepWindow &&
      isWithinSleepWindow(now, state.sleepWindowStart, state.sleepWindowEnd)) {
    return ContextOverride.sleep;
  }
  return ContextOverride.none;
}

// ─── Vacation window check ────────────────────────────────────────────────────

/// Returns true if [dateKey] (`"yyyyMMdd"`) falls within the vacation window.
///
/// Used by the streak engine to skip penalty application for dates that
/// occurred while the user was on vacation.
///
/// [state.lastOverrideActivatedAt] marks the vacation start.
/// [state.lastAttentionResetAt] marks the vacation end (null = still active).
bool vacationWindowContains(UserAttentionState state, String dateKey) {
  final startMs = state.lastOverrideActivatedAt;
  if (startMs == null) return false;

  // Parse dateKey into a DateTime at the start of that day.
  if (dateKey.length < 8) return false;
  final year = int.tryParse(dateKey.substring(0, 4));
  final month = int.tryParse(dateKey.substring(4, 6));
  final day = int.tryParse(dateKey.substring(6, 8));
  if (year == null || month == null || day == null) return false;
  final dateMs = DateTime(year, month, day).millisecondsSinceEpoch;

  // End of the date key day.
  final dateEndMs = DateTime(
    year,
    month,
    day,
    23,
    59,
    59,
  ).millisecondsSinceEpoch;

  final endMs =
      state.lastAttentionResetAt ?? DateTime.now().millisecondsSinceEpoch;

  // The date is inside the vacation window if its day overlaps [startMs, endMs].
  return dateMs <= endMs && dateEndMs >= startMs;
}
