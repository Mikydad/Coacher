import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/goals_providers.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/user_goal.dart';
import 'goal_detail_screen.dart';
import 'goal_editor_screen.dart';
import 'goals_archive_screen.dart';
import '../application/goal_period_helpers.dart' as gp;

/// Goals tab — list, category filter, new goal (`prd-goals.md`).
class GoalsHomeScreen extends ConsumerWidget {
  const GoalsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);
    final filter = ref.watch(selectedGoalCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, GoalEditorScreen.routeName),
        backgroundColor: const Color(0xFFB7FF00),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'What do you want to improve?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Goals are your bigger commitments — not the same as tasks on your calendar.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              return maxW >= 340
                  ? _CategoryBentoWide(filter: filter, ref: ref)
                  : _CategoryBentoNarrow(filter: filter, ref: ref);
            },
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, GoalsArchiveScreen.routeName),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Paused & completed'),
          ),
          const SizedBox(height: 16),
          goalsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Could not load goals: $e', style: TextStyle(color: Colors.red.shade200)),
            data: (goals) {
              if (goals.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No goals here yet. Tap “New goal” to define something you’re working toward over time.',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return Column(
                children: [
                  for (final g in goals) _GoalRow(goal: g),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

const double _kCatSpacing = 10;

/// 3-column bento: `All` is wide + tall; last row `Habits` + wide `Mental Clarity` (no empty cells).
class _CategoryBentoWide extends StatelessWidget {
  const _CategoryBentoWide({
    required this.filter,
    required this.ref,
  });

  final String? filter;
  final WidgetRef ref;

  void _tapAll() => ref.read(selectedGoalCategoryFilterProvider.notifier).state = null;

  void _tap(String id) {
    ref.read(selectedGoalCategoryFilterProvider.notifier).state = filter == id ? null : id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _CategoryMiniTile(
                  label: 'All',
                  selected: filter == null,
                  height: 88,
                  featured: true,
                  onTap: _tapAll,
                ),
              ),
              SizedBox(width: _kCatSpacing),
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.study),
                  selected: filter == GoalCategories.study,
                  height: 88,
                  onTap: () => _tap(GoalCategories.study),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _kCatSpacing),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.fitness),
                  selected: filter == GoalCategories.fitness,
                  height: 68,
                  compactType: true,
                  onTap: () => _tap(GoalCategories.fitness),
                ),
              ),
              SizedBox(width: _kCatSpacing),
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.productivity),
                  selected: filter == GoalCategories.productivity,
                  height: 68,
                  compactType: true,
                  onTap: () => _tap(GoalCategories.productivity),
                ),
              ),
              SizedBox(width: _kCatSpacing),
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.focus),
                  selected: filter == GoalCategories.focus,
                  height: 68,
                  compactType: true,
                  onTap: () => _tap(GoalCategories.focus),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _kCatSpacing),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.habits),
                  selected: filter == GoalCategories.habits,
                  height: 72,
                  onTap: () => _tap(GoalCategories.habits),
                ),
              ),
              SizedBox(width: _kCatSpacing),
              Expanded(
                flex: 2,
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.mentalClarity),
                  selected: filter == GoalCategories.mentalClarity,
                  height: 72,
                  onTap: () => _tap(GoalCategories.mentalClarity),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2-column layout for narrow widths; last row one full-width tile.
class _CategoryBentoNarrow extends StatelessWidget {
  const _CategoryBentoNarrow({
    required this.filter,
    required this.ref,
  });

  final String? filter;
  final WidgetRef ref;

  void _tapAll() => ref.read(selectedGoalCategoryFilterProvider.notifier).state = null;

  void _tap(String id) {
    ref.read(selectedGoalCategoryFilterProvider.notifier).state = filter == id ? null : id;
  }

  @override
  Widget build(BuildContext context) {
    Widget pair(String idA, String idB) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _CategoryMiniTile(
                label: GoalCategories.label(idA),
                selected: filter == idA,
                height: 70,
                onTap: () => _tap(idA),
              ),
            ),
            SizedBox(width: _kCatSpacing),
            Expanded(
              child: _CategoryMiniTile(
                label: GoalCategories.label(idB),
                selected: filter == idB,
                height: 70,
                onTap: () => _tap(idB),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CategoryMiniTile(
                  label: 'All',
                  selected: filter == null,
                  height: 78,
                  featured: true,
                  onTap: _tapAll,
                ),
              ),
              SizedBox(width: _kCatSpacing),
              Expanded(
                child: _CategoryMiniTile(
                  label: GoalCategories.label(GoalCategories.study),
                  selected: filter == GoalCategories.study,
                  height: 78,
                  onTap: () => _tap(GoalCategories.study),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _kCatSpacing),
        pair(GoalCategories.fitness, GoalCategories.productivity),
        SizedBox(height: _kCatSpacing),
        pair(GoalCategories.focus, GoalCategories.habits),
        SizedBox(height: _kCatSpacing),
        SizedBox(
          width: double.infinity,
          child: _CategoryMiniTile(
            label: GoalCategories.label(GoalCategories.mentalClarity),
            selected: filter == GoalCategories.mentalClarity,
            height: 74,
            onTap: () => _tap(GoalCategories.mentalClarity),
          ),
        ),
      ],
    );
  }
}

/// Lime / dark tiles; [featured] and [compactType] tune size and radius for hierarchy.
class _CategoryMiniTile extends StatelessWidget {
  const _CategoryMiniTile({
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
    this.featured = false,
    this.compactType = false,
  });

  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final bool featured;
  final bool compactType;

  @override
  Widget build(BuildContext context) {
    final radius = featured ? 24.0 : (compactType ? 16.0 : 20.0);
    final fontSize = featured
        ? 17.0
        : compactType
            ? 13.0
            : (label.length > 10 ? 13.0 : 14.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFB7FF00) : const Color(0xFF1A1C1F),
            borderRadius: BorderRadius.circular(radius),
            border: featured && !selected
                ? Border.all(color: const Color(0xFF2A2D32))
                : null,
            boxShadow: featured && !selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: featured ? 2 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontSize: fontSize,
              fontWeight: featured ? FontWeight.w900 : FontWeight.w800,
              height: 1.05,
              letterSpacing: featured ? -0.3 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final UserGoal goal;

  @override
  Widget build(BuildContext context) {
    final horizon = goal.horizon.name;
    return Card(
      color: const Color(0xFF1A1C1F),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${GoalCategories.label(goal.categoryId)} · $horizon · ${gp.GoalPeriodHelpers.formatPeriodSummary(goal)}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${goal.intensity}', style: const TextStyle(color: Color(0xFFB7FF00), fontWeight: FontWeight.bold)),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          GoalDetailScreen.routeName,
          arguments: goal.id,
        ),
      ),
    );
  }
}
