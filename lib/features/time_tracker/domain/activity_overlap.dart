import 'models/activity_event.dart';

/// Overlap between a new (or edited) entry and what is already logged
/// (Miko, 2026-09-24). The tracker is one activity at a time by design —
/// the timeline cuts an entry at the next start — but the capture sheet
/// used to save an overlapping entry silently, so "track A at 9:00, then
/// log B at 9:00" ended A with no word said. Now it asks first.
///
/// A running entry (no explicit end) is treated as ending [nowMs].
List<ActivityEvent> overlappingActivities(
  Iterable<ActivityEvent> events, {
  required int startMs,
  int? endMs,
  required int nowMs,
  String? excludeId,
}) {
  final newEnd = endMs ?? nowMs;
  final out = <ActivityEvent>[];
  for (final e in events) {
    if (!e.active || e.id == excludeId) continue;
    final eEnd = e.endedAtMs ?? nowMs;
    if (e.startedAtMs < newEnd && eEnd > startMs) out.add(e);
  }
  out.sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
  return out;
}

/// What the confirm dialog says about the first clash.
({String title, String body}) overlapNotice({
  required ActivityEvent existing,
  required String newText,
  required int startMs,
  required String Function(int ms) formatTime,
}) {
  final existingEnd = existing.endedAtMs;
  final existingRange = existingEnd == null
      ? 'from ${formatTime(existing.startedAtMs)}'
      : '${formatTime(existing.startedAtMs)} – ${formatTime(existingEnd)}';
  final cutAt = startMs > existing.startedAtMs
      ? formatTime(startMs)
      : formatTime(existing.startedAtMs);
  final label = newText.trim().isEmpty ? 'This entry' : "'${newText.trim()}'";
  return (
    title: "Already logging '${existing.text}'",
    body:
        "'${existing.text}' is logged $existingRange. One thing at a time: "
        '$label will end it at $cutAt.',
  );
}
