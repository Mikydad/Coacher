/// Coach AI scenario harness (AI chat fix plan Phase 0.2, 2026-09-26).
///
/// Runs the REAL pipeline — `ProxyAiOperatingLayerClient` (tool-call
/// mapping + normaliser), `AiIntentParser`, `AiAssistantService`,
/// `AiActionExecutor`, `AiPayloadAssembler` — over in-memory repositories,
/// with the model replaced by a scripted proxy that feeds raw replies (text
/// or `propose_changes` tool calls) one per round. Scenarios assert the
/// resulting RECORDS (tasks, goals, history rows, batches, card state), not
/// only the reply text. Only the batch repository is real Isar (temp dir;
/// `libisar.dylib` ships in the repo root, so this runs offline).
library;

import 'dart:convert';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:sidepal/core/ai/ai_proxy_client.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_ai_interaction_history.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_batch_repository.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:sidepal/features/ai_assistant/application/ai_conflict_detector.dart';
import 'package:sidepal/features/ai_assistant/application/ai_entity_resolver.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_chat_message.dart';
import 'package:sidepal/features/coaching/data/coaching_style_repository.dart';
import 'package:sidepal/features/coaching/domain/models/user_coaching_profile.dart';
import 'package:sidepal/features/context_override/application/context_override_service.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/goals/domain/models/goal_action.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/application/reminder_sync_service.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/time_blocks/application/time_block_sync_service.dart';
import 'package:sidepal/features/time_blocks/domain/models/scheduled_time_block.dart';

import 'isar_test_harness.dart';

// ─── Scripted model ──────────────────────────────────────────────────────────

/// One scripted model reply per round, in order. Records every message list
/// the client sent so scenarios can assert on the prompt the model saw.
class ScriptedProxy implements AiProxyClient {
  ScriptedProxy([List<AiProxyChatResult>? script]) : _script = [...?script];

  final List<AiProxyChatResult> _script;
  final List<List<Map<String, dynamic>>> calls = [];

  /// Queue more replies mid-scenario (one per expected round).
  void enqueue(AiProxyChatResult reply) => _script.add(reply);

  /// Plain assistant text — an informational reply.
  static AiProxyChatResult text(String content) =>
      AiProxyChatResult(content: content);

  /// A `propose_changes` tool call with the given actions.
  static AiProxyChatResult propose({
    required String presentation,
    required List<Map<String, dynamic>> actions,
    String? message,
    String? content,
    String callId = 'call_1',
  }) {
    return AiProxyChatResult(
      content: content,
      toolCalls: [
        AiProxyToolCall(
          id: callId,
          name: 'propose_changes',
          arguments: jsonEncode({
            'presentation': presentation,
            'message': ?message,
            'actions': actions,
          }),
        ),
      ],
    );
  }

  /// One createTask action map in the documented parameter shape.
  static Map<String, dynamic> createTask({
    required String title,
    required String time,
    int duration = 30,
    String date = 'today',
    double confidence = 0.9,
  }) => {
    'actionType': 'createTask',
    'parameters': {
      'title': title,
      'time': time,
      'duration': duration,
      'date': date,
    },
    'confidence': confidence,
  };

  /// The last user-role message content of the most recent call — the
  /// context-grounded prompt the model saw for that round.
  String lastUserPrompt([int? callIndex]) {
    final call = calls[callIndex ?? calls.length - 1];
    final user = call.lastWhere((m) => m['role'] == 'user');
    return user['content'] as String;
  }

  @override
  Future<AiProxyChatResult> chatWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required String turnId,
    required int loopIndex,
    double temperature = 0.4,
    int maxTokens = 800,
    String? purpose,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls.add(List.of(messages));
    if (_script.isEmpty) {
      throw StateError(
        'ScriptedProxy: no reply queued for call ${calls.length} '
        '(loopIndex $loopIndex). Enqueue one per model round.',
      );
    }
    return _script.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// ─── In-memory repositories ──────────────────────────────────────────────────

class _NoopFake {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

/// Tasks keyed by date; one routine + one block per day, ids derived from
/// the date so the executor's resolver stamps line up.
class InMemoryPlanningRepo extends _NoopFake implements PlanningRepository {
  final Map<String, List<PlannedTask>> tasksByDate = {};

