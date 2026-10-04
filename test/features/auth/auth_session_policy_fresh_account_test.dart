import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/features/auth/application/auth_session_policy.dart';

/// Fresh-account detection for the first-launch gate (2026-09-22): the
/// sign-in marker is the primary signal, the metadata rule the fallback.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('looksFreshlyCreated', () {
    final t = DateTime.utc(2026, 9, 22, 10, 0, 0);

    test('creation and last sign-in at the same instant → fresh', () {
      expect(
        AuthSessionPolicy.looksFreshlyCreated(
          creationTime: t,
          lastSignInTime: t,
        ),
        isTrue,
      );
    });

    test('within the 2 s tolerance → fresh', () {
      expect(
        AuthSessionPolicy.looksFreshlyCreated(
          creationTime: t,
          lastSignInTime: t.add(const Duration(milliseconds: 1500)),
        ),
        isTrue,
      );
    });

    test('a later sign-in (another device, a returning user) → not fresh', () {
      expect(
        AuthSessionPolicy.looksFreshlyCreated(
          creationTime: t,
          lastSignInTime: t.add(const Duration(minutes: 5)),
        ),
        isFalse,
      );
    });

    test('missing stamps → not fresh (never skip a seed on a guess)', () {
      expect(
        AuthSessionPolicy.looksFreshlyCreated(
          creationTime: null,
          lastSignInTime: t,
        ),
        isFalse,
      );
      expect(
        AuthSessionPolicy.looksFreshlyCreated(
          creationTime: t,
          lastSignInTime: null,
        ),
        isFalse,
      );
    });
  });

  group('account-created marker', () {
    test('consume returns true once for the marked uid, then clears', () async {
      await AuthSessionPolicy.markAccountCreated('u1');
      expect(await AuthSessionPolicy.consumeAccountCreated('u1'), isTrue);
      expect(await AuthSessionPolicy.consumeAccountCreated('u1'), isFalse);
    });

    test('a marker for another uid is dropped and reports false', () async {
      await AuthSessionPolicy.markAccountCreated('u1');
      expect(await AuthSessionPolicy.consumeAccountCreated('u2'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kAccountCreatedUidPrefsKey), isNull);
    });

    test('no marker → false', () async {
      expect(await AuthSessionPolicy.consumeAccountCreated('u1'), isFalse);
    });
  });
}
