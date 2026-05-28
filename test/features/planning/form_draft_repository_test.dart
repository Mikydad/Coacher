import 'package:coach_for_life/features/goals/domain/models/goal_editor_form_draft.dart';
import 'package:coach_for_life/features/planning/application/form_draft_providers.dart';
import 'package:coach_for_life/features/planning/data/form_draft_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/add_task_form_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FormDraftRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FormDraftRepository();
  });

  test('round-trips add task draft JSON', () async {
    final draft = AddTaskFormDraft(
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      title: 'Deep work',
      notes: 'Notes',
      duration: '25 MIN',
      customDurationMinutes: 90,
      category: 'Study',
      reminder: true,
      focusSession: false,
      isHabitAnchor: true,
      reminderTimeMs: DateTime(2026, 5, 23, 9).millisecondsSinceEpoch,
      modeRefId: 'disciplined',
      strictModeRequired: true,
      modeUserCustomized: true,
      isRigid: false,
      advancedExpanded: true,
      syncSleepWindowAndQuietMode: true,
      inAppQuietMode: 'sleep',
    );

    await repository.save(addTaskCreateDraftKey(), draft.toJson());
    final loaded = await repository.load(addTaskCreateDraftKey());
    expect(loaded, isNotNull);

    final restored = AddTaskFormDraft.fromJson(loaded!);
    expect(restored.contentEquals(draft), isTrue);
  });

  test('round-trips goal editor draft with actions', () async {
    final draft = GoalEditorFormDraft(
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      title: 'Run 5k',
      target: '30',
      customLabel: '',
      durationDays: '30',
      categoryId: 'fitness',
      horizon: 'monthly',
      periodMode: 'calendar',
      measurement: 'minutes',
      intensity: 4,
      monthAnchorMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
      rangeStartMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
      rangeEndMs: DateTime(2026, 5, 31).millisecondsSinceEpoch,
      durationStartMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
      reminderEnabled: true,
      reminderMinutesFromMidnight: 480,
      actions: const [
        GoalEditorActionDraftRow(id: 'a1', title: 'Buy shoes', completed: false),
      ],
    );

    await repository.save(goalEditDraftKey('goal-1'), draft.toJson());
    final restored = GoalEditorFormDraft.fromJson(
      (await repository.load(goalEditDraftKey('goal-1')))!,
    );
    expect(restored.contentEquals(draft), isTrue);
  });

  test('create and edit keys are isolated', () async {
    await repository.save(addTaskCreateDraftKey(), {'savedAtMs': 1, 'title': 'create'});
    await repository.save(addTaskEditDraftKey('t1'), {'savedAtMs': 2, 'title': 'edit'});

    expect((await repository.load(addTaskCreateDraftKey()))!['title'], 'create');
    expect((await repository.load(addTaskEditDraftKey('t1')))!['title'], 'edit');
  });

  test('isExpired respects TTL', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(repository.isExpired(now), isFalse);
    expect(
      repository.isExpired(now - (kFormDraftTtlMinutes + 1) * 60 * 1000),
      isTrue,
    );
  });

  test('delete removes draft', () async {
    await repository.save(goalCreateDraftKey(), {'savedAtMs': 1});
    await repository.delete(goalCreateDraftKey());
    expect(await repository.load(goalCreateDraftKey()), isNull);
  });
}
