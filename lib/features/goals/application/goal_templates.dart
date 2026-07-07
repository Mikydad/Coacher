import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_template.dart';

/// Popular goal presets — each maps to existing editor fields only.
const List<GoalTemplate> goalTemplates = [
  GoalTemplate(
    id: 'study',
    label: 'Study',
    emoji: '📚',
    suggestedTitle: 'Study daily',
    categoryId: GoalCategories.study,
    horizon: GoalHorizon.monthly,
    measurement: MeasurementKind.sessions,
    targetValue: 20,
    intensity: 3,
    reminderEnabled: true,
    reminderMinutesFromMidnight: 20 * 60,
    setupSteps: [
      'Block study time on calendar',
      'Gather materials',
      'Review last session notes',
    ],
  ),
  GoalTemplate(
    id: 'fitness',
    label: 'Fitness',
    emoji: '🏃',
    suggestedTitle: 'Stay active',
    categoryId: GoalCategories.fitness,
    horizon: GoalHorizon.weekly,
    measurement: MeasurementKind.sessions,
    targetValue: 4,
    intensity: 4,
    reminderEnabled: true,
    reminderMinutesFromMidnight: 7 * 60,
    setupSteps: ['Pick workout days', 'Prepare gear', 'Set a warm-up routine'],
  ),
  GoalTemplate(
    id: 'learn_skill',
    label: 'Learn Skill',
    emoji: '🧠',
    suggestedTitle: 'Learn a new skill',
    categoryId: GoalCategories.study,
    horizon: GoalHorizon.monthly,
    measurement: MeasurementKind.sessions,
    targetValue: 24,
    intensity: 3,
    setupSteps: [
      'Choose a course or resource',
      'Install required tools',
      'Schedule first practice block',
    ],
  ),
  GoalTemplate(
    id: 'read_books',
    label: 'Read Books',
    emoji: '📖',
    suggestedTitle: 'Read more books',
    categoryId: GoalCategories.habits,
    horizon: GoalHorizon.monthly,
    measurement: MeasurementKind.custom,
    targetValue: 20,
    intensity: 2,
    customLabel: 'chapters',
    setupSteps: [
      'Pick your next book',
      'Keep it visible',
      'Set a daily reading window',
    ],
  ),
  GoalTemplate(
    id: 'focus',
    label: 'Deep Work',
    emoji: '🎯',
    suggestedTitle: 'Deep work sessions',
    categoryId: GoalCategories.focus,
    horizon: GoalHorizon.weekly,
    measurement: MeasurementKind.minutes,
    targetValue: 300,
    intensity: 4,
    reminderEnabled: true,
    reminderMinutesFromMidnight: 9 * 60,
    setupSteps: [
      'Research deep work protocols',
      'Silence notifications',
      'Define your focus block',
    ],
  ),
  GoalTemplate(id: 'custom', label: 'Custom Goal', emoji: '✨'),
];

GoalTemplate? goalTemplateById(String id) {
  for (final t in goalTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
