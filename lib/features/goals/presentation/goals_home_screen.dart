import '../../education/presentation/first_time_feature_card.dart';
import '../../education/presentation/help_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/goals_providers.dart';
import '../domain/models/user_goal.dart';
import 'goal_template_picker_screen.dart';
import 'goals_archive_screen.dart';
import 'widgets/category_chip_row.dart';
import 'widgets/goal_card.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';

/// Goals tab — list with fill-bar cards, horizontal category chips,
/// and a counter bottom sheet on tap.
class GoalsHomeScreen extends ConsumerWidget {
  const GoalsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('Goals'),
        centerTitle: true,
        actions: [
          const HelpAppBarButton('goals'),
          IconButton(
            tooltip: 'Paused & completed',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, GoalsArchiveScreen.routeName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_tab_fab',
        onPressed: () =>
            Navigator.pushNamed(context, GoalTemplatePickerScreen.routeName),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FirstTimeFeatureCard(guideId: 'goals'),
          ),
          // ── Category filter ─────────────────────────────────────────
          const SizedBox(height: 12),
          const CategoryChipRow(),
          const SizedBox(height: 16),

          // ── Goal list ────────────────────────────────────────────────
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load goals: $e',
                  style: TextStyle(color: Colors.red.shade200),
                ),
              ),
              data: (goals) => _GoalList(goals: goals),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.goals});

  final List<UserGoal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text(
          'No goals here yet.\nTap "New goal" to define something you\'re working toward over time.',
          style: TextStyle(color: AppColors.fg54, height: 1.6),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: goals.length,
      itemBuilder: (_, i) => GoalCard(goal: goals[i]),
    );
  }
}
