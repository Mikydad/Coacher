import '../../../../core/utils/date_keys.dart';
import '../../../../core/utils/stable_id.dart';

/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.
///
/// One timestamped "this is what I'm doing" moment. Durations are NEVER
/// stored — they are derived by `buildTimeline` (explicit end → next event
/// → 2-hour cap → untracked gap). See PRD/Time_Tracker §2.

const int kActivityTextMaxChars = 80;
const int kActivityIntendedMaxMinutes = 720;

enum ActivitySource { manual, timer }

ActivitySource activitySourceFromStorage(String? raw) {
  for (final v in ActivitySource.values) {
    if (v.name == raw) return v;
  }
  return ActivitySource.manual;
}

/// Local calendar day of [ms] — the timeline bucket (decision 1).
String activityDateKeyFor(int ms) =>
    DateKeys.todayKey(DateTime.fromMillisecondsSinceEpoch(ms));

/// "gym", "Gym " and "GYM" are one activity for chips and the summary.
String normalizeActivityText(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Fully synced entity: Isar is the source of truth, replication via the
/// outbox, LWW on [updatedAtMs]. Deletion is a soft tombstone ([active] =
/// false) so a delete on one device wins over a stale edit from another.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.text,
    required this.startedAtMs,
    this.endedAtMs,
    this.intendedMinutes,
    required this.dateKey,
    this.source = ActivitySource.manual,
    this.sourceEntityId,
    this.category,
    this.active = true,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  /// New event with a client-generated id and the derived [dateKey].
  factory ActivityEvent.create({
    required String text,
    required int startedAtMs,
    required int nowMs,
    int? endedAtMs,
    int? intendedMinutes,
    ActivitySource source = ActivitySource.manual,
    String? sourceEntityId,
  }) {
    return ActivityEvent(
      id: StableId.generate('act'),
      text: text.trim(),
      startedAtMs: startedAtMs,
      endedAtMs: endedAtMs,
      intendedMinutes: intendedMinutes,
      dateKey: activityDateKeyFor(startedAtMs),
      source: source,
      sourceEntityId: sourceEntityId,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
    );
  }

  /// StableId (`act_...`), client-generated. Many per day, so NOT
  /// deterministic (unlike Direction).
  final String id;

  /// What the user was doing, 1..80 chars after trim.
  final String text;

  /// "The time the user says the activity started" — editable.
  final int startedAtMs;

  /// Explicit end (timer stop, or the user set one). Optional: most
  /// manual entries end when the next one starts.
  final int? endedAtMs;

  /// Intended duration — intent, never a stop time (decision 4).
  final int? intendedMinutes;

  /// Local calendar day of [startedAtMs], derived at write, indexed.
  final String dateKey;

  final ActivitySource source;

  /// Task or block id when [source] is `timer`.
  final String? sourceEntityId;

  /// Carried from day one, unexposed in V1 (decision 15).
  final String? category;

  /// Soft tombstone for LWW sync: false = deleted.
  final bool active;

  final int createdAtMs;

  /// LWW key — bumped on EVERY write.
  final int updatedAtMs;

  bool get hasExplicitEnd => endedAtMs != null;
  bool get isTimerSourced => source == ActivitySource.timer;
  String get normalizedText => normalizeActivityText(text);

  /// Throws [ArgumentError] — the only validation gate.
  void validate() {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text must not be empty');
    }
    if (trimmed.length > kActivityTextMaxChars) {
      throw ArgumentError('text must be at most $kActivityTextMaxChars chars');
    }
    if (startedAtMs <= 0) {
      throw ArgumentError('startedAtMs must be positive');
    }
    final end = endedAtMs;
    if (end != null && end <= startedAtMs) {
      throw ArgumentError('endedAtMs must be after startedAtMs');
    }
    final intended = intendedMinutes;
    if (intended != null &&
        (intended < 1 || intended > kActivityIntendedMaxMinutes)) {
      throw ArgumentError(
        'intendedMinutes must be 1..$kActivityIntendedMaxMinutes',
      );
    }
    if (dateKey != activityDateKeyFor(startedAtMs)) {
      throw ArgumentError('dateKey must match the local day of startedAtMs');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'startedAtMs': startedAtMs,
    if (endedAtMs != null) 'endedAtMs': endedAtMs,
    if (intendedMinutes != null) 'intendedMinutes': intendedMinutes,
    'dateKey': dateKey,
    'source': source.name,
    if (sourceEntityId != null) 'sourceEntityId': sourceEntityId,
    if (category != null) 'category': category,
    'active': active,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': 1,
  };

  factory ActivityEvent.fromMap(Map<String, dynamic> map) {
    final startedAtMs = (map['startedAtMs'] as num?)?.toInt() ?? 0;
    final storedKey = (map['dateKey'] as String?)?.trim();
    return ActivityEvent(
      id: (map['id'] as String?)?.trim() ?? '',
      text: (map['text'] as String?) ?? '',
      startedAtMs: startedAtMs,
      endedAtMs: (map['endedAtMs'] as num?)?.toInt(),
      intendedMinutes: (map['intendedMinutes'] as num?)?.toInt(),
      // Re-derive locally: another device's zone may bucket differently;
      // the timeline is always the LOCAL calendar day.
      dateKey: startedAtMs > 0
          ? activityDateKeyFor(startedAtMs)
          : (storedKey ?? ''),
      source: activitySourceFromStorage(map['source'] as String?),
      sourceEntityId: map['sourceEntityId'] as String?,
      category: map['category'] as String?,
      active: map['active'] as bool? ?? true,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  /// [startedAtMs] changes re-derive [dateKey]; pass `clearEnd` /
  /// `clearIntended` to null those fields.
  ActivityEvent copyWith({
    String? text,
    int? startedAtMs,
    int? endedAtMs,
    bool clearEnd = false,
    int? intendedMinutes,
    bool clearIntended = false,
    String? category,
    bool? active,
    int? updatedAtMs,
  }) {
    final start = startedAtMs ?? this.startedAtMs;
    return ActivityEvent(
      id: id,
      text: text ?? this.text,
      startedAtMs: start,
      endedAtMs: clearEnd ? null : (endedAtMs ?? this.endedAtMs),
      intendedMinutes: clearIntended
          ? null
          : (intendedMinutes ?? this.intendedMinutes),
      dateKey: activityDateKeyFor(start),
      source: source,
      sourceEntityId: sourceEntityId,
      category: category ?? this.category,
      active: active ?? this.active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
