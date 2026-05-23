import '../../context_override/data/context_override_repository.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../reminders/data/reminder_repository.dart';
import '../domain/models/ai_action.dart';

// ─── Result ───────────────────────────────────────────────────────────────────

class ConflictDetectionResult {
  const ConflictDetectionResult({
    this.softConflicts = const [],
    this.hardBlocks = const [],
  });

  /// Advisory amber warnings — confirm still allowed.
  final List<String> softConflicts;

  /// Hard red blocks — action falls inside a protected window.
  final List<String> hardBlocks;

  bool get hasAny => softConflicts.isNotEmpty || hardBlocks.isNotEmpty;
}

// ─── Detector ─────────────────────────────────────────────────────────────────

/// Inspects a list of [AiAction]s for schedule conflicts:
///
///   1a — Reminder collision  (within 3 minutes of an existing reminder).
///   1b — Context conflict    (overlaps active/sleep override window).
///   1c — Enforcement mode    (strict-mode task moved outside allowed window).
class AiConflictDetector {
  const AiConflictDetector({
    required this.reminderRepository,
    required this.contextOverrideRepository,
  });

  final ReminderRepository reminderRepository;
  final ContextOverrideRepository contextOverrideRepository;

  static const int _reminderCollisionMinutes = 3;

  Future<ConflictDetectionResult> detect(List<AiAction> actions) async {
    final softConflicts = <String>[];
    final hardBlocks = <String>[];

    // Load current attention state once
    final attentionState = await _loadAttentionState();

    for (final action in actions) {
      // 1a — Reminder collision check
      if (action.actionType == ActionType.addReminder ||
          action.actionType == ActionType.rescheduleReminder) {
        final collision = await _checkReminderCollision(action);
        if (collision != null) softConflicts.add(collision);
      }

      // 1b — Context / sleep window conflict
      if (_isSchedulingAction(action)) {
        final timeStr = action.parameters['time'] as String?;
        final durationMinutes =
            (action.parameters['duration'] as num?)?.toInt() ?? 30;
        final taskTitle =
            action.parameters['title'] as String? ??
            action.parameters['taskTitle'] as String? ??
            'Task';

        if (timeStr != null) {
          final contextResult = _checkContextConflict(
            title: taskTitle,
            timeStr: timeStr,
            durationMinutes: durationMinutes,
            attentionState: attentionState,
          );
          if (contextResult != null) {
            if (contextResult.isHard) {
              hardBlocks.add(contextResult.message);
            } else {
              softConflicts.add(contextResult.message);
            }
          }
        }
      }

      // 1c — Enforcement mode conflict
      if (action.actionType == ActionType.moveTask) {
        final strictRequired =
            action.parameters['strictModeRequired'] as bool? ?? false;
        if (strictRequired) {
          final taskTitle =
              action.parameters['taskTitle'] as String? ?? 'Task';
          softConflicts.add(
            '"$taskTitle" uses a strict mode — moving it may require a typed CONFIRM override.',
          );
        }
      }
    }

    return ConflictDetectionResult(
      softConflicts: softConflicts,
      hardBlocks: hardBlocks,
    );
  }

  // ─── 1a: Reminder collision ────────────────────────────────────────────────

