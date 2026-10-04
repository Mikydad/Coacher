import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/app/first_launch_gate.dart';
import 'package:sidepal/core/bootstrap/first_screen_ready.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/auth/application/auth_session_policy.dart';

/// The gate is the one owner of the first-launch seed (2026-09-22): it
/// reveals on the first of seeded / fresh account / critical phases / cap,
/// and writes the seeded flag only for a pull that succeeded.
void main() {
  const uid = 'u1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirstScreenReady.resetForTests();
    SyncService.debugUidForTests = uid;
    FirstLaunchGate.debugSeedForTests = null;
  });

  tearDown(() {
    FirstLaunchGate.debugSeedForTests = null;
    SyncService.debugUidForTests = null;
    FirstScreenReady.resetForTests();
    FirstLaunchGate.resetSeedSignals();
  });

  Widget gate() => const FirstLaunchGate(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Text('HOME'),
    ),
  );

  Future<bool?> seededFlag() async =>
      (await SharedPreferences.getInstance()).getBool(kIsarSeededV1PrefsKey);

  testWidgets('already seeded: reveals at once without a pull', (tester) async {
    SharedPreferences.setMockInitialValues({kIsarSeededV1PrefsKey: true});
    var seeds = 0;
    FirstLaunchGate.debugSeedForTests = (_) async {
      seeds++;
      return true;
    };

    await tester.pumpWidget(gate());
    await tester.pump();

    expect(find.text('HOME'), findsOneWidget);
    expect(seeds, 0);
    expect(FirstScreenReady.isReady, isTrue);
  });

  testWidgets(
    'account created on this device: reveals at once, flag set, marker consumed',
    (tester) async {
      SharedPreferences.setMockInitialValues({kAccountCreatedUidPrefsKey: uid});
      var seeds = 0;
      FirstLaunchGate.debugSeedForTests = (_) async {
        seeds++;
        return true;
      };

      await tester.pumpWidget(gate());
      await tester.pump();

      expect(find.text('HOME'), findsOneWidget);
      expect(seeds, 0);
      expect(await seededFlag(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kAccountCreatedUidPrefsKey), isNull);
    },
  );

  testWidgets('a marker for another uid is dropped and the seed still runs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      kAccountCreatedUidPrefsKey: 'someone-else',
    });
    var seeds = 0;
    FirstLaunchGate.debugSeedForTests = (first) async {
      seeds++;
      first.complete();
      return true;
    };

    await tester.pumpWidget(gate());
    await tester.pump();
    await tester.pump();

    expect(seeds, 1);
    expect(find.text('HOME'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAccountCreatedUidPrefsKey), isNull);
  });

  testWidgets(
    'reveals when the critical phases land; the flag waits for the pull',
    (tester) async {
      final pullDone = Completer<bool>();
      FirstLaunchGate.debugSeedForTests = (first) {
        first.complete();
        return pullDone.future;
      };

      await tester.pumpWidget(gate());
      await tester.pump();
      await tester.pump();

      expect(find.text('HOME'), findsOneWidget);
      expect(FirstScreenReady.isReady, isTrue);
      expect(await seededFlag(), isNull);

      pullDone.complete(true);
      await tester.pump();
      expect(await seededFlag(), isTrue);
    },
  );

  testWidgets(
    'reveals at the cap when nothing lands; a failed pull leaves the flag unset',
    (tester) async {
      final pullDone = Completer<bool>();
      FirstLaunchGate.debugSeedForTests = (_) => pullDone.future;

      await tester.pumpWidget(gate());
      await tester.pump();
      await tester.pump(kFirstLaunchRevealCap - const Duration(seconds: 1));
      expect(find.text('HOME'), findsNothing);
      expect(find.textContaining('Loading your plan'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('HOME'), findsOneWidget);
      expect(FirstScreenReady.isReady, isTrue);

      pullDone.complete(false);
      await tester.pump();
      expect(await seededFlag(), isNull);
    },
  );

  group('seedSettledFor (2026-09-23)', () {
    testWidgets('settles after the pull ends, even when revealed by the cap', (
      tester,
    ) async {
      final pull = Completer<bool>();
      FirstLaunchGate.debugSeedForTests = (_) => pull.future;
      var settled = false;
      unawaited(FirstLaunchGate.seedSettledFor(uid).then((_) => settled = true));

      await tester.pumpWidget(gate());
      await tester.pump(kFirstLaunchRevealCap + const Duration(seconds: 1));
      expect(find.text('HOME'), findsOneWidget, reason: 'cap revealed');
      expect(settled, isFalse, reason: 'rows may still be landing');

      pull.complete(false);
      await tester.pump();
      expect(settled, isTrue);
    });

    testWidgets('a pending signal asked for before the mount is honoured', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({kIsarSeededV1PrefsKey: true});
      var settled = false;
      unawaited(FirstLaunchGate.seedSettledFor(uid).then((_) => settled = true));
      await tester.pumpWidget(gate());
      await tester.pump();
      expect(settled, isTrue);
    });

    testWidgets('asking again after it settled does not reopen it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({kIsarSeededV1PrefsKey: true});
      await tester.pumpWidget(gate());
      await tester.pump();
      var first = false;
      var second = false;
      unawaited(FirstLaunchGate.seedSettledFor(uid).then((_) => first = true));
      unawaited(FirstLaunchGate.seedSettledFor(uid).then((_) => second = true));
      await tester.pump();
      expect(first, isTrue);
      expect(second, isTrue);
    });

    testWidgets('a settled signal is replaced by the next mount for that uid', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({kIsarSeededV1PrefsKey: true});
      await tester.pumpWidget(gate());
      await tester.pump();
      var settledOnce = false;
      unawaited(
        FirstLaunchGate.seedSettledFor(uid).then((_) => settledOnce = true),
      );
      await tester.pump();
      expect(settledOnce, isTrue, reason: 'first mount settled');

      // Remount (account switched away and back): a new question.
      await tester.pumpWidget(const SizedBox());
      final pull = Completer<bool>();
      SharedPreferences.setMockInitialValues({});
      FirstLaunchGate.debugSeedForTests = (_) => pull.future;
      await tester.pumpWidget(gate());
      var settled = false;
      unawaited(FirstLaunchGate.seedSettledFor(uid).then((_) => settled = true));
      await tester.pump();
      expect(settled, isFalse);
      pull.complete(true);
      await tester.pump();
      expect(settled, isTrue);
    });
  });
}
