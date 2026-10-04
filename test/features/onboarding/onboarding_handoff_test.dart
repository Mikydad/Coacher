import 'package:sidepal/features/onboarding/application/onboarding_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing pending by default', () async {
    expect(await OnboardingHandoff.consume(), isNull);
  });

  test('schedule then consume returns the kind exactly once', () async {
    await OnboardingHandoff.schedule(OnboardingHandoffKind.firstGoal);
    expect(await OnboardingHandoff.consume(), OnboardingHandoffKind.firstGoal);
    expect(await OnboardingHandoff.consume(), isNull);
  });

  test('unknown stored value is cleared and ignored', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingHandoff.prefsKey: 'something_else',
    });
    expect(await OnboardingHandoff.consume(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(OnboardingHandoff.prefsKey), isFalse);
  });
}
