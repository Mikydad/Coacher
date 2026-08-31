import '../../../../core/validation/model_validators.dart';
import 'reminder_occurrence_enums.dart';

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.enabled,
    required this.scheduledAtIso,
    this.modeRefId,
    this.blockUrgencyScore = 50,
    this.pendingAction = false,
    this.escalationLevel = 0,
    this.emergencyBypass = false,
    this.lastTriggeredAtMs,
    this.nextPromptAtIso,
    this.activeNotificationId,
    this.evaluationTrace = const [],
    this.taxonomy = ReminderTaxonomy.flexible,
    this.criticality = 1,
    this.classificationSource = ClassificationSource.heuristic,
    this.classifierVersion,
    this.aiBody,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final String? taskTitle;
  final bool enabled;
  final String? scheduledAtIso;
  final String? modeRefId;
  final int blockUrgencyScore;
  final bool pendingAction;
  final int escalationLevel;
  final bool emergencyBypass;
  final int? lastTriggeredAtMs;
  final String? nextPromptAtIso;

  /// The OS notification ID currently scheduled for this entity.
  /// Null when no notification is active. Used by [AttentionOrchestratorService]
  /// for single-cancel across app restarts (in-memory map is primary; this is
  /// the persistence fallback added in Phase C).
  final int? activeNotificationId;

  /// Ordered human-readable trace entries from escalation decisions.
  /// Appended by [AttentionOrchestratorService] for explainability/debug.
  final List<String> evaluationTrace;

  /// The task's stable classification (FR-R-20/21).
  ///
  /// It lives on the CONFIG, not only on an occurrence, because it must
  /// survive the day: an occurrence is one moment, and tomorrow's would
  /// otherwise forget that the user said "this is routine". Each occurrence
  /// takes a snapshot of these at arming time, which is what the state
  /// machine and the ladder read.
  final ReminderTaxonomy taxonomy;

  /// 0 = nice-to-do … 3 = critical. The heuristic never sets 3 — only the
  /// user does, via the editor's Critical toggle (settled 2026-08-30).
  final int criticality;

  final ClassificationSource classificationSource;
  final int? classifierVersion;

  /// AI-pre-generated warm first-reminder line (FR-R-63), written at
  /// classification time and used VERBATIM by the compiled slot 0. The
  /// template bank is the permanent fallback and keeps every escalation
  /// step — warmth is allowed to vary, the escalation contract is not.
  final String? aiBody;

  final int createdAtMs;
  final int updatedAtMs;

  /// Apply a freshly computed classification, honouring precedence.
  ///
  /// A `user` classification is authoritative and is never overwritten by a
  /// heuristic or by AI (FR-R-21); [force] exists for the editor itself,
  /// which IS the user speaking.
  ///
  /// FR-R-23: this only ever touches taxonomy/criticality/source. It cannot
  /// disable a reminder the user configured — classification selects the
  /// ladder's shape, never whether one exists.
  ReminderConfig withClassification({
    required ReminderTaxonomy taxonomy,
    required int criticality,
    required ClassificationSource source,
    int? classifierVersion,
    required int updatedAtMs,
    bool force = false,
  }) {
    if (!force && classificationSource.isAuthoritative) return this;
    return copyWith(
      taxonomy: taxonomy,
      criticality: criticality.clamp(0, 3),
      classificationSource: source,
      classifierVersion: classifierVersion,
      updatedAtMs: updatedAtMs,
    );
  }

  void validate() {
    ModelValidators.requireNotBlank(id, 'reminder.id');
    ModelValidators.requireNotBlank(taskId, 'reminder.taskId');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    if (taskTitle != null) 'taskTitle': taskTitle,
    'enabled': enabled,
    'scheduledAtIso': scheduledAtIso,
    if (modeRefId != null) 'modeRefId': modeRefId,
    'blockUrgencyScore': blockUrgencyScore,
    'pendingAction': pendingAction,
    'escalationLevel': escalationLevel,
    'emergencyBypass': emergencyBypass,
    if (lastTriggeredAtMs != null) 'lastTriggeredAtMs': lastTriggeredAtMs,
    if (nextPromptAtIso != null) 'nextPromptAtIso': nextPromptAtIso,
    if (activeNotificationId != null)
      'activeNotificationId': activeNotificationId,
    if (evaluationTrace.isNotEmpty) 'evaluationTrace': evaluationTrace,
    'taxonomy': taxonomy.toStorage(),
    'criticality': criticality,
    'classificationSource': classificationSource.toStorage(),
    if (classifierVersion != null) 'classifierVersion': classifierVersion,
    if (aiBody != null) 'aiBody': aiBody,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static ReminderConfig fromMap(Map<String, dynamic> map) {
    final rawTrace = map['evaluationTrace'];
    final trace = rawTrace is List
        ? rawTrace.whereType<String>().toList(growable: false)
        : const <String>[];
    return ReminderConfig(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      taskTitle: map['taskTitle'] as String?,
      enabled: map['enabled'] as bool? ?? false,
      scheduledAtIso: map['scheduledAtIso'] as String?,
      modeRefId: map['modeRefId'] as String?,
      blockUrgencyScore: (map['blockUrgencyScore'] as num?)?.toInt() ?? 50,
      pendingAction: map['pendingAction'] as bool? ?? false,
      escalationLevel: (map['escalationLevel'] as num?)?.toInt() ?? 0,
      emergencyBypass: map['emergencyBypass'] as bool? ?? false,
      lastTriggeredAtMs: (map['lastTriggeredAtMs'] as num?)?.toInt(),
      nextPromptAtIso: map['nextPromptAtIso'] as String?,
      activeNotificationId: (map['activeNotificationId'] as num?)?.toInt(),
      evaluationTrace: trace,
      taxonomy: ReminderTaxonomy.fromStorage(map['taxonomy'] as String?),
      criticality: (map['criticality'] as num?)?.toInt() ?? 1,
      // A row with no taxonomy field at all predates classification, so it is
      // marked `migration` rather than pretending a heuristic ever looked at
      // it (PRD §9). FR-R-22's AI pass can then target migration/heuristic
      // rows and leave `user` ones alone.
      classificationSource: map.containsKey('taxonomy')
          ? ClassificationSource.fromStorage(
              map['classificationSource'] as String?,
            )
          : ClassificationSource.migration,
      classifierVersion: (map['classifierVersion'] as num?)?.toInt(),
      aiBody: map['aiBody'] as String?,
      createdAtMs: map['createdAtMs'] as int,
      updatedAtMs: map['updatedAtMs'] as int,
    );
  }

  /// Nullable fields use the `_sentinel` convention (as in
  /// `circle_notif_prefs.dart` / `ai_pulse.dart`) so passing an explicit
  /// `null` CLEARS the field instead of silently keeping the old value.
  ///
  /// The `?? this.x` form it replaces made `nextPromptAtIso: null` a no-op —
  /// `_resolveReminder` had been asking to clear the pending prompt and
  /// keeping a stale timestamp instead (AUDIT §10 L4). Harmless only while
  /// nothing read the field independently; every nullable added by Reminder
  /// V2 would have inherited the same trap.
  ReminderConfig copyWith({
    bool? enabled,
    Object? scheduledAtIso = _sentinel,
    Object? taskTitle = _sentinel,
    Object? modeRefId = _sentinel,
    int? blockUrgencyScore,
    bool? pendingAction,
    int? escalationLevel,
    bool? emergencyBypass,
    Object? lastTriggeredAtMs = _sentinel,
    Object? nextPromptAtIso = _sentinel,
    Object? activeNotificationId = _sentinel,
    List<String>? evaluationTrace,
    ReminderTaxonomy? taxonomy,
    int? criticality,
    ClassificationSource? classificationSource,
    Object? classifierVersion = _sentinel,
    Object? aiBody = _sentinel,
    int? updatedAtMs,
  }) {
    return ReminderConfig(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle == _sentinel
          ? this.taskTitle
          : taskTitle as String?,
      enabled: enabled ?? this.enabled,
      scheduledAtIso: scheduledAtIso == _sentinel
          ? this.scheduledAtIso
          : scheduledAtIso as String?,
      modeRefId: modeRefId == _sentinel
          ? this.modeRefId
          : modeRefId as String?,
      blockUrgencyScore: blockUrgencyScore ?? this.blockUrgencyScore,
      pendingAction: pendingAction ?? this.pendingAction,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      emergencyBypass: emergencyBypass ?? this.emergencyBypass,
      lastTriggeredAtMs: lastTriggeredAtMs == _sentinel
          ? this.lastTriggeredAtMs
          : lastTriggeredAtMs as int?,
      nextPromptAtIso: nextPromptAtIso == _sentinel
          ? this.nextPromptAtIso
          : nextPromptAtIso as String?,
      activeNotificationId: activeNotificationId == _sentinel
          ? this.activeNotificationId
          : activeNotificationId as int?,
      evaluationTrace: evaluationTrace ?? this.evaluationTrace,
      taxonomy: taxonomy ?? this.taxonomy,
      criticality: criticality ?? this.criticality,
      classificationSource: classificationSource ?? this.classificationSource,
      classifierVersion: classifierVersion == _sentinel
          ? this.classifierVersion
          : classifierVersion as int?,
      aiBody: aiBody == _sentinel ? this.aiBody : aiBody as String?,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

const Object _sentinel = Object();
