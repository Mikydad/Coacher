import '../../goals/domain/models/goal_categories.dart';
import '../domain/models/onboarding_profile.dart';

/// Where an onboarding interest lands when it becomes a real goal
/// (decision log 2026-09-25). Interests stay tags; this only chooses the
/// starting point the first-goal picker opens on. Existing categories only —
/// business and money share "productivity" rather than adding an app-wide
/// category for one screen.
abstract final class OnboardingGoalBridge {
  static String categoryFor(String interest) => switch (interest) {
    OnboardingInterests.improveHealth => GoalCategories.fitness,
    OnboardingInterests.learnSkills => GoalCategories.study,
    OnboardingInterests.betterHabits => GoalCategories.habits,
    OnboardingInterests.moreDisciplined => GoalCategories.focus,
    // buildBusiness, getOrganized, makeMoney
    _ => GoalCategories.productivity,
  };

  /// Template ids the first-goal picker shows for an interest. Filtered by
  /// interest rather than category so "Make more money" never shows the
  /// decluttering templates that share its category.
  static List<String> templateIdsFor(String interest) => switch (interest) {
    OnboardingInterests.buildBusiness => const ['first_version', 'first_customers'],
    OnboardingInterests.makeMoney => const ['side_income', 'money_checkin'],
    OnboardingInterests.getOrganized => const ['brain_dump', 'clear_space'],
    OnboardingInterests.moreDisciplined => const ['morning_start', 'focused_hour'],
    OnboardingInterests.improveHealth => const ['fitness'],
    OnboardingInterests.learnSkills => const ['learn_skill', 'study'],
    OnboardingInterests.betterHabits => const ['read_books'],
    _ => const [],
  };
}
