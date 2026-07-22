import 'package:sidepal/features/ai_assistant/application/ai_conflict_detector.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/context_override/domain/models/context_override.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({this.reminders = const []});
  final List<ReminderConfig> reminders;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => reminders;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async =>
      reminders.where((r) => taskIds.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

class _FakeContextOverrideRepository implements ContextOverrideRepository {
  _FakeContextOverrideRepository({this.state});
  final UserAttentionState? state;

  @override
  Future<UserAttentionState?> getAttentionState() async => state;

  @override
  Stream<UserAttentionState?> watchAttentionState() => Stream.value(state);

  @override
  Future<void> upsertAttentionState(UserAttentionState s) async {}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

ReminderConfig _makeReminder({
  required String id,
  required String scheduledAtIso,
  String taskTitle = 'Some Task',
}) {
  return ReminderConfig(
    id: id,
    taskId: 'task_$id',
    taskTitle: taskTitle,
    enabled: true,
    scheduledAtIso: scheduledAtIso,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

AiAction _addReminderAction({required String reminderTime}) {
  return AiAction(
    actionType: ActionType.addReminder,
    parameters: {
      'taskTitle': 'Morning Run',
      'reminderTime': reminderTime,
      'date': '2026-05-22',
    },
    confidence: 0.9,
  );
}

AiAction _createTaskAction({
  required String time,
  int duration = 30,
  String title = 'Workout',
}) {
  return AiAction(
    actionType: ActionType.createTask,
    parameters: {
      'title': title,
      'time': time,
      'duration': duration,
      'date': '2026-05-22',
    },
    confidence: 0.9,
  );
}

UserAttentionState _stateWithSleepWindow({
  required String start,
  required String end,
}) {
  return UserAttentionState(
    id: 'user_attention_state',
    activeOverride: ContextOverride.none,
    manuallyMuted: false,
    updatedAtMs: 0,
    sleepWindowStart: start,
    sleepWindowEnd: end,
  );
}

UserAttentionState _stateWithActiveOverride({
  required ContextOverride override,
  required DateTime activatedAt,
  DateTime? expiresAt,
}) {
  return UserAttentionState(
    id: 'user_attention_state',
    activeOverride: override,
    manuallyMuted: false,
    updatedAtMs: 0,
    lastOverrideActivatedAt: activatedAt.millisecondsSinceEpoch,
    overrideExpiresAt: expiresAt,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Task 7.1: Reminder collision detection ─────────────────────────────────
  group('Reminder collision detection', () {
    test('Two reminders 2 min apart → collision detected', () async {
      final existing = _makeReminder(
        id: 'r1',
        scheduledAtIso: '2026-05-22T06:00:00.000',
        taskTitle: 'Morning Run',
      );
      final detector = AiConflictDetector(
        reminderRepository: _FakeReminderRepository(reminders: [existing]),
        contextOverrideRepository: _FakeContextOverrideRepository(),
      );

      final action = _addReminderAction(reminderTime: '06:02'); // 2 min later
      final result = await detector.detect([action]);

      expect(result.softConflicts, isNotEmpty);
      expect(
        result.softConflicts.first,
        contains('Morning Run'),
      );
      expect(result.hardBlocks, isEmpty);
    });

    test('Two reminders 5 min apart → no collision', () async {
      final existing = _makeReminder(
        id: 'r1',
        scheduledAtIso: '2026-05-22T06:00:00.000',
        taskTitle: 'Morning Run',
      );
      final detector = AiConflictDetector(
        reminderRepository: _FakeReminderRepository(reminders: [existing]),
        contextOverrideRepository: _FakeContextOverrideRepository(),
      );

      final action = _addReminderAction(reminderTime: '06:05'); // 5 min later
      final result = await detector.detect([action]);

      expect(result.softConflicts, isEmpty);
      expect(result.hardBlocks, isEmpty);
    });
  });

  // ── Task 7.2: Context conflict detection ───────────────────────────────────
  group('Context conflict detection', () {
    test('Task inside sleep window → added to softConflicts', () async {
      final attentionState = _stateWithSleepWindow(
        start: '23:00',
        end: '07:00',
      );
      final detector = AiConflictDetector(
        reminderRepository: _FakeReminderRepository(),
        contextOverrideRepository: _FakeContextOverrideRepository(
          state: attentionState,
        ),
      );

      final action = _createTaskAction(time: '02:00'); // 2 AM inside sleep
      final result = await detector.detect([action]);

      expect(result.softConflicts, isNotEmpty);
      expect(result.softConflicts.first, contains('sleep window'));
      expect(result.hardBlocks, isEmpty);
    });

    test(
      'Task inside active DND override → added to hardBlocks',
      () async {
        final now = DateTime(2026, 5, 22, 10, 0); // 10:00 AM
        final expiresAt = DateTime(2026, 5, 22, 12, 0); // 12:00 PM
        final attentionState = _stateWithActiveOverride(
          override: ContextOverride.doNotDisturb,
          activatedAt: now,
          expiresAt: expiresAt,
        );
        final detector = AiConflictDetector(
          reminderRepository: _FakeReminderRepository(),
          contextOverrideRepository: _FakeContextOverrideRepository(
            state: attentionState,
          ),
        );

        final action = _createTaskAction(time: '10:30'); // inside DND 10–12
        final result = await detector.detect([action]);

        expect(result.hardBlocks, isNotEmpty);
        expect(result.hardBlocks.first, contains('⛔'));
        expect(result.softConflicts, isEmpty);
      },
    );

    test(
      'Task inside active Focus override → added to softConflicts (advisory)',
      () async {
        final now = DateTime(2026, 5, 22, 10, 0);
        final expiresAt = DateTime(2026, 5, 22, 12, 0);
        final attentionState = _stateWithActiveOverride(
          override: ContextOverride.focus,
          activatedAt: now,
          expiresAt: expiresAt,
        );
        final detector = AiConflictDetector(
          reminderRepository: _FakeReminderRepository(),
          contextOverrideRepository: _FakeContextOverrideRepository(
            state: attentionState,
          ),
        );

        final action = _createTaskAction(time: '10:30'); // inside focus 10–12
        final result = await detector.detect([action]);

        expect(result.softConflicts, isNotEmpty);
        expect(result.softConflicts.first, contains('Focus'));
        expect(result.hardBlocks, isEmpty);
      },
    );

    test('Task outside any override → no conflicts', () async {
      final detector = AiConflictDetector(
        reminderRepository: _FakeReminderRepository(),
        contextOverrideRepository: _FakeContextOverrideRepository(),
      );

      final action = _createTaskAction(time: '09:00');
      final result = await detector.detect([action]);

      expect(result.softConflicts, isEmpty);
      expect(result.hardBlocks, isEmpty);
    });
  });

  // ── Enforcement mode conflict ──────────────────────────────────────────────
  group('Enforcement mode conflict', () {
    test('moveTask with strictModeRequired → advisory warning added', () async {
      final detector = AiConflictDetector(
        reminderRepository: _FakeReminderRepository(),
        contextOverrideRepository: _FakeContextOverrideRepository(),
      );

      final action = AiAction(
        actionType: ActionType.moveTask,
        parameters: {
          'taskTitle': 'Deep Work',
          'strictModeRequired': true,
          'destinationDate': '2026-05-23',
        },
        confidence: 0.9,
      );
      final result = await detector.detect([action]);

      expect(result.softConflicts, isNotEmpty);
      expect(result.softConflicts.first, contains('strict mode'));
      expect(result.hardBlocks, isEmpty);
    });

    test(
      'moveTask without strictModeRequired → no enforcement warning',
      () async {
        final detector = AiConflictDetector(
          reminderRepository: _FakeReminderRepository(),
          contextOverrideRepository: _FakeContextOverrideRepository(),
        );

        final action = AiAction(
          actionType: ActionType.moveTask,
          parameters: {
            'taskTitle': 'Morning Walk',
            'destinationDate': '2026-05-23',
          },
          confidence: 0.9,
        );
        final result = await detector.detect([action]);

        expect(result.softConflicts, isEmpty);
        expect(result.hardBlocks, isEmpty);
      },
    );
  });
}
