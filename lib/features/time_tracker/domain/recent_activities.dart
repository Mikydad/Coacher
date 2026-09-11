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
