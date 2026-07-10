import 'package:coach_for_life/features/education/application/education_prefs.dart';
import 'package:coach_for_life/features/education/application/getting_started_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GettingStartedController _controller({
  bool existingData = false,
  int streak = 0,
  Duration celebrateFor = const Duration(milliseconds: 1),
}) => GettingStartedController(
  EducationPrefs(),
  hasExistingDataProbe: () async => existingData,
  streakReader: () => streak,
  celebrateFor: celebrateFor,
);

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh user → active, and the decision is persisted', () async {
    final c = _controller();
    await _settle();
    expect(c.state.phase, GettingStartedPhase.active);
    expect(await EducationPrefs().onboardingState(), 'active');
  });

  test('user with existing tasks → silently done and hidden', () async {
    final c = _controller(existingData: true);
    await _settle();
    expect(c.state.phase, GettingStartedPhase.hidden);
    expect(await EducationPrefs().onboardingState(), 'done');
  });

  test('user with a streak → silently done', () async {
    final c = _controller(streak: 4);
    await _settle();
    expect(c.state.phase, GettingStartedPhase.hidden);
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
    expect(c.state.phase, GettingStartedPhase.hidden);
    expect(probed, isFalse);
  });

  test(
    "stored 'active' resumes active even though the user now has data "
    '(the first-task bug guard)',
    () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1': 'active',
      });
      final c = _controller(existingData: true, streak: 9);
      await _settle();
      expect(c.state.phase, GettingStartedPhase.active);
    },
  );

  test('steps latch and progress in order; step 3 requires step 2', () async {
    final c = _controller(celebrateFor: const Duration(minutes: 1));
    await _settle();

    // Progress signal BEFORE completion must not check step 3.
    c.onProgressSignal(progressed: true);
    expect(c.state.step3ProgressSeen, isFalse);

    c.onTaskRows(anyTask: true, anyCompleted: false);
    expect(c.state.step1TaskCreated, isTrue);
    expect(c.state.step2TaskCompleted, isFalse);

    // Task list becomes empty again (deleted) — step 1 stays latched.
    c.onTaskRows(anyTask: false, anyCompleted: false);
    expect(c.state.step1TaskCreated, isTrue);

    c.onTaskRows(anyTask: true, anyCompleted: true);
    expect(c.state.step2TaskCompleted, isTrue);
    // Buffered progress signal now applies → step 3 + celebration.
    expect(c.state.step3ProgressSeen, isTrue);
    expect(c.state.phase, GettingStartedPhase.celebrating);
  });

  test('celebration persists done and hides', () async {
    final c = _controller(celebrateFor: const Duration(milliseconds: 5));
    await _settle();
    c.onTaskRows(anyTask: true, anyCompleted: true);
    c.onProgressSignal(progressed: true);
    expect(c.state.phase, GettingStartedPhase.celebrating);

    await _settle();
    expect(c.state.phase, GettingStartedPhase.hidden);
    expect(await EducationPrefs().onboardingState(), 'done');
  });

  test('skip persists done immediately', () async {
    final c = _controller();
    await _settle();
    expect(c.state.phase, GettingStartedPhase.active);

    await c.skip();
    expect(c.state.phase, GettingStartedPhase.hidden);
    expect(await EducationPrefs().onboardingState(), 'done');
  });

  test('signals buffered during loading apply once active', () async {
    final c = _controller();
    // Fire before init resolves (no settle yet).
    c.onTaskRows(anyTask: true, anyCompleted: false);
    await _settle();
    expect(c.state.phase, GettingStartedPhase.active);
    expect(c.state.step1TaskCreated, isTrue);
  });

  test('probe failure still onboards the new user', () async {
    final c = GettingStartedController(
      EducationPrefs(),
      hasExistingDataProbe: () async => throw Exception('isar closed'),
      streakReader: () => 0,
    );
    await _settle();
    expect(c.state.phase, GettingStartedPhase.active);
  });
}
