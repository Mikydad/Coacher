import 'package:sidepal/features/education/application/education_prefs.dart';
import 'package:sidepal/features/education/application/education_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('EducationPrefs', () {
    test('onboarding state round-trips per account', () async {
      final prefs = EducationPrefs();
      expect(await prefs.onboardingState('a'), isNull);
      await prefs.setOnboardingState('a', 'active');
      expect(await prefs.onboardingState('a'), 'active');
      await prefs.setOnboardingState('a', 'done');
      expect(await prefs.onboardingState('a'), 'done');
      expect(await prefs.onboardingState('b'), isNull, reason: 'scoped');
    });

    test('legacy device-level key migrates to the first account that reads it',
        () async {
      SharedPreferences.setMockInitialValues({
        kLegacyOnboardingStatePrefsKey: 'done',
      });
      final prefs = EducationPrefs();
      expect(await prefs.onboardingState('a'), 'done');
      final raw = await SharedPreferences.getInstance();
      expect(raw.getString(onboardingStatePrefsKeyFor('a')), 'done');
      expect(raw.getString(kLegacyOnboardingStatePrefsKey), isNull);
      expect(await prefs.onboardingState('b'), isNull);
    });

    test('markCardSeen accumulates and is idempotent', () async {
      final prefs = EducationPrefs();
      expect(await prefs.seenCards(), isEmpty);
      await prefs.markCardSeen('focus');
      await prefs.markCardSeen('goals');
      await prefs.markCardSeen('focus');
      expect(await prefs.seenCards(), {'focus', 'goals'});
    });
  });

  group('EducationSeenCardsController', () {
    test('loads persisted set; showFeatureCardProvider gates correctly',
        () async {
      SharedPreferences.setMockInitialValues({
        'education_seen_cards_v1': ['focus'],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // While loading (null) every card is hidden.
      expect(container.read(showFeatureCardProvider('goals')), isFalse);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(showFeatureCardProvider('goals')), isTrue);
      expect(container.read(showFeatureCardProvider('focus')), isFalse);
    });

    test('markSeen hides instantly and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(educationSeenCardsProvider.notifier);
      if (container.read(educationSeenCardsProvider) == null) {
        await notifier.stream.firstWhere((s) => s != null);
      }
      expect(container.read(showFeatureCardProvider('circles')), isTrue);

      final future = container
          .read(educationSeenCardsProvider.notifier)
          .markSeen('circles');
      // Optimistic: hidden before the disk write completes.
      expect(container.read(showFeatureCardProvider('circles')), isFalse);
      await future;
      expect(await EducationPrefs().seenCards(), contains('circles'));
    });
  });
}
