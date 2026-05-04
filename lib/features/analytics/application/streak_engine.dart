import '../../../core/utils/date_keys.dart';
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

StreakSummary computeStreakSummaryForEvents(
  Iterable<AnalyticsEvent> events, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateKeys.todayKey(current);
  final yesterday = DateKeys.yyyymmdd(
    DateTime(current.year, current.month, current.day).subtract(const Duration(days: 1)),
  );
  final unique = <String>{};
  for (final event in events) {
    if (event.type != AnalyticsEventType.habitCompleted) continue;
    if (!_isValidDateKey(event.dateKey)) continue;
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

  final sorted = unique.toList()..sort();
  var longest = 1;
  var running = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = DateKeys.parseLocalDateKey(sorted[i - 1]);
    final next = DateKeys.parseLocalDateKey(sorted[i]);
    final gap = next.difference(prev).inDays;
    if (gap == 1) {
      running++;
    } else if (gap > 1) {
      running = 1;
    }
    if (running > longest) longest = running;
  }

  final keySet = sorted.toSet();
  var anchorKey = today;
  if (!keySet.contains(today) && keySet.contains(yesterday)) {
    anchorKey = yesterday;
  } else if (!keySet.contains(today)) {
    anchorKey = '';
  }
  var currentStreak = 0;
  if (anchorKey.isNotEmpty) {
    var cursor = DateKeys.parseLocalDateKey(anchorKey);
    while (keySet.contains(DateKeys.yyyymmdd(cursor))) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  return StreakSummary(
    currentStreak: currentStreak,
    longestStreak: longest,
    lastCompletedDateKey: sorted.isEmpty ? null : sorted.last,
    completedDateKeys: sorted,
  );
}

bool _isValidDateKey(String key) {
  try {
    DateKeys.parseLocalDateKey(key);
    return true;
  } catch (_) {
    return false;
  }
}
