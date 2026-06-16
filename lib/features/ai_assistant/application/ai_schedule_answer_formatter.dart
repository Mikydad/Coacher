import '../domain/models/ai_operating_layer_payload.dart';

/// Builds plain-language schedule summaries from payload data (offline fallback).
abstract final class AiScheduleAnswerFormatter {
  static String? tryAnswerScheduleQuery(AiOperatingLayerPayload payload) {
    final lower = payload.userInput.toLowerCase();

    if (_looksLikeGoalQuery(lower) && payload.goalProgress.isNotEmpty) {
      return _formatGoalProgress(payload);
    }

    if (!_looksLikeScheduleQuery(lower)) return null;

    if (lower.contains('week') && payload.weekOverview.isNotEmpty) {
      return _formatWeek(payload.weekOverview);
    }

    if (lower.contains('tomorrow')) {
      return _formatDay(
        label: 'tomorrow',
        tasks: payload.tomorrowTasks,
        schedule: payload.tomorrowSchedule,
      );
    }

    if (lower.contains('today') || _looksLikeScheduleQuery(lower)) {
      return _formatDay(
        label: 'today',
        tasks: payload.activeTasks,
        schedule: payload.todaySchedule,
      );
    }

    return null;
  }

  static bool _looksLikeGoalQuery(String lower) {
    return lower.contains('goal') &&
        (lower.contains('how am i') ||
            lower.contains('progress') ||
            lower.contains('doing on'));
  }

  static String _formatGoalProgress(AiOperatingLayerPayload payload) {
    final coachingStyle =
        payload.behaviorPreferences['coachingStyle']?.toString() ?? 'balanced';
    final buffer = StringBuffer('Here\'s your goal progress this period:\n');
    for (final g in payload.goalProgress) {
      buffer.writeln(
        '• ${g['title']}: ${g['daysMet']}/${g['target']} '
        '(${g['daysElapsed']}/${g['totalDays']} days)',
      );
    }
    if (coachingStyle == 'supportive') {
      buffer.writeln('\nKeep showing up — small wins add up.');
    } else if (coachingStyle == 'direct') {
      buffer.writeln('\nFocus on closing the gap on days you missed.');
    }
    return buffer.toString().trim();
  }

  static String _formatWeek(List<Map<String, dynamic>> weekOverview) {
    final buffer = StringBuffer('Here\'s your week at a glance:\n');
    for (final day in weekOverview) {
      final count = day['taskCount'] ?? 0;
      final scheduled = day['scheduledCount'] ?? 0;
      buffer.writeln(
        '• ${day['label']} (${day['date']}): $count tasks, $scheduled scheduled',
      );
    }
    return buffer.toString().trim();
  }

  static bool _looksLikeScheduleQuery(String lower) {
    const queryWords = [
      'what',
      'show',
      'tell me',
      'list',
      'how many',
      'what\'s',
      'whats',
    ];
    const scheduleWords = [
      'plan',
      'schedule',
      'tomorrow',
      'today',
      'week',
      'on my',
    ];
    return queryWords.any(lower.contains) &&
        scheduleWords.any(lower.contains);
  }

  static String _formatDay({
    required String label,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> schedule,
  }) {
    final buffer = StringBuffer('Here\'s your plan for $label:\n');
    if (schedule.isNotEmpty) {
      for (final block in schedule) {
        buffer.writeln(
          '• ${block['title']} ${block['startTime']}–${block['endTime']}',
        );
      }
    } else if (tasks.isNotEmpty) {
      for (final task in tasks) {
        buffer.writeln(
          '• ${task['title']} at ${task['time']} (${task['duration']})',
        );
      }
    } else {
      buffer.writeln('Nothing scheduled yet.');
    }
    return buffer.toString().trim();
  }
}