  static String routineIdFor(String dateKey) => 'r-$dateKey';
  static String blockIdFor(String dateKey) => 'b-r-$dateKey';
  static String _dateFromRoutine(String routineId) =>
      routineId.startsWith('r-') ? routineId.substring(2) : routineId;

  List<PlannedTask> tasksOn(String dateKey) =>
      List.unmodifiable(tasksByDate[dateKey] ?? const []);

  /// Seeds a task; defaults mirror a scheduled 45-minute task.
  PlannedTask seed({
    required String title,
    required String dateKey,
    String? id,
    String? time, // "HH:mm" → reminderTimeIso on that day
    int durationMinutes = 45,
    TaskStatus status = TaskStatus.notStarted,
  }) {
    final taskId = id ?? 't-${title.toLowerCase().replaceAll(' ', '-')}-$dateKey';
    String? iso;
    if (time != null) {
      final day = DateKeys.parseLocalDateKey(dateKey);
      final parts = time.split(':');
      iso = DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ).toIso8601String();
    }
    final task = PlannedTask(
      id: taskId,
      routineId: routineIdFor(dateKey),
      blockId: blockIdFor(dateKey),
      title: title,
      durationMinutes: durationMinutes,
      priority: 2,
      orderIndex: (tasksByDate[dateKey]?.length ?? 0),
      reminderEnabled: iso != null,
      reminderTimeIso: iso,
      status: status,
      createdAtMs: 1,
      updatedAtMs: 1,
      planDateKey: dateKey,
    );
    tasksByDate.putIfAbsent(dateKey, () => []).add(task);
    return task;
  }

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => [
    Routine(
      id: routineIdFor(dateKey),
      title: 'Day',
      dateKey: dateKey,
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => [
    TaskBlock(
      id: 'b-$routineId',
      routineId: routineId,
      title: 'Block',
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async => List.of(tasksByDate[_dateFromRoutine(routineId)] ?? const []);

  @override
  Future<void> upsertTask(PlannedTask task) async {
    final dateKey = task.planDateKey ?? _dateFromRoutine(task.routineId);
    final list = tasksByDate.putIfAbsent(dateKey, () => []);
    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx == -1) {
      list.add(task);
    } else {
      list[idx] = task;
    }
  }

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {
    for (final list in tasksByDate.values) {
      list.removeWhere((t) => t.id == taskId);
    }
  }

  @override
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(
    String dateKey,
  ) async => (routineId: routineIdFor(dateKey), blockId: blockIdFor(dateKey));
}

class InMemoryGoalsRepo extends _NoopFake implements GoalsRepository {
  final List<UserGoal> goals = [];
  final List<GoalCheckIn> checkIns = [];

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => List.of(goals);

  @override
  Future<UserGoal?> getGoal(String goalId) async {
    for (final g in goals) {
      if (g.id == goalId) return g;
    }
    return null;
  }

  @override
  Future<void> upsertGoal(UserGoal goal) async {
    final idx = goals.indexWhere((g) => g.id == goal.id);
    if (idx == -1) {
      goals.add(goal);
    } else {
      goals[idx] = goal;
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async =>
      goals.removeWhere((g) => g.id == goalId);

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async => checkIns
      .where(
        (c) =>
            c.goalId == goalId &&
            (startDateKey == null || c.dateKey.compareTo(startDateKey) >= 0) &&
            (endDateKey == null || c.dateKey.compareTo(endDateKey) <= 0),
      )
      .toList();

  @override
  Future<List<GoalAction>> getActions(String goalId) async => const [];
}

/// History rows in memory, newest-first queries like the Isar repository.
class InMemoryHistoryRepo extends _NoopFake
    implements AiInteractionHistoryRepository {
  final List<IsarAiInteractionHistory> rows = [];
  int _clock = 0;

  /// Set to make a mutation throw once (retry-hole scenarios).
  Object? failNextMarkExecuted;

  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {
    rows.add(
      IsarAiInteractionHistory()
        ..sessionId = sessionId
        ..userInput = userInput
        ..parsedActionsJson = jsonEncode(
          parsedActions.map((a) => a.toJson()).toList(),
        )
        ..confirmed = false
        ..executed = false
        ..resolvedCategory = resolvedCategory
        ..assistantSummary = assistantSummary
        ..responseType = responseType
        ..timestampMs = ++_clock,
    );
  }

  List<IsarAiInteractionHistory> _session(String sessionId) =>
      rows.where((r) => r.sessionId == sessionId).toList()
        ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

  @override
  Future<List<IsarAiInteractionHistory>> getRecentForSession(
    String sessionId, {
    int limit = 10,
  }) async => _session(sessionId).take(limit).toList();

  @override
  Future<List<IsarAiInteractionHistory>> getAllForSession(
    String sessionId,
  ) async => _session(sessionId).reversed.toList();

  @override
  Future<List<IsarAiInteractionHistory>> getRecent({int limit = 10}) async =>
      (List.of(rows)..sort((a, b) => b.timestampMs.compareTo(a.timestampMs)))
          .take(limit)
          .toList();

  @override
  Future<IsarAiInteractionHistory?> getMostRecentUnconfirmed({
    int withinMinutes = 30,
  }) async => null;

  IsarAiInteractionHistory? _latest(String sessionId) {
    final s = _session(sessionId);
    return s.isEmpty ? null : s.first;
  }

  @override
  Future<void> markConfirmed(String sessionId) async =>
      _latest(sessionId)?.confirmed = true;

  @override
  Future<void> markExecuted(String sessionId) async {
    final failure = failNextMarkExecuted;
    if (failure != null) {
      failNextMarkExecuted = null;
      throw failure;
    }
    _latest(sessionId)?.executed = true;
  }

  @override
  Future<void> saveAssistantSummary(String sessionId, String summary) async =>
      _latest(sessionId)?.assistantSummary = summary;

  @override
  Future<void> updateResolvedCategory(String sessionId, String category) async {
    for (final r in rows) {
      if (r.sessionId == sessionId) r.resolvedCategory = category;
    }
  }
}

class _FakeContextOverrideRepo extends _NoopFake
    implements ContextOverrideRepository {
  @override
  Future<UserAttentionState?> getAttentionState() async => null;
}

class _FakeCoachingStyleRepo extends _NoopFake
    implements CoachingStyleRepository {
  @override
  Future<UserCoachingProfile?> getProfile() async => null;
}

class _FakeReminderRepo extends _NoopFake implements ReminderRepository {
  final upserted = <ReminderConfig>[];

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async => const [];

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async =>
      upserted.add(reminder);
}

class _FakeReminderSync extends _NoopFake implements ReminderSyncService {
  @override
  Future<void> removeForDeletedTask(String taskId) async {}

  @override
  Future<void> syncForTaskIds(List<String> taskIds) async {}
}

class _FakeTimeBlockSync extends _NoopFake implements TimeBlockSyncService {
  @override
  Future<void> removeBlockForEntity(String entityId) async {}

  @override
  ScheduledTimeBlock? deriveBlock({
    required String entityId,
    required String entityKind,
    required DateTime? startAt,
    required int? durationMinutes,
    String? modeRefId,
    bool isRigid = false,
    bool allowOverlapOverride = false,
  }) => null;
}

class _FakeContextOverrideService extends _NoopFake
    implements ContextOverrideService {}

// ─── The scenario ────────────────────────────────────────────────────────────

/// One assembled Coach stack. Create with [AiScenario.start], drive
/// [service], inspect [planning] / [goals] / [history] / [proxy] / [batches],
/// then [dispose].
class AiScenario {
  AiScenario._({
    required this.proxy,
    required this.planning,
    required this.goals,
    required this.history,
    required this.batches,
    required this.service,
    required Isar isar,
    required Directory dir,
  }) : _isar = isar,
       _dir = dir;

  final ScriptedProxy proxy;
  final InMemoryPlanningRepo planning;
  final InMemoryGoalsRepo goals;
  final InMemoryHistoryRepo history;
  final AiActionBatchRepository batches;
  final AiAssistantService service;
  final Isar _isar;
  final Directory _dir;

  static Future<AiScenario> start({List<AiProxyChatResult>? script}) async {
    final opened = await openTempIsar();
    final proxy = ScriptedProxy(script);
    final planning = InMemoryPlanningRepo();
    final goals = InMemoryGoalsRepo();
    final history = InMemoryHistoryRepo();
    final batches = AiActionBatchRepository(opened.isar);
    final contextOverrideRepo = _FakeContextOverrideRepo();
    final reminderRepo = _FakeReminderRepo();

    final assembler = AiPayloadAssembler(
      planningRepository: planning,
      goalsRepository: goals,
      contextOverrideRepository: contextOverrideRepo,
      coachingStyleRepository: _FakeCoachingStyleRepo(),
      historyRepository: history,
    );
    final client = ProxyAiOperatingLayerClient(
      proxy: proxy,
      toolRunner: AiCoachToolRunner(
        dayScheduleLookup: (dateKey) async {
          final tasks = planning.tasksOn(dateKey);
          if (tasks.isEmpty) return 'No tasks on $dateKey.';
          return tasks.map((t) => '${t.title} (${t.reminderTimeIso})').join(', ');
        },
      ),
    );
    final parser = AiIntentParser(
      client: client,
      assembler: assembler,
      assumptionEngine: AiAssumptionEngine(
        planningRepository: planning,
        historyRepository: history,
        normaliser: const EntityNormaliser(),
      ),
      conflictDetector: AiConflictDetector(
        reminderRepository: reminderRepo,
        contextOverrideRepository: contextOverrideRepo,
      ),
      entityResolver: AiEntityResolver(
        planningRepository: planning,
        goalsRepository: goals,
      ),
    );
    final executor = AiActionExecutor(
      planningRepository: planning,
      goalsRepository: goals,
      reminderRepository: reminderRepo,
      reminderSyncService: _FakeReminderSync(),
      timeBlockSyncService: _FakeTimeBlockSync(),
      contextOverrideService: _FakeContextOverrideService(),
      batchRepository: batches,
    );
    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: executor,
      historyRepository: history,
      onScheduleMutated: assembler.invalidateSessionCache,
    );
    return AiScenario._(
      proxy: proxy,
      planning: planning,
      goals: goals,
      history: history,
      batches: batches,
      service: service,
      isar: opened.isar,
      dir: opened.dir,
    );
  }

  // ─── Inspection helpers ──────────────────────────────────────────────────

  List<AiChatMessage> get messages => service.messages;

  AiChatMessage get lastAssistant =>
      messages.lastWhere((m) => m.role == ChatRole.assistant);

  /// The newest assistant message carrying a suggest draft (Apply button).
  AiChatMessage? get latestDraft {
    for (final m in messages.reversed) {
      if (m.hasDraftPlan) return m;
    }
    return null;
  }

  /// The newest assistant message carrying a preview card.
  AiChatMessage? get latestCard {
    for (final m in messages.reversed) {
      if (m.hasPreviewCard) return m;
    }
    return null;
  }

  bool get anyLiveCard => messages.any(
    (m) => m.hasPreviewCard && m.isCurrentPlan && !m.isExecuted && !m.isCancelled,
  );

  List<String> titlesOn(String dateKey) =>
      planning.tasksOn(dateKey).map((t) => t.title).toList();

  Future<void> dispose() async {
    service.dispose();
    await closeTempIsar(_isar, _dir);
  }
}
