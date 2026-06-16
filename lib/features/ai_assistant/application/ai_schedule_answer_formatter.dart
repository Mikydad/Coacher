import '../domain/models/ai_operating_layer_payload.dart';

/// Builds plain-language schedule summaries from payload data (offline fallback).
abstract final class AiScheduleAnswerFormatter {
  static String? tryAnswerScheduleQuery(AiOperatingLayerPayload payload) {
    final lower = payload.userInput.toLowerCase();
    if (!_looksLikeScheduleQuery(lower)) return null;

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
