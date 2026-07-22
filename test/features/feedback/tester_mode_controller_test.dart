import 'package:sidepal/features/auth/application/auth_providers.dart';
import 'package:sidepal/features/feedback/application/tester_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets a fresh async settle (listeners + SharedPreferences awaits).
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TesterModeController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// Container with a fixed account identity.
    ProviderContainer fixed({String? uid, required bool registered}) {
      final container = ProviderContainer(
        overrides: [
          authUidProvider.overrideWithValue(uid),
          isRegisteredProvider.overrideWithValue(registered),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('registered account with no stored flag defaults to false', () async {
      final c = fixed(uid: 'userA', registered: true);
      c.read(testerModeProvider.notifier);
      await _settle();
      expect(c.read(testerModeProvider), isFalse);
    });

    test('toggle enables and persists under a per-uid key', () async {
      final c = fixed(uid: 'userA', registered: true);
      final controller = c.read(testerModeProvider.notifier);
      await _settle();

      expect(await controller.toggle(), TesterToggleOutcome.enabled);
      expect(c.read(testerModeProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tester_mode_enabled_v2_userA'), isTrue);

      expect(await controller.toggle(), TesterToggleOutcome.disabled);
      expect(c.read(testerModeProvider), isFalse);
      expect(prefs.getBool('tester_mode_enabled_v2_userA'), isFalse);
    });

    test('a registered account loads its own persisted flag', () async {
      SharedPreferences.setMockInitialValues({
        'tester_mode_enabled_v2_userA': true,
      });
      final c = fixed(uid: 'userA', registered: true);
      c.read(testerModeProvider.notifier);
      await _settle();
      expect(c.read(testerModeProvider), isTrue);
    });

    test('tester state is isolated per account', () async {
      SharedPreferences.setMockInitialValues({
        'tester_mode_enabled_v2_userA': true,
      });
      // A different signed-in account never inherits A's flag.
      final b = fixed(uid: 'userB', registered: true);
      b.read(testerModeProvider.notifier);
      await _settle();
      expect(b.read(testerModeProvider), isFalse);
    });

    test('anonymous session cannot enable tester mode', () async {
      final c = fixed(uid: 'guest-uid', registered: false);
      final controller = c.read(testerModeProvider.notifier);
      await _settle();

      expect(await controller.toggle(), TesterToggleOutcome.accountRequired);
      expect(c.read(testerModeProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tester_mode_enabled_v2_guest-uid'), isNull);
    });

    test('guest state does not carry into a signed-in account', () async {
      // Anonymous session that upgrades to registered, preserving the uid
      // (the real anonymous→email link path). Nothing was (or could be)
      // enabled while anonymous, so the account starts clean.
      final uidCtrl = StateProvider<String?>((_) => 'shared-uid');
      final regCtrl = StateProvider<bool>((_) => false);
      final container = ProviderContainer(
        overrides: [
          authUidProvider.overrideWith((ref) => ref.watch(uidCtrl)),
          isRegisteredProvider.overrideWith((ref) => ref.watch(regCtrl)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(testerModeProvider.notifier);
      await _settle();
      // Guest cannot enable it.
      expect(await controller.toggle(), TesterToggleOutcome.accountRequired);

      // Upgrade to a registered account on the same uid.
      container.read(regCtrl.notifier).state = true;
      await _settle();

      expect(container.read(testerModeProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tester_mode_enabled_v2_shared-uid'), isNull);
    });

    test('signing out clears the effective tester state', () async {
      SharedPreferences.setMockInitialValues({
        'tester_mode_enabled_v2_userA': true,
      });
      final uidCtrl = StateProvider<String?>((_) => 'userA');
      final regCtrl = StateProvider<bool>((_) => true);
      final container = ProviderContainer(
        overrides: [
          authUidProvider.overrideWith((ref) => ref.watch(uidCtrl)),
          isRegisteredProvider.overrideWith((ref) => ref.watch(regCtrl)),
        ],
      );
      addTearDown(container.dispose);

      container.read(testerModeProvider.notifier);
      await _settle();
      expect(container.read(testerModeProvider), isTrue);

      // Sign out.
      container.read(uidCtrl.notifier).state = null;
      container.read(regCtrl.notifier).state = false;
      await _settle();
      expect(container.read(testerModeProvider), isFalse);
    });

    test('legacy device-wide key is purged on init', () async {
      SharedPreferences.setMockInitialValues({'tester_mode_enabled_v1': true});
      final c = fixed(uid: 'userA', registered: true);
      c.read(testerModeProvider.notifier);
      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tester_mode_enabled_v1'), isNull);
    });
  });

  group('SevenTapDetector', () {
    test('fires on the 7th rapid tap and resets', () {
      final detector = SevenTapDetector();
      var t = DateTime(2026, 7, 9, 12);
      final remaining = <int>[];
      for (var i = 0; i < 7; i++) {
        remaining.add(detector.registerTap(t));
        t = t.add(const Duration(milliseconds: 200));
      }
      expect(remaining, [6, 5, 4, 3, 2, 1, 0]);

      // Detector reset — next tap starts a fresh round.
      expect(detector.registerTap(t), 6);
    });

    test('a gap longer than the window resets the count', () {
      final detector = SevenTapDetector();
      var t = DateTime(2026, 7, 9, 12);
      for (var i = 0; i < 5; i++) {
        detector.registerTap(t);
        t = t.add(const Duration(milliseconds: 200));
      }
      // 3-second pause — over the 2s window.
      t = t.add(const Duration(seconds: 3));
      expect(detector.registerTap(t), 6);
    });
  });
}
