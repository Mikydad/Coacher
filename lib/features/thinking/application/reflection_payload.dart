import '../../direction/domain/direction_context_lines.dart';
import '../../direction/domain/models/direction_entry.dart';
import '../../intentions/domain/models/intention.dart';
import '../../memory/domain/models/memory_fact.dart';
import '../../memory/domain/models/person.dart';

/// Pure snapshot assembly for the Thinking Loop's reflection pass
/// (humanizing Phase 7, PRD §12).
///
/// The snapshot is everything the deterministic layers already know —
/// facts, people, open/dormant intentions with their avoidance history —
/// rendered as compact JSON for ONE budgeted `reflect` call. Every item
/// carries its id so the model can ground proposals in `basedOn`
/// references, which the parser then verifies against these same ids
/// (grounding-or-drop — the reflection sibling of quote verification).

/// Caps keep the payload bounded: reflection reads the shape of the
/// user's life, not every record of a long history.
const kReflectionMaxFacts = 30;
const kReflectionMaxPeople = 15;
const kReflectionMaxIntentions = 30;

/// How long an expired intention still counts as avoidance evidence.
const kReflectionExpiredLookbackDays = 14;

/// Builds the snapshot map sent as the reflection user message.
Map<String, dynamic> buildReflectionSnapshot({
  required List<MemoryFact> facts,
  required List<Person> people,
  required List<Intention> intentions,
  required DateTime now,

  /// Direction (2026-09-11): every stored row; only CURRENT-period,
  /// non-empty entries reach the snapshot (history ≠ current direction).
  List<DirectionEntry> directions = const [],
}) {
  final nowMs = now.millisecondsSinceEpoch;
  final directionSlots = resolveDirectionSlots(directions, now);
  final currentDirection = [
    for (final h in kDirectionHorizonOrder)
      if (directionSlots[h]!.hasText)
        {
          'id': directionSlots[h]!.current!.id,
          'horizon': h.name,
          'period': directionSlots[h]!.period.label,
          'text': directionSlots[h]!.text,
        },
  ];

  final sortedFacts = [...facts]
    ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
  final sortedPeople = [...people]
    ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));

  final relevant = intentions
      .where((i) => _isReflectionRelevant(i, nowMs))
      .toList()
    ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));

  return {
    'today': _dayKey(now),
    'facts': [
      for (final f in sortedFacts.take(kReflectionMaxFacts))
        {
          'id': f.id,
          'kind': f.kind.name,
          'content': f.content,
          'provenance': f.provenance.name,
        },
    ],
    'people': [
      for (final p in sortedPeople.take(kReflectionMaxPeople))
        {
          'id': p.id,
          'name': p.displayName,
          if (p.relationship != null) 'relationship': p.relationship,
          if (p.lastInteractionAtMs != null)
            'lastInteractionDaysAgo': _daysAgo(p.lastInteractionAtMs!, nowMs),
        },
    ],
    'intentions': [
      for (final i in relevant.take(kReflectionMaxIntentions))
        {
          'id': i.id,
          'title': i.title,
          'status': i.status.name,
          'windowEndsInDays': _daysUntil(i.windowEndMs, nowMs),
          if (i.nudgeCount > 0) 'nudgeCount': i.nudgeCount,
          if (i.snoozeCount > 0) 'snoozeCount': i.snoozeCount,
          if (i.activityTags.isNotEmpty) 'tags': i.activityTags,
        },
    ],
    if (currentDirection.isNotEmpty) 'direction': currentDirection,
  };
}

/// Open and dormant intentions matter; recently expired ones are
/// avoidance evidence ("you've pushed this three times").
bool _isReflectionRelevant(Intention i, int nowMs) {
  if (!i.active) return false;
  switch (i.status) {
    case IntentionStatus.open:
    case IntentionStatus.dormant:
    case IntentionStatus.nudged:
      return true;
    case IntentionStatus.expired:
      return nowMs - i.windowEndMs <
          Duration(days: kReflectionExpiredLookbackDays).inMilliseconds;
    case IntentionStatus.done:
    case IntentionStatus.dismissed:
      return false;
  }
}

/// The id set proposals may reference (`basedOn` grounding universe).
Set<String> reflectionKnownIds({
  required List<MemoryFact> facts,
  required List<Person> people,
  required List<Intention> intentions,
  List<DirectionEntry> directions = const [],
}) => {
  for (final f in facts) f.id,
  for (final p in people) p.id,
  for (final i in intentions) i.id,
  for (final d in directions) d.id,
};

/// Stable hash over the DURABLE identity of the inputs — ids, statuses and
/// update stamps, deliberately not the rendered payload (day-relative
/// numbers like `windowEndsInDays` change every midnight and must not
/// force a re-reflection when nothing actually happened).
String reflectionInputsHash({
  required List<MemoryFact> facts,
  required List<Person> people,
  required List<Intention> intentions,
  List<DirectionEntry> directions = const [],

  /// Extra durable parts (Time Tracker V1.2: activity ids + rule stamps).
  List<String> extraParts = const [],
}) {
  final parts = <String>[
    ...extraParts,
    for (final f in facts) 'f:${f.id}:${f.updatedAtMs}',
    // Editing a direction must re-arm the loop; id + stamp only (no
    // day-relative values, so midnight alone never re-arms it).
    for (final d in directions) 'd:${d.id}:${d.updatedAtMs}',
    // updatedAtMs matters too (P2-10): renaming a person or editing their
    // relationship must re-arm reflection, not only a new interaction.
    for (final p in people)
      'p:${p.id}:${p.updatedAtMs}:${p.lastInteractionAtMs ?? 0}',
    for (final i in intentions)
      'i:${i.id}:${i.status.name}:${i.updatedAtMs}:'
          '${i.nudgeCount}:${i.snoozeCount}',
  ]..sort();
  // FNV-1a, 64-bit — cheap, stable across runs, no crypto needed.
  var hash = 0xcbf29ce484222325;
  for (final part in parts) {
    for (final unit in part.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
  }
  return hash.toRadixString(16);
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int _daysAgo(int thenMs, int nowMs) =>
    ((nowMs - thenMs) / Duration.millisecondsPerDay).floor();

int _daysUntil(int thenMs, int nowMs) =>
    ((thenMs - nowMs) / Duration.millisecondsPerDay).ceil();
