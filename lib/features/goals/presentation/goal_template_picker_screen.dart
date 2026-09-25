import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/goal_templates.dart';
import '../application/goals_providers.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_template.dart';
import 'goal_editor_screen.dart';
import 'widgets/goal_category_pill_row.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/presentation/bento_category_card.dart';
import '../../onboarding/application/onboarding_goal_bridge.dart';
import '../../onboarding/domain/models/onboarding_profile.dart';

/// First-goal mode (onboarding handoff, 2026-09-25): the picker opens once
/// after onboarding with the user's chosen interests as a filter row —
/// "What do you want to start with?" — instead of the everyday mosaic.
/// The user still names and saves the goal in the normal editor; interests
/// never become goals on their own.
class FirstGoalPick {
  const FirstGoalPick({required this.interests});

  /// Onboarding interest keys, in the order they were picked; the first is
  /// the default filter.
  final List<String> interests;
}

/// Entry point for creating a goal — pick a popular template (bento mosaic)
/// or start from a blank Custom Goal.
class GoalTemplatePickerScreen extends ConsumerStatefulWidget {
  const GoalTemplatePickerScreen({
    super.key,
    this.initialCategoryId,
    this.firstGoal,
  });

  static const routeName = '/goals/templates';

  /// The Goals tab's active category filter, carried in so a goal started
  /// from a filtered list lands in that category (2026-09-24).
  final String? initialCategoryId;

  /// Non-null renders the onboarding first-goal variant. Pops with `true`
  /// when a goal was saved, `null` when the user backed out.
  final FirstGoalPick? firstGoal;

  @override
  ConsumerState<GoalTemplatePickerScreen> createState() =>
      _GoalTemplatePickerScreenState();
}

