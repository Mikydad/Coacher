import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/features/add_task/presentation/add_task_args.dart';
import 'package:sidepal/features/add_task/presentation/add_task_screen.dart';
import 'package:sidepal/features/analytics/application/feature_builder_recompute_service.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/education/application/education_prefs.dart';
import 'package:sidepal/features/education/application/getting_started_controller.dart';
import 'package:sidepal/features/planning/application/form_draft_providers.dart';
import 'package:sidepal/features/planning/domain/add_task_duration.dart';
import 'package:sidepal/features/planning/domain/models/add_task_form_draft.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/profile/application/profile_providers.dart';
import 'package:sidepal/features/profile/domain/models/user_profile_preference.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';

import '../../support/no_op_planning_repository.dart';

/// Smoke coverage for [AddTaskScreen] rendering — the safety net for the
/// add_task file split. Finds by visible text/widget type only (never private
/// members) so the assertions survive the refactor unchanged. The save path is
/// deliberately not exercised (tier gates reach FirebaseAuth/Isar statics).

class _FakePlanningRepository extends NoOpPlanningRepository {
  _FakePlanningRepository({this.tasks = const []});

  final List<PlannedTask> tasks;

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async => tasks
      .where((t) => t.routineId == routineId && t.blockId == blockId)
      .toList();
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({this.reminders = const []});

  final List<ReminderConfig> reminders;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => reminders;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async => reminders.where((r) => taskIds.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

class _NoOpAnalyticsRepository implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoOpRecomputeService implements FeatureBuilderRecomputeService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Widget _app({
  AddTaskEditArgs? editArgs,
  _FakePlanningRepository? planning,
  _FakeReminderRepository? reminders,
}) {
  return ProviderScope(
    overrides: [
      planningRepositoryProvider.overrideWithValue(
        planning ?? _FakePlanningRepository(),
      ),
      reminderRepositoryProvider.overrideWithValue(
        reminders ?? _FakeReminderRepository(),
      ),
      // Null preference stream → defaultEnforcementModeProvider falls back to
      // `disciplined` without touching Isar.
      userProfilePreferenceStreamProvider.overrideWith(
        (ref) => Stream<UserProfilePreference?>.value(null),
      ),
      // Onboarding pref is seeded 'done' (setUp) → tour hidden, no timers, and
      // the real provider's Isar/Firestore listener chains are bypassed.
      gettingStartedControllerProvider.overrideWith(
        (ref) => GettingStartedController(EducationPrefs()),
      ),
      analyticsRepositoryProvider.overrideWithValue(_NoOpAnalyticsRepository()),
      featureBuilderRecomputeServiceProvider.overrideWithValue(
        _NoOpRecomputeService(),
      ),
    ],
    child: MaterialApp(home: AddTaskScreen(editArgs: editArgs)),
  );
}

/// Tall viewport so every section is on-screen at once — assertions don't
/// depend on scroll positions that the refactor might nudge.
Future<void> _pump(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({kOnboardingStatePrefsKey: 'done'});
  });

  testWidgets('create mode renders every section', (tester) async {
    await _pump(tester, _app());

    expect(find.text('What do you want to do?'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Accountability'), findsOneWidget);
    expect(find.text('Deep Work'), findsOneWidget);
    expect(find.text('ADVANCED SETTINGS'), findsOneWidget);
    // Twice: the small-caps AppBar PageTitle and the save button.
    expect(find.text('ADD TASK'), findsNWidgets(2));
    expect(find.text('Sleep window & quiet mode'), findsNothing);
  });

  testWidgets('selecting Sleep swaps to the sleep layout', (tester) async {
    await _pump(tester, _app());

    await tester.tap(find.text('SLEEP'));
    await tester.pumpAndSettle();

    // Sleep-specific chrome appears…
    expect(find.text('Sleep length'), findsOneWidget);
    expect(find.text('Sleep window & quiet mode'), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    // …the paired accountability/deep-work row becomes the full-width row…
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('Deep Work'), findsNothing);
    expect(find.text('ADVANCED SETTINGS'), findsNothing);
    // …sleep defaults kick in: reminder forced on (start/end pickers) and the
    // title autofilled.
    expect(find.text('Sleep start'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Sleep'), findsOneWidget);
  });

  testWidgets('edit mode prefills from the stored task', (tester) async {
    final planning = _FakePlanningRepository(
      tasks: [
        const PlannedTask(
          id: 't1',
          routineId: 'r1',
          blockId: 'b1',
          title: 'Read 20 pages',
          durationMinutes: 25,
          priority: 3,
          orderIndex: 0,
          reminderEnabled: true,
          reminderTimeIso: '2026-08-08T09:30:00.000',
          status: TaskStatus.notStarted,
          createdAtMs: 1000,
          updatedAtMs: 1000,
          category: 'Study',
        ),
      ],
    );
    final reminders = _FakeReminderRepository(
      reminders: [
        const ReminderConfig(
          id: 'rem1',
          taskId: 't1',
          enabled: true,
          scheduledAtIso: '2026-08-08T09:30:00.000',
          createdAtMs: 1000,
          updatedAtMs: 1000,
        ),
      ],
    );

    await _pump(
      tester,
      _app(
        editArgs: const AddTaskEditArgs(
          taskId: 't1',
          routineId: 'r1',
          blockId: 'b1',
          dateKey: '2026-08-08',
        ),
        planning: planning,
        reminders: reminders,
      ),
    );

    expect(find.text('EDIT TASK'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Read 20 pages'), findsOneWidget);
    expect(find.text('SAVE CHANGES'), findsOneWidget);
    expect(find.text('9:30 AM'), findsOneWidget);
  });

  testWidgets('meaningful draft offers restore and applies it', (tester) async {
    final draft = AddTaskFormDraft(
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      title: 'Half-typed task',
      notes: '',
      duration: '25 MIN',
      durationEnabled: false,
      customDurationMinutes: kAddTaskDefaultCustomMinutes,
      reminder: false,
      focusSession: false,
      isHabitAnchor: false,
      reminderTimeMs: DateTime.now().millisecondsSinceEpoch,
      modeRefId: 'flexible',
      strictModeRequired: false,
      modeUserCustomized: false,
      isRigid: false,
      advancedExpanded: false,
      syncSleepWindowAndQuietMode: true,
      inAppQuietMode: 'sleep',
    );
    SharedPreferences.setMockInitialValues({
      kOnboardingStatePrefsKey: 'done',
      'form_draft_v1_${addTaskCreateDraftKey()}': jsonEncode(draft.toJson()),
    });

    await _pump(tester, _app());

    expect(find.text('Restore draft?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Half-typed task'), findsOneWidget);
  });
}
