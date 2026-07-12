class GoalAction {
  const GoalAction({
    required this.id,
    required this.goalId,
    required this.title,
    required this.orderIndex,
    this.completed = false,
    this.repeatWeekdays,
    this.completedDateKeys = const [],
    this.updatedAtMs = 0,
  });

  final String id;
  final String goalId;
  final String title;
  final int orderIndex;

  /// Last local edit time — drives last-write-wins sync merging. `0` for
  /// legacy records written before offline sync; the repository stamps it
  /// on every upsert.
  final int updatedAtMs;

  /// One-time completion flag. Only meaningful when [isRepeating] is false;
  /// repeating actions track completion per day in [completedDateKeys].
  final bool completed;

  /// Weekdays this action repeats on ([DateTime.monday]=1 … [DateTime.sunday]=7).
  /// Null or empty means a one-time checklist step (legacy behavior).
  final List<int>? repeatWeekdays;

  /// `yyyy-MM-dd` keys of days a repeating action was completed on.
  final List<String> completedDateKeys;

  bool get isRepeating => repeatWeekdays != null && repeatWeekdays!.isNotEmpty;

  /// Whether a repeating action is due on [day] (always true for one-time).
  bool isScheduledOn(DateTime day) {
    if (!isRepeating) return true;
    return repeatWeekdays!.contains(day.weekday);
  }

  /// Completion state for [dateKey]: per-day for repeating actions, the
  /// sticky [completed] flag otherwise.
  bool isCompletedOn(String dateKey) {
    if (isRepeating) return completedDateKeys.contains(dateKey);
    return completed;
  }

  /// Returns a copy with the completion state for [dateKey] set to [done].
  /// One-time actions just flip [completed].
  GoalAction withCompletionOn(String dateKey, {required bool done}) {
    if (!isRepeating) return copyWith(completed: done);
    final keys = List<String>.from(completedDateKeys);
    if (done && !keys.contains(dateKey)) {
      keys.add(dateKey);
    } else if (!done) {
      keys.remove(dateKey);
    }
    return copyWith(completedDateKeys: keys);
  }

  GoalAction copyWith({
    String? id,
    String? goalId,
    String? title,
    int? orderIndex,
    bool? completed,
    List<int>? repeatWeekdays,
    List<String>? completedDateKeys,
    int? updatedAtMs,
  }) {
    return GoalAction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      completed: completed ?? this.completed,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      completedDateKeys: completedDateKeys ?? this.completedDateKeys,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'orderIndex': orderIndex,
    'completed': completed,
    if (repeatWeekdays != null) 'repeatWeekdays': repeatWeekdays,
    if (completedDateKeys.isNotEmpty) 'completedDateKeys': completedDateKeys,
    'updatedAtMs': updatedAtMs,
  };

  static GoalAction fromMap(Map<String, dynamic> map) => GoalAction(
    id: map['id'] as String,
    goalId: map['goalId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    completed: map['completed'] as bool? ?? false,
    repeatWeekdays: (map['repeatWeekdays'] as List?)
        ?.whereType<num>()
        .map((d) => d.toInt())
        .toList(),
    completedDateKeys:
        (map['completedDateKeys'] as List?)?.whereType<String>().toList() ??
        const [],
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
  );
}
