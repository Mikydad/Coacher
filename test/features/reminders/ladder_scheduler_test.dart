import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/analytics/data/focus_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/reminders/application/attention_orchestrator_service.dart';
import 'package:sidepal/features/reminders/application/ladder_compiler.dart';
import 'package:sidepal/features/reminders/application/ladder_scheduler.dart';
import 'package:sidepal/features/reminders/data/reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/attention_decision.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

import '../../support/no_op_notification_ledger.dart';

/// Audit B2/B3 + A3: what rearmAll arms, cancels, and refuses to touch.

class _Occurrences implements ReminderOccurrenceRepository {
  _Occurrences(this.open);
  final List<ReminderOccurrence> open;

  @override
  Future<List<ReminderOccurrence>> listUnresolved() async => open;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<List<ReminderOccurrence>>.value(const []);
}

class _Orchestrator extends AttentionOrchestratorService {
  _Orchestrator()
    : super(
        contextOverrideRepository: _NoOpOverrideRepo(),
        focusRepository: _NoOpFocusRepo(),
        reminderRepository: _NoOpReminderRepo(),
        notifications: LocalNotificationsService.instance,
        ledger: NoOpNotificationLedger(),
        logEvent: _noOpLog,
      );

  final List<ReminderIntent> evaluated = [];
  final List<(String, int)> cancelledSlots = [];

  @override
  Future<AttentionDecision> evaluate(ReminderIntent intent) async {
    evaluated.add(intent);
    return AttentionDecision.approved(
      intentId: intent.id,
      deliverAt: intent.proposedAt,
    );
  }

  @override
  Future<void> cancelTaskSlot(String entityId, int slot) async {
    cancelledSlots.add((entityId, slot));
  }
}

Future<void> _noOpLog({
  required AnalyticsEventType type,
  required String entityId,
  required String entityKind,
  required String sourceSurface,
  required String idempotencyKey,
  String? reason,
}) async {}

class _NoOpOverrideRepo implements ContextOverrideRepository {
  @override
  Future<UserAttentionState?> getAttentionState() async => null;
  @override
  Future<void> upsertAttentionState(UserAttentionState state) async {}
  @override
  Stream<UserAttentionState?> watchAttentionState() => const Stream.empty();
}

class _NoOpFocusRepo implements FocusRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<CurrentCoachingFocus?>.value(null);
}

class _NoOpReminderRepo implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> listAllReminders() async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  final now = DateTime(2026, 8, 31, 13, 0);
  final twoPm = DateTime(2026, 8, 31, 14, 0);

  ReminderOccurrence occ({
    String id = 'task-1',
    String entityKind = 'task',
    String modeRefId = 'disciplined',
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
  }) => ReminderOccurrence(
    id: 'o-$id',
    entityId: id,
    entityKind: entityKind,
    dateKey: DateKeys.yyyymmdd(twoPm),
    scheduledAtMs: twoPm.millisecondsSinceEpoch,
    windowMinutes: 45,
    entityTitle: 'Study',
    modeRefId: modeRefId,
    taxonomy: taxonomy,
    createdAtMs: 1,
    updatedAtMs: 1,
  );

  LadderScheduler scheduler(
    _Occurrences occurrences,
    _Orchestrator orchestrator,
  ) => LadderScheduler(
    occurrences: occurrences,
    orchestrator: orchestrator,
    loadUpcomingStarts: (_) async => const [],
    now: () => now,
  );

  test('a task occurrence arms its full ladder', () async {
    final orchestrator = _Orchestrator();
    await scheduler(_Occurrences([occ()]), orchestrator).rearmAll();

    expect(orchestrator.evaluated.map((i) => i.slot), [0, 1, 2]);
  });

  test('goal and intention occurrences are never armed here (A3)', () async {
    final orchestrator = _Orchestrator();
    final result = await scheduler(
      _Occurrences([
        occ(id: 'g1', entityKind: 'goal', taxonomy: ReminderTaxonomy.routine),
        occ(id: 'i1', entityKind: 'intention'),
      ]),
      orchestrator,
    ).rearmAll();

    expect(orchestrator.evaluated, isEmpty);
    expect(result.armed, 0);
  });

  test(
    'an ephemeral session shield silences armed slots inside it (B2)',
    () async {
      final orchestrator = _Orchestrator();
      // Session 13:55 → 14:20 covers T+0 (14:00) and T+10 (14:10).
      await scheduler(_Occurrences([occ()]), orchestrator).rearmAll(
        extraShields: [
          ShieldWindow(
            start: twoPm.subtract(const Duration(minutes: 5)),
            end: twoPm.add(const Duration(minutes: 20)),
            reason: 'focus',
          ),
        ],
      );

      // Only T+25 survives; the two shielded slots are actively cancelled so
      // an earlier compile's armed leftovers die NOW, not at next cold start.
      expect(orchestrator.evaluated.map((i) => i.slot), [2]);
      expect(
        orchestrator.cancelledSlots,
        containsAll([('task-1', 0), ('task-1', 1)]),
      );
    },
  );

  test('criticality 3 ignores the session shield (D5)', () async {
    final orchestrator = _Orchestrator();
    final critical = ReminderOccurrence(
      id: 'o-meds',
      entityId: 'meds',
      entityKind: 'task',
      dateKey: DateKeys.yyyymmdd(twoPm),
      scheduledAtMs: twoPm.millisecondsSinceEpoch,
      windowMinutes: 45,
      entityTitle: 'Take meds',
      modeRefId: 'disciplined',
      taxonomy: ReminderTaxonomy.timeSensitive,
      criticality: 3,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
    await scheduler(_Occurrences([critical]), orchestrator).rearmAll(
      extraShields: [
        ShieldWindow(
          start: twoPm.subtract(const Duration(hours: 1)),
          end: twoPm.add(const Duration(hours: 1)),
          reason: 'focus',
        ),
      ],
    );

    expect(orchestrator.evaluated, hasLength(3));
    expect(orchestrator.cancelledSlots, isEmpty);
  });
}
