import '../../../../core/utils/date_keys.dart';
import '../../../../core/validation/model_validators.dart';
import 'reminder_occurrence_enums.dart';

/// One scheduled *instance* of a reminder — the unit the state machine moves
/// through `upcoming → due → [active] → overdue → resolved` (PRD §3.1).
///
/// ## Why this is separate from `ReminderConfig`
///
/// `ReminderConfig` is the user's **configuration**: when they want reminding,
/// in which mode, whether it's on. It is long-lived and edited by the user.
/// An occurrence is a **single moment**: today's 2 PM study block, yesterday's
/// missed one. It is created by the scheduler and resolved once.
///
/// Conflating the two is what makes today's behaviour confusing — a fired
/// task reminder leaves its config `enabled` with a past timestamp forever,
/// so every later sync computes "next fire = null" and arms nothing
/// (AUDIT §10 C3). Separating them means a recurring task's config stays
/// stable while each day gets its own row that can be missed, resolved, or
/// rolled forward independently, and history survives for the streak and
/// resolution-rate metrics.
///
/// Occurrences exist for tasks, habits and goals alike — [entityKind]
/// distinguishes them, and all of them run the same transition functions
/// (FR-R-14).
class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id,
    required this.entityId,
    required this.entityKind,
    required this.dateKey,
    required this.scheduledAtMs,
    required this.windowMinutes,
    this.entityTitle,
    this.modeRefId,
    this.state = ReminderOccurrenceState.upcoming,
    this.taxonomy = ReminderTaxonomy.flexible,
    this.criticality = 1,
    this.classificationSource = ClassificationSource.heuristic,
    this.classifierVersion,
    this.ladderPosition = 0,
    this.overdueSinceMs,
    this.resolutionKind,
    this.resolutionReason,
    this.resolvedAtMs,
    this.dismissedForDayKey,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  /// Client-generated [StableId].
  final String id;

  /// The task / habit / goal this occurrence belongs to.
  final String entityId;

  /// One of `ReminderEntityKinds` — `task`, `habit`, `goal`.
  final String entityKind;

  /// Local calendar day (`yyyy-MM-dd`) of [scheduledAtMs]. Together with
  /// [entityKind] and [entityId] this is the occurrence's natural identity.
  final String dateKey;

  /// The occurrence's due moment.
  final int scheduledAtMs;

  /// Length of the reminder window in minutes (D2: Flexible 30 / Disciplined
  /// 45 / Extreme 60). `windowEnd = scheduledAt + windowMinutes`; from R3 the
  /// interruption boundary can shorten it further, never lengthen it.
  final int windowMinutes;

  /// Denormalised so a pre-written notification string and the Recovery Card
  /// need no join at delivery time.
  final String? entityTitle;

  /// Resolved enforcement mode at scheduling time (`flexible` / `disciplined`
  /// / `extreme`).
  final String? modeRefId;

  final ReminderOccurrenceState state;
  final ReminderTaxonomy taxonomy;

  /// 0 = nice-to-do … 3 = critical (medication). Only 3 may pierce the
  /// interruption boundary, the Focus Shield and the sleep window (D5).
  final int criticality;

  final ClassificationSource classificationSource;

  /// Which classifier build produced [taxonomy]; lets a later version
  /// re-classify only what it should.
  final int? classifierVersion;

  /// How far up the mode's ladder this occurrence has climbed.
  final int ladderPosition;

  /// When the window closed unresolved. Set exactly once, to `windowEnd` —
  /// not to the moment the app happened to notice (FR-R-12).
  final int? overdueSinceMs;

  final ReminderResolutionKind? resolutionKind;

  /// Required by Extreme mode for a reschedule (FR-R-42).
  final String? resolutionReason;

  final int? resolvedAtMs;

  /// The local day (`yyyy-MM-dd`) on which the user waved this row off the
  /// Recovery Card (FR-R-40, Flexible mode).
  ///
  /// Dismissing is NOT resolving: the task is still undone, so the occurrence
  /// stays unresolved and keeps its overdue history. It simply stops being
  /// mentioned for the rest of that day, and day rollover carries it into
  /// Plan-Tomorrow as a suggestion. Storing the day rather than a boolean is
  /// what makes it expire on its own at midnight, with nothing to reset.
  final String? dismissedForDayKey;

  final int createdAtMs;
  final int updatedAtMs;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// `'$entityKind|$entityId|$dateKey'` — the natural composite key, mirroring
  /// `IsarGoalCheckIn.keyFor`, so upserts stay a single `putBy` call.
  static String keyFor(String entityKind, String entityId, String dateKey) =>
      '$entityKind|$entityId|$dateKey';

  String get occurrenceKey => keyFor(entityKind, entityId, dateKey);

  static String dateKeyFor(int scheduledAtMs) =>
      DateKeys.yyyymmdd(DateTime.fromMillisecondsSinceEpoch(scheduledAtMs));

  DateTime get scheduledAt =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAtMs);

  /// The moment the window closes and the taxonomy rule fires.
  DateTime get windowEnd =>
      scheduledAt.add(Duration(minutes: windowMinutes));

  int get windowEndMs => windowEnd.millisecondsSinceEpoch;

  bool get isResolved => state.isTerminal;

  /// Unresolved and past its window — the raw pool the Recovery Card draws
  /// from before dismissal and taxonomy filtering.
  bool get isOverdue => state == ReminderOccurrenceState.overdue;

  /// Whether the user has waved this off for [dayKey].
  bool isDismissedOn(String dayKey) => dismissedForDayKey == dayKey;

  void validate() {
    ModelValidators.requireNotBlank(id, 'reminderOccurrence.id');
    ModelValidators.requireNotBlank(entityId, 'reminderOccurrence.entityId');
    ModelValidators.requireNotBlank(
      entityKind,
      'reminderOccurrence.entityKind',
    );
    ModelValidators.requireNotBlank(dateKey, 'reminderOccurrence.dateKey');
  }

  ReminderOccurrence copyWith({
    Object? entityTitle = _sentinel,
    Object? modeRefId = _sentinel,
    int? scheduledAtMs,
    String? dateKey,
    int? windowMinutes,
    ReminderOccurrenceState? state,
    ReminderTaxonomy? taxonomy,
    int? criticality,
    ClassificationSource? classificationSource,
    Object? classifierVersion = _sentinel,
    int? ladderPosition,
    Object? overdueSinceMs = _sentinel,
    Object? resolutionKind = _sentinel,
    Object? resolutionReason = _sentinel,
    Object? resolvedAtMs = _sentinel,
    Object? dismissedForDayKey = _sentinel,
    int? updatedAtMs,
  }) {
    return ReminderOccurrence(
      id: id,
      entityId: entityId,
      entityKind: entityKind,
      dateKey: dateKey ?? this.dateKey,
      scheduledAtMs: scheduledAtMs ?? this.scheduledAtMs,
      windowMinutes: windowMinutes ?? this.windowMinutes,
      entityTitle: entityTitle == _sentinel
          ? this.entityTitle
          : entityTitle as String?,
      modeRefId: modeRefId == _sentinel
          ? this.modeRefId
          : modeRefId as String?,
      state: state ?? this.state,
      taxonomy: taxonomy ?? this.taxonomy,
      criticality: criticality ?? this.criticality,
      classificationSource: classificationSource ?? this.classificationSource,
      classifierVersion: classifierVersion == _sentinel
          ? this.classifierVersion
          : classifierVersion as int?,
      ladderPosition: ladderPosition ?? this.ladderPosition,
      overdueSinceMs: overdueSinceMs == _sentinel
          ? this.overdueSinceMs
          : overdueSinceMs as int?,
      resolutionKind: resolutionKind == _sentinel
          ? this.resolutionKind
          : resolutionKind as ReminderResolutionKind?,
      resolutionReason: resolutionReason == _sentinel
          ? this.resolutionReason
          : resolutionReason as String?,
      resolvedAtMs: resolvedAtMs == _sentinel
          ? this.resolvedAtMs
          : resolvedAtMs as int?,
      dismissedForDayKey: dismissedForDayKey == _sentinel
          ? this.dismissedForDayKey
          : dismissedForDayKey as String?,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityId': entityId,
    'entityKind': entityKind,
    'dateKey': dateKey,
    'scheduledAtMs': scheduledAtMs,
    'windowMinutes': windowMinutes,
    if (entityTitle != null) 'entityTitle': entityTitle,
    if (modeRefId != null) 'modeRefId': modeRefId,
    'state': state.toStorage(),
    'taxonomy': taxonomy.toStorage(),
    'criticality': criticality,
    'classificationSource': classificationSource.toStorage(),
    if (classifierVersion != null) 'classifierVersion': classifierVersion,
    'ladderPosition': ladderPosition,
    if (overdueSinceMs != null) 'overdueSinceMs': overdueSinceMs,
    if (resolutionKind != null) 'resolutionKind': resolutionKind!.toStorage(),
    if (resolutionReason != null) 'resolutionReason': resolutionReason,
    if (resolvedAtMs != null) 'resolvedAtMs': resolvedAtMs,
    if (dismissedForDayKey != null) 'dismissedForDayKey': dismissedForDayKey,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static ReminderOccurrence fromMap(Map<String, dynamic> map) {
    final scheduledAtMs = (map['scheduledAtMs'] as num?)?.toInt() ?? 0;
    return ReminderOccurrence(
      id: map['id'] as String,
      entityId: map['entityId'] as String? ?? '',
      entityKind: map['entityKind'] as String? ?? 'task',
      dateKey: map['dateKey'] as String? ?? dateKeyFor(scheduledAtMs),
      scheduledAtMs: scheduledAtMs,
      windowMinutes: (map['windowMinutes'] as num?)?.toInt() ?? 30,
      entityTitle: map['entityTitle'] as String?,
      modeRefId: map['modeRefId'] as String?,
      state: ReminderOccurrenceState.fromStorage(map['state'] as String?),
      taxonomy: ReminderTaxonomy.fromStorage(map['taxonomy'] as String?),
      criticality: (map['criticality'] as num?)?.toInt() ?? 1,
      classificationSource: ClassificationSource.fromStorage(
        map['classificationSource'] as String?,
      ),
      classifierVersion: (map['classifierVersion'] as num?)?.toInt(),
      ladderPosition: (map['ladderPosition'] as num?)?.toInt() ?? 0,
      overdueSinceMs: (map['overdueSinceMs'] as num?)?.toInt(),
      resolutionKind: ReminderResolutionKind.fromStorage(
        map['resolutionKind'] as String?,
      ),
      resolutionReason: map['resolutionReason'] as String?,
      resolvedAtMs: (map['resolvedAtMs'] as num?)?.toInt(),
      dismissedForDayKey: map['dismissedForDayKey'] as String?,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

const Object _sentinel = Object();