class _GoalTemplatePickerScreenState
    extends ConsumerState<GoalTemplatePickerScreen> {
  /// The highlighted template: tinted + check chip (and the others softly
  /// dimmed) so the mosaic reads as a choice, and still marks the pick when
  /// the user backs out of the editor to re-choose. Starts on Study — a
  /// preselected card is what signals "these are selectable" at first glance.
  String? _selectedId = 'study';

  /// First-goal mode: the interest whose templates are listed.
  late String _interest = widget.firstGoal?.interests.firstOrNull ?? '';

  /// Pushes (not replaces) the editor so back returns here to re-pick a
  /// template. After a successful save the editor pops with `true` and this
  /// picker pops itself too — the user lands where they started, not on a
  /// stale picker.
  Future<void> _openEditor(
    BuildContext context,
    GoalTemplate template, {
    String? categoryId,
  }) async {
    setState(() => _selectedId = template.id);
    final saved = await Navigator.pushNamed(
      context,
      GoalEditorScreen.routeName,
      arguments: GoalEditorArgs(
        template: template,
        initialCategoryId: categoryId ?? widget.initialCategoryId,
      ),
    );
    if (saved == true && context.mounted) {
      Navigator.pop(context, saved);
    }
  }

  /// Categories the bento cards already stand for; the pill row skips them.
  static const Set<String> _onMosaic = {'study', 'fitness', 'focus'};

  static GoalTemplate _customWith(GoalTemplate custom, String categoryId) =>
      GoalTemplate(
        id: custom.id,
        label: custom.label,
        emoji: custom.emoji,
        categoryId: categoryId,
      );

  static IconData _iconFor(String id) => switch (id) {
    'study' => CupertinoIcons.book_fill,
    'fitness' => CupertinoIcons.flame_fill,
    'learn_skill' => CupertinoIcons.lightbulb_fill,
    'read_books' => CupertinoIcons.bookmark_fill,
    'focus' => CupertinoIcons.scope,
    'first_version' => CupertinoIcons.rocket_fill,
    'first_customers' => CupertinoIcons.person_2_fill,
    'side_income' => CupertinoIcons.money_dollar_circle_fill,
    'money_checkin' => CupertinoIcons.chart_bar_fill,
    'brain_dump' => CupertinoIcons.square_list_fill,
    'clear_space' => CupertinoIcons.house_fill,
    'morning_start' => CupertinoIcons.sun_max_fill,
    'focused_hour' => CupertinoIcons.timer_fill,
    'custom' => CupertinoIcons.plus_circle_fill,
    _ => CupertinoIcons.sparkles,
  };

  static String? _subtitle(GoalTemplate t) {
    if (t.measurement == null) return null;
    final target = t.targetValue?.round() ?? 0;
    final unit = switch (t.measurement) {
      MeasurementKind.minutes => 'min',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.count => t.customLabel ?? 'count',
      MeasurementKind.distance => 'km',
      MeasurementKind.custom => t.customLabel ?? 'units',
      null => '',
    };
    return '$target $unit · ${GoalCategories.label(t.categoryId ?? '')}';
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final t in goalTemplates) t.id: t};
    final firstGoal = widget.firstGoal;
    if (firstGoal != null) return _buildFirstGoal(context, byId, firstGoal);

    BentoCategoryCard card(String id, BentoTone tone, {bool hero = false}) {
      final t = byId[id]!;
      return BentoCategoryCard(
        tone: tone,
        icon: _iconFor(id),
        label: t.label,
        subtitle: _subtitle(t),
        hero: hero,
        selected: _selectedId == id,
        dimmed: _selectedId != null && _selectedId != id,
        onTap: () => _openEditor(context, t),
      );
    }

    final custom = byId['custom']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.fg70),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const PageTitle('New goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Pick a goal'),
            const SizedBox(height: 16),
            // Bento mosaic: Study hero on top, then two side-by-side pairs.
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: card('study', BentoPalette.study, hero: true),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(child: card('fitness', BentoPalette.fitness)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: card('learn_skill', BentoPalette.learn),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(child: card('read_books', BentoPalette.read)),
                        const SizedBox(width: 12),
                        Expanded(child: card('focus', BentoPalette.focus)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Categories not already on the mosaic, then the user's own
            // (2026-09-24). "+ New" names a category first — the old
            // "Custom Goal" silently filed the goal under Study, making it
            // unfindable behind the category filter. A pill opens the
            // editor with that category set; the editor's own row can
            // still change it.
            Text(
              'OR PICK A CATEGORY',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            GoalCategoryPillRow(
              categories: [
                for (final id in ref.watch(goalCategoryOptionsProvider))
                  if (!_onMosaic.contains(id)) id,
              ],
              selectedId: widget.initialCategoryId,
              onSelected: (id) =>
                  _openEditor(context, _customWith(custom, id), categoryId: id),
              onCreated: (name) => _openEditor(
                context,
                _customWith(custom, name),
                categoryId: name,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── First-goal mode ────────────────────────────────────────────────────────

  /// Cycles the mosaic's five tones over the interest's templates.
  static BentoTone _toneAt(int i) => switch (i % 5) {
    0 => BentoPalette.study,
    1 => BentoPalette.fitness,
    2 => BentoPalette.learn,
    3 => BentoPalette.read,
    _ => BentoPalette.focus,
  };

  Widget _buildFirstGoal(
    BuildContext context,
    Map<String, GoalTemplate> byId,
    FirstGoalPick firstGoal,
  ) {
    final categoryId = OnboardingGoalBridge.categoryFor(_interest);
    final templates = [
      for (final id in OnboardingGoalBridge.templateIdsFor(_interest))
        ?byId[id],
    ];
    final custom = byId['custom']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.fg70),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const PageTitle('Your first goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('What do you want to start with?'),
            const SizedBox(height: 6),
            Text(
              'Pick a goal to begin with. You can change everything later.',
              style: TextStyle(fontSize: 13, color: AppColors.textSoft),
            ),
            if (firstGoal.interests.length > 1) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final key in firstGoal.interests) ...[
                      _InterestChip(
                        label: OnboardingInterests.label(key),
                        selected: key == _interest,
                        onTap: () => setState(() {
                          _interest = key;
                          _selectedId = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final (i, t) in templates.indexed)
                    BentoCategoryCard(
                      tone: _toneAt(i),
                      icon: _iconFor(t.id),
                      label: t.label,
                      subtitle: _subtitle(t),
                      selected: _selectedId == t.id,
                      dimmed: _selectedId != null && _selectedId != t.id,
                      onTap: () =>
                          _openEditor(context, t, categoryId: categoryId),
                    ),
                  BentoCategoryCard(
                    tone: _toneAt(templates.length),
                    icon: _iconFor('custom'),
                    label: 'Create my own goal',
                    subtitle: GoalCategories.label(categoryId),
                    selected: _selectedId == 'custom',
                    dimmed: _selectedId != null && _selectedId != 'custom',
                    onTap: () => _openEditor(
                      context,
                      _customWith(custom, categoryId),
                      categoryId: categoryId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.fg12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onAccent : AppColors.fg70,
          ),
        ),
      ),
    );
  }
}