  Future<String?> _checkReminderCollision(AiAction action) async {
    try {
      final timeStr = action.parameters['reminderTime'] as String?;
      if (timeStr == null || !timeStr.contains(':')) return null;

      final parts = timeStr.split(':');
      final proposedHour = int.tryParse(parts[0]) ?? -1;
      final proposedMin = int.tryParse(parts[1]) ?? -1;
      if (proposedHour < 0) return null;

      final allReminders = await reminderRepository.listAllReminders();

      for (final existing in allReminders) {
        if (existing.scheduledAtIso == null) continue;
        final existingDt =
            DateTime.tryParse(existing.scheduledAtIso!)?.toLocal();
        if (existingDt == null) continue;

        final diffMinutes = (existingDt.hour * 60 + existingDt.minute) -
            (proposedHour * 60 + proposedMin);
        if (diffMinutes.abs() <= _reminderCollisionMinutes &&
            diffMinutes.abs() > 0) {
          final existingTime =
              '${existingDt.hour.toString().padLeft(2, '0')}:${existingDt.minute.toString().padLeft(2, '0')}';
          final existingTitle = existing.taskTitle ?? 'another task';
          return 'Reminder for "$existingTitle" fires at $existingTime, '
              'only ${diffMinutes.abs()} min away from this reminder.';
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── 1b: Context / sleep window conflict ──────────────────────────────────

  _ContextConflict? _checkContextConflict({
    required String title,
    required String timeStr,
    required int durationMinutes,
    required _AttentionSnapshot? attentionState,
  }) {
    if (attentionState == null) return null;

    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? -1;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    if (hour < 0) return null;

    final proposedMinutes = hour * 60 + minute;
    final proposedEndMinutes = proposedMinutes + durationMinutes;

    // Check active focus/DND override window
    if (attentionState.activeOverride != ContextOverride.none &&
        attentionState.overrideStartMinutes != null &&
        attentionState.overrideEndMinutes != null) {
      final overlapStart = attentionState.overrideStartMinutes!;
      final overlapEnd = attentionState.overrideEndMinutes!;
      if (_overlaps(proposedMinutes, proposedEndMinutes, overlapStart, overlapEnd)) {
        final overrideType = attentionState.activeOverride;
        final overrideName = overrideType.displayName;
        final startStr = _minsToTime(overlapStart);
        final endStr = _minsToTime(overlapEnd);

        final isHard = overrideType == ContextOverride.sleep ||
            overrideType == ContextOverride.doNotDisturb;

        return _ContextConflict(
          message: isHard
              ? '⛔ "$title" falls inside your $overrideName window ($startStr–$endStr).'
              : '"$title" overlaps with your active $overrideName ($startStr–$endStr).',
          isHard: isHard,
        );
      }
    }

    // Check sleep window (configured schedule, not necessarily active now)
    if (attentionState.sleepWindowStartMinutes != null &&
        attentionState.sleepWindowEndMinutes != null) {
      final sleepStart = attentionState.sleepWindowStartMinutes!;
      final sleepEnd = attentionState.sleepWindowEndMinutes!;

      // Sleep window may wrap midnight (e.g. 23:00–07:00)
      final inSleep = _inSleepWindow(
        proposedMinutes,
        sleepStart,
        sleepEnd,
      );
      if (inSleep) {
        final startStr = attentionState.sleepWindowStart!;
        final endStr = attentionState.sleepWindowEnd!;
        return _ContextConflict(
          message:
              '"$title" is scheduled during your sleep window ($startStr–$endStr).',
          isHard: false, // sleep window is advisory unless active sleep override
        );
      }
    }

    return null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<_AttentionSnapshot?> _loadAttentionState() async {
    try {
      final state = await contextOverrideRepository.getAttentionState();
      if (state == null) return null;

      int? overrideStart;
      int? overrideEnd;
      if (state.hasActiveOverride && state.lastOverrideActivatedAt != null) {
        final activatedAt = DateTime.fromMillisecondsSinceEpoch(
          state.lastOverrideActivatedAt!,
        ).toLocal();
        overrideStart = activatedAt.hour * 60 + activatedAt.minute;

        if (state.overrideExpiresAt != null) {
          final expiresAt = state.overrideExpiresAt!.toLocal();
          overrideEnd = expiresAt.hour * 60 + expiresAt.minute;
        } else {
          overrideEnd = overrideStart + 120; // default 2h assumption
        }
      }

      int? sleepStart;
      int? sleepEnd;
      if (state.hasSleepWindow) {
        sleepStart = _parseTimeStr(state.sleepWindowStart!);
        sleepEnd = _parseTimeStr(state.sleepWindowEnd!);
      }

      return _AttentionSnapshot(
        activeOverride: state.activeOverride,
        overrideStartMinutes: overrideStart,
        overrideEndMinutes: overrideEnd,
        sleepWindowStartMinutes: sleepStart,
        sleepWindowEndMinutes: sleepEnd,
        sleepWindowStart: state.sleepWindowStart,
        sleepWindowEnd: state.sleepWindowEnd,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isSchedulingAction(AiAction action) {
    return action.actionType == ActionType.createTask ||
        action.actionType == ActionType.editTask ||
        action.actionType == ActionType.moveTask;
  }

  bool _overlaps(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart < bEnd && aEnd > bStart;
  }

  bool _inSleepWindow(int minutes, int sleepStart, int sleepEnd) {
    if (sleepStart < sleepEnd) {
      // Normal window (e.g. 22:00–06:00 — but this case means start < end in minutes)
      return minutes >= sleepStart && minutes < sleepEnd;
    } else {
      // Wraps midnight (e.g. 23:00 = 1380, 07:00 = 420)
      return minutes >= sleepStart || minutes < sleepEnd;
    }
  }

  int? _parseTimeStr(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String _minsToTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

class _ContextConflict {
  const _ContextConflict({required this.message, required this.isHard});
  final String message;
  final bool isHard;
}

class _AttentionSnapshot {
  const _AttentionSnapshot({
    required this.activeOverride,
    this.overrideStartMinutes,
    this.overrideEndMinutes,
    this.sleepWindowStartMinutes,
    this.sleepWindowEndMinutes,
    this.sleepWindowStart,
    this.sleepWindowEnd,
  });

  final ContextOverride activeOverride;
  final int? overrideStartMinutes;
  final int? overrideEndMinutes;
  final int? sleepWindowStartMinutes;
  final int? sleepWindowEndMinutes;
  final String? sleepWindowStart;
  final String? sleepWindowEnd;
}
