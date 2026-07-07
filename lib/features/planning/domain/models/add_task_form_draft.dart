import '../add_task_duration.dart';

/// Serializable snapshot of [AddTaskScreen] field state.
class AddTaskFormDraft {
  const AddTaskFormDraft({
    required this.savedAtMs,
    required this.title,
    required this.notes,
    required this.duration,
    required this.durationEnabled,
    required this.customDurationMinutes,
    this.category,
    required this.reminder,
    required this.focusSession,
    required this.isHabitAnchor,
    required this.reminderTimeMs,
    required this.modeRefId,
    required this.strictModeRequired,
    required this.modeUserCustomized,
    required this.isRigid,
    required this.advancedExpanded,
    required this.syncSleepWindowAndQuietMode,
    required this.inAppQuietMode,
    this.slotRoutineId,
    this.slotBlockId,
    this.slotDateKey,
  });

  final int savedAtMs;
  final String title;
  final String notes;
  final String duration;
  final bool durationEnabled;
  final int customDurationMinutes;
  final String? category;
  final bool reminder;
  final bool focusSession;
  final bool isHabitAnchor;
  final int reminderTimeMs;
  final String modeRefId;
  final bool strictModeRequired;
  final bool modeUserCustomized;
  final bool isRigid;
  final bool advancedExpanded;
  final bool syncSleepWindowAndQuietMode;
  final String inAppQuietMode;
  final String? slotRoutineId;
  final String? slotBlockId;
  final String? slotDateKey;

  bool get hasMeaningfulContent {
    if (title.trim().isNotEmpty || notes.trim().isNotEmpty) return true;
    if (durationEnabled || focusSession) return true;
    if (reminder || isHabitAnchor || strictModeRequired || isRigid) return true;
    if (category != null && category!.isNotEmpty) return true;
    if (modeUserCustomized || modeRefId != 'flexible') return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
    'savedAtMs': savedAtMs,
    'title': title,
    'notes': notes,
    'duration': duration,
    'durationEnabled': durationEnabled,
    'customDurationMinutes': customDurationMinutes,
    'category': category,
    'reminder': reminder,
    'focusSession': focusSession,
    'isHabitAnchor': isHabitAnchor,
    'reminderTimeMs': reminderTimeMs,
    'modeRefId': modeRefId,
    'strictModeRequired': strictModeRequired,
    'modeUserCustomized': modeUserCustomized,
    'isRigid': isRigid,
    'advancedExpanded': advancedExpanded,
    'syncSleepWindowAndQuietMode': syncSleepWindowAndQuietMode,
    'inAppQuietMode': inAppQuietMode,
    'slotRoutineId': slotRoutineId,
    'slotBlockId': slotBlockId,
    'slotDateKey': slotDateKey,
  };

  factory AddTaskFormDraft.fromJson(Map<String, dynamic> json) {
    return AddTaskFormDraft(
      savedAtMs: json['savedAtMs'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      duration: json['duration'] as String? ?? '25 MIN',
      durationEnabled: json['durationEnabled'] as bool? ?? false,
      customDurationMinutes:
          json['customDurationMinutes'] as int? ?? kAddTaskDefaultCustomMinutes,
      category: json['category'] as String?,
      reminder: json['reminder'] as bool? ?? false,
      focusSession: json['focusSession'] as bool? ?? false,
      isHabitAnchor: json['isHabitAnchor'] as bool? ?? false,
      reminderTimeMs:
          json['reminderTimeMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      modeRefId: json['modeRefId'] as String? ?? 'flexible',
      strictModeRequired: json['strictModeRequired'] as bool? ?? false,
      modeUserCustomized: json['modeUserCustomized'] as bool? ?? false,
      isRigid: json['isRigid'] as bool? ?? false,
      advancedExpanded: json['advancedExpanded'] as bool? ?? false,
      syncSleepWindowAndQuietMode:
          json['syncSleepWindowAndQuietMode'] as bool? ?? true,
      inAppQuietMode: json['inAppQuietMode'] as String? ?? 'sleep',
      slotRoutineId: json['slotRoutineId'] as String?,
      slotBlockId: json['slotBlockId'] as String?,
      slotDateKey: json['slotDateKey'] as String?,
    );
  }

  /// Compares user-editable fields (ignores [savedAtMs]).
  bool contentEquals(AddTaskFormDraft other) {
    return title == other.title &&
        notes == other.notes &&
        duration == other.duration &&
        durationEnabled == other.durationEnabled &&
        customDurationMinutes == other.customDurationMinutes &&
        category == other.category &&
        reminder == other.reminder &&
        focusSession == other.focusSession &&
        isHabitAnchor == other.isHabitAnchor &&
        reminderTimeMs == other.reminderTimeMs &&
        modeRefId == other.modeRefId &&
        strictModeRequired == other.strictModeRequired &&
        modeUserCustomized == other.modeUserCustomized &&
        isRigid == other.isRigid &&
        advancedExpanded == other.advancedExpanded &&
        syncSleepWindowAndQuietMode == other.syncSleepWindowAndQuietMode &&
        inAppQuietMode == other.inAppQuietMode &&
        slotRoutineId == other.slotRoutineId &&
        slotBlockId == other.slotBlockId &&
        slotDateKey == other.slotDateKey;
  }
}
