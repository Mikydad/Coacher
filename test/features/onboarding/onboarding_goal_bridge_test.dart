import 'package:sidepal/features/goals/application/goal_templates.dart';
import 'package:sidepal/features/goals/domain/models/goal_categories.dart';
import 'package:sidepal/features/onboarding/application/onboarding_goal_bridge.dart';
import 'package:sidepal/features/onboarding/domain/models/onboarding_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingGoalBridge', () {
    test('every interest maps to an existing category', () {
      for (final key in OnboardingInterests.all) {
        expect(
          GoalCategories.all,
          contains(OnboardingGoalBridge.categoryFor(key)),
          reason: key,
        );
      }
    });

    test('every interest has at least one real template', () {
      final ids = goalTemplates.map((t) => t.id).toSet();
      for (final key in OnboardingInterests.all) {
        final forKey = OnboardingGoalBridge.templateIdsFor(key);
        expect(forKey, isNotEmpty, reason: key);
        for (final id in forKey) {
          expect(ids, contains(id), reason: '$key → $id');
          expect(id, isNot('custom'));
        }
      }
    });

    test('template ids are unique', () {
      final ids = goalTemplates.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every interest has a display label', () {
      for (final key in OnboardingInterests.all) {
        expect(OnboardingInterests.label(key), isNot(key));
      }
    });
  });
}
