import 'package:sidepal/features/education/application/education_prefs.dart';
import 'package:sidepal/features/education/application/getting_started_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GettingStartedController _controller({
  bool existingData = false,
  int streak = 0,
  Duration celebrateFor = const Duration(minutes: 1),
  Duration titleSettleFor = const Duration(milliseconds: 5),
}) => GettingStartedController(
  EducationPrefs(),
  hasExistingDataProbe: () async => existingData,
  streakReader: () => streak,
  celebrateFor: celebrateFor,
  titleSettleFor: titleSettleFor,
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('new-vs-existing gate', () {
    test('fresh user → tour active at tapAddTask, decision persisted',
        () async {
      final c = _controller();
      await _settle();
      expect(c.state.status, TourStatus.active);
      expect(c.state.step, TourStep.tapAddTask);
      expect(await EducationPrefs().onboardingState(), 'active');
    });

    test('user with existing tasks → silently done and hidden', () async {
      final c = _controller(existingData: true);
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(await EducationPrefs().onboardingState(), 'done');
    });

    test('user with a streak → silently done', () async {
      final c = _controller(streak: 4);
      await _settle();
      expect(c.state.status, TourStatus.hidden);
    });

    test("stored 'done' → hidden without probing", () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1': 'done',
      });
      var probed = false;
      final c = GettingStartedController(
        EducationPrefs(),
        hasExistingDataProbe: () async {
          probed = true;
          return false;
        },
        streakReader: () => 0,
      );
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(probed, isFalse);
    });

    test(
      "stored 'active' resumes even though the user now has data "
      '(first-task bug guard)',
      () async {
        SharedPreferences.setMockInitialValues({
          'education_onboarding_state_v1': 'active',
        });
        final c = _controller(existingData: true, streak: 9);
        await _settle();
        expect(c.state.status, TourStatus.active);
      },
    );

    test('probe failure still onboards the new user', () async {
      final c = GettingStartedController(
        EducationPrefs(),
        hasExistingDataProbe: () async => throw Exception('probe broke'),
        streakReader: () => 0,
      );
      await _settle();
      expect(c.state.status, TourStatus.active);
    });
  });

  group('step advancement', () {
    test('the golden path: tap → name → save → complete → celebrate',
        () async {
      final c = _controller(celebrateFor: const Duration(milliseconds: 5));
      await _settle();
      expect(c.state.step, TourStep.tapAddTask);

      c.onRouteChanged('/add-task');
      expect(c.state.step, TourStep.nameTask);

      // Advancing to "save it" waits for the user to pause typing.
      c.onTaskTitleChanged('Read 10 pages');
      expect(c.state.step, TourStep.nameTask);
      await _settle();
      expect(c.state.step, TourStep.saveTask);

      // Saved: rows now contain the task; route pops home.
      c.onTaskRows(anyTask: true, anyCompleted: false);
      c.onRouteChanged('/');
      expect(c.state.step, TourStep.completeTask);

      // Hours later: completed.
      c.onTaskRows(anyTask: true, anyCompleted: true);
      expect(c.state.step, TourStep.seeProgress);

      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(await EducationPrefs().onboardingState(), 'done');
    });

    test('leaving Add Task without saving rewinds to tapAddTask', () async {
      final c = _controller();
      await _settle();
      c.onRouteChanged('/add-task');
      c.onTaskTitleChanged('half typed');
      await _settle();
      expect(c.state.step, TourStep.saveTask);

      c.onRouteChanged('/'); // backed out, nothing saved
      expect(c.state.step, TourStep.tapAddTask);
    });

    test('typing pause is debounced: keystrokes keep it at nameTask',
        () async {
      final c = _controller(titleSettleFor: const Duration(milliseconds: 15));
      await _settle();
      c.onRouteChanged('/add-task');

      // A burst of keystrokes — each one restarts the settle timer.
      c.onTaskTitleChanged('R');
      c.onTaskTitleChanged('Re');
      c.onTaskTitleChanged('Rea');
      expect(c.state.step, TourStep.nameTask);

      // Cleared before the pause elapsed → no advance at all.
      c.onTaskTitleChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(c.state.step, TourStep.nameTask);

      // Typed again and left alone → advances after the pause.
      c.onTaskTitleChanged('Read');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(c.state.step, TourStep.saveTask);
    });

    test('leaving Add Task AFTER saving does not rewind', () async {
      final c = _controller();
      await _settle();
      c.onRouteChanged('/add-task');
      c.onTaskTitleChanged('Read');
      c.onTaskRows(anyTask: true, anyCompleted: false); // saved
      c.onRouteChanged('/');
      expect(c.state.step, TourStep.completeTask);
    });

    test('resume: task already created → completeTask hint', () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1': 'active',
      });
      final c = _controller();
      // Signal arrives before init resolves (buffered).
      c.onTaskRows(anyTask: true, anyCompleted: false);
      await _settle();
      expect(c.state.status, TourStatus.active);
      expect(c.state.step, TourStep.completeTask);
    });

    test('resume: task already completed → straight to celebration → done',
        () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1': 'active',
      });
      final c = _controller(celebrateFor: const Duration(milliseconds: 5));
      c.onTaskRows(anyTask: true, anyCompleted: true);
      await _settle();
      expect(await EducationPrefs().onboardingState(), 'done');
    });
  });

  test('skip persists done immediately', () async {
    final c = _controller();
    await _settle();
    expect(c.state.status, TourStatus.active);

    await c.skip();
    expect(c.state.status, TourStatus.hidden);
    expect(await EducationPrefs().onboardingState(), 'done');
  });
}
