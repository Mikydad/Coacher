import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/goals_providers.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';
import '../application/goal_period_helpers.dart';
import 'goal_detail_screen.dart';

class GoalsArchiveScreen extends ConsumerWidget {
  const GoalsArchiveScreen({super.key});

  static const routeName = '/goals/archive';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archivedGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paused & completed')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nothing archived yet. Pause or complete a goal from its detail screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final g = goals[i];
              return _ArchiveTile(goal: g);
            },
          );
        },
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({required this.goal});

  final UserGoal goal;

  @override
  Widget build(BuildContext context) {
    final status = goal.status == GoalStatus.paused ? 'Paused' : 'Completed';
    return Card(
      color: const Color(0xFF1A1C1F),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$status · ${GoalCategories.label(goal.categoryId)} · ${GoalPeriodHelpers.formatPeriodSummary(goal)}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: () => Navigator.pushNamed(
          context,
          GoalDetailScreen.routeName,
          arguments: goal.id,
        ),
      ),
    );
  }
}
