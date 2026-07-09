import 'package:coach_for_life/features/feedback/application/tester_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TesterModeController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to false', () async {
      final controller = TesterModeController();
      await Future<void>.delayed(Duration.zero); // let _load complete
      expect(controller.state, isFalse);
    });

    test('loads persisted true', () async {
      SharedPreferences.setMockInitialValues({'tester_mode_enabled_v1': true});
      final controller = TesterModeController();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isTrue);
    });

    test('toggle flips and persists', () async {
      final controller = TesterModeController();
      await Future<void>.delayed(Duration.zero);

      await controller.toggle();
      expect(controller.state, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tester_mode_enabled_v1'), isTrue);

      await controller.toggle();
      expect(controller.state, isFalse);
      expect(prefs.getBool('tester_mode_enabled_v1'), isFalse);
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
