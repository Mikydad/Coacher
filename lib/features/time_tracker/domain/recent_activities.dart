import 'models/activity_event.dart';

/// The user's OWN recent distinct activities, most recent first, for the
/// capture sheet's chips (decision 7). Never global suggestions.
///
/// Distinct by normalised text ("gym" / "Gym " / "GYM" are one chip);
/// the displayed spelling is the most recent one. Timer-sourced events
/// count too — a task the user focuses on is exactly what they'll log by
/// hand next time.
const int kRecentActivityChipCount = 6;
const Duration kRecentActivityWindow = Duration(days: 30);

List<String> recentActivityChips(
  List<ActivityEvent> events, {
  int max = kRecentActivityChipCount,
}) {
  final sorted = events.where((e) => e.active).toList()
    ..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
  final seen = <String>{};
  final chips = <String>[];
  for (final e in sorted) {
    final key = e.normalizedText;
    if (key.isEmpty || !seen.add(key)) continue;
    chips.add(e.text.trim());
    if (chips.length >= max) break;
  }
  return chips;
}


/// One row of the capture sheet's recent list: the most recent spelling
/// and how many times it was logged in the window.
class RecentActivitySuggestion {
  const RecentActivitySuggestion({
    required this.text,
    required this.count,
    required this.lastStartedAtMs,
  });

  final String text;
  final int count;
  final int lastStartedAtMs;

  String get normalized => normalizeActivityText(text);
}

/// Ranked list for the sheet (Miko, 2026-09-12): activities logged more
/// than once in the window come first (by count, then recency), then
/// one-offs by recency — so "Eating breakfast" sits at the top every
/// morning and "going to the clinic with my mom" only shows while it is
/// recent, then falls away on its own. [query] filters by substring
/// (normalised) so a rare repeat is a few keystrokes away.
List<RecentActivitySuggestion> recentActivitySuggestions(
  List<ActivityEvent> events, {
  String query = '',
  int max = kRecentSuggestionRows,
}) {
  final counts = <String, int>{};
  final latest = <String, ActivityEvent>{};
  for (final e in events) {
    if (!e.active) continue;
    final k = e.normalizedText;
    if (k.isEmpty) continue;
    counts[k] = (counts[k] ?? 0) + 1;
    final seen = latest[k];
    if (seen == null || e.startedAtMs > seen.startedAtMs) latest[k] = e;
  }
  final q = normalizeActivityText(query);
  final rows = <RecentActivitySuggestion>[
    for (final k in counts.keys)
      if (q.isEmpty || k.contains(q))
        RecentActivitySuggestion(
          text: latest[k]!.text.trim(),
          count: counts[k]!,
          lastStartedAtMs: latest[k]!.startedAtMs,
        ),
  ];
  // Exact match to what is typed is not a suggestion.
  rows.removeWhere((r) => q.isNotEmpty && r.normalized == q);
  rows.sort((a, b) {
    final aRepeat = a.count > 1;
    final bRepeat = b.count > 1;
    if (aRepeat != bRepeat) return aRepeat ? -1 : 1;
    if (aRepeat) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
    }
    return b.lastStartedAtMs.compareTo(a.lastStartedAtMs);
  });
  return rows.take(max).toList(growable: false);
}

/// Rows visible in the sheet at once — fixed height, never grows.
const int kRecentSuggestionRows = 5;
