/// Category ids for filter + tag (`prd-goals.md` §4.7).
abstract final class GoalCategories {
  static const String study = 'study';
  static const String fitness = 'fitness';
  static const String productivity = 'productivity';
  static const String focus = 'focus';
  static const String habits = 'habits';
  static const String mentalClarity = 'mental_clarity';

  static const List<String> all = [
    study,
    fitness,
    productivity,
    focus,
    habits,
    mentalClarity,
  ];

  static String label(String id) {
    switch (id) {
      case study:
        return 'Study';
      case fitness:
        return 'Fitness';
      case productivity:
        return 'Productivity';
      case focus:
        return 'Focus';
      case habits:
        return 'Habits';
      case mentalClarity:
        return 'Mental Clarity';
      default:
        return id;
    }
  }
}
