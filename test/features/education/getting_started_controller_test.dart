import 'dart:async';

import 'package:sidepal/features/education/application/education_prefs.dart';
import 'package:sidepal/features/education/application/getting_started_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'u1';
const _key = 'education_onboarding_state_v1:u1';

Future<void> _ready(String _) async {}

GettingStartedController _controller({
  String? uid = _uid,
  bool existingData = false,
  int streak = 0,
  Future<void> Function(String uid) awaitReady = _ready,
  Duration celebrateFor = const Duration(minutes: 1),
  Duration titleSettleFor = const Duration(milliseconds: 5),
}) => GettingStartedController(
  EducationPrefs(),
  uid: uid,
  hasExistingDataProbe: () async => existingData,
  streakReader: () => streak,
  awaitReady: awaitReady,
  celebrateFor: celebrateFor,
  titleSettleFor: titleSettleFor,
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

Future<String?> _stored([String uid = _uid]) =>
    EducationPrefs().onboardingState(uid);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('new-vs-existing gate', () {
    test('fresh user → tour active at tapAddTask, decision persisted',
        () async {
      final c = _controller();
      await _settle();
      expect(c.state.status, TourStatus.active);
      expect(c.state.step, TourStep.tapAddTask);
      expect(await _stored(), 'active');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), 'active', reason: 'keyed per account');
    });

    test('user with existing tasks → silently done and hidden', () async {
      final c = _controller(existingData: true);
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(await _stored(), 'done');
    });

    test('user with a streak → silently done', () async {
      final c = _controller(streak: 4);
      await _settle();
      expect(c.state.status, TourStatus.hidden);
    });

    test("stored 'done' → hidden without probing", () async {
      SharedPreferences.setMockInitialValues({_key: 'done'});
      var probed = false;
      final c = GettingStartedController(
        EducationPrefs(),
        uid: _uid,
        hasExistingDataProbe: () async {
          probed = true;
          return false;
        },
        streakReader: () => 0,
        awaitReady: _ready,
      );
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(probed, isFalse);
    });

    test(
      "stored 'active' resumes even though the user now has data "
      '(first-task bug guard)',
      () async {
        SharedPreferences.setMockInitialValues({_key: 'active'});
        final c = _controller(existingData: true, streak: 9);
        await _settle();
        expect(c.state.status, TourStatus.active);
      },
    );

    test('probe failure still onboards the new user', () async {
      final c = GettingStartedController(
        EducationPrefs(),
        uid: _uid,
        hasExistingDataProbe: () async => throw Exception('probe broke'),
        streakReader: () => 0,
        awaitReady: _ready,
      );
      await _settle();
      expect(c.state.status, TourStatus.active);
    });
  });

  group('account boundary (2026-09-23)', () {
    test("another account's 'done' is not inherited", () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1:someone-else': 'done',
      });
      final c = _controller();
      await _settle();
      expect(c.state.status, TourStatus.active);
      expect(await _stored(), 'active');
      expect(await _stored('someone-else'), 'done', reason: 'untouched');
    });

    test('signed out → hidden, nothing probed, nothing persisted', () async {
      var probed = false;
      final c = GettingStartedController(
        EducationPrefs(),
        uid: null,
        hasExistingDataProbe: () async {
          probed = true;
          return false;
        },
        streakReader: () => 0,
        awaitReady: _ready,
      );
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      expect(probed, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('legacy device-level verdict migrates to the signed-in account once',
        () async {
      SharedPreferences.setMockInitialValues({
        'education_onboarding_state_v1': 'done',
      });
      final c = _controller();
      await _settle();
      expect(c.state.status, TourStatus.hidden);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), 'done');
      expect(prefs.getString('education_onboarding_state_v1'), isNull);
      // The next account on this device does not see it.
      final other = _controller(uid: 'u2');
      await _settle();
      expect(other.state.status, TourStatus.active);
    });

    test(
      'the verdict waits for readiness: probe runs on the post-wipe rows, '
      'not the outgoing account\'s',
      () async {
        // Simulates an in-session account switch: the provider is rebuilt
        // while User A's rows are still in Isar; the wipe empties them later.
        final wipeDone = Completer<void>();
        var rowsPresent = true;
        final c = GettingStartedController(
          EducationPrefs(),
          uid: 'user-b',
          hasExistingDataProbe: () async => rowsPresent,
          streakReader: () => 0,
          awaitReady: (_) => wipeDone.future,
        );
        await _settle();
        expect(c.state.status, TourStatus.loading, reason: 'undecided');
        expect(await _stored('user-b'), isNull);

        rowsPresent = false; // the wipe landed
        wipeDone.complete();
        await _settle();
        expect(c.state.status, TourStatus.active);
        expect(await _stored('user-b'), 'active');
      },
    );

    test('a readiness failure never stalls the decision', () async {
      final c = _controller(
        awaitReady: (_) async => throw StateError('gate missing'),
      );
      await _settle();
      expect(c.state.status, TourStatus.active);
    });

    test('signals buffered while waiting for readiness still resume the step',
        () async {
      SharedPreferences.setMockInitialValues({_key: 'active'});
      final ready = Completer<void>();
      final c = _controller(awaitReady: (_) => ready.future);
      c.onTaskRows(anyTask: true, anyCompleted: false);
      ready.complete();
      await _settle();
      expect(c.state.step, TourStep.completeTask);
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
      expect(await _stored(), 'done');
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
      SharedPreferences.setMockInitialValues({_key: 'active'});
      final c = _controller();
      // Signal arrives before init resolves (buffered).
      c.onTaskRows(anyTask: true, anyCompleted: false);
      await _settle();
      expect(c.state.status, TourStatus.active);
      expect(c.state.step, TourStep.completeTask);
    });

    test('resume: task already completed → straight to celebration → done',
        () async {
      SharedPreferences.setMockInitialValues({_key: 'active'});
      final c = _controller(celebrateFor: const Duration(milliseconds: 5));
      c.onTaskRows(anyTask: true, anyCompleted: true);
      await _settle();
      expect(await _stored(), 'done');
    });
  });

  test('skip persists done immediately', () async {
    final c = _controller();
    await _settle();
    expect(c.state.status, TourStatus.active);

    await c.skip();
    expect(c.state.status, TourStatus.hidden);
    expect(await _stored(), 'done');
  });
}
