import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/application/daily_analytics_providers.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../application/goal_intensity_mode.dart';
import '../application/goal_period_helpers.dart';
import '../application/goals_providers.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';
import 'goal_editor_screen.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  static const routeName = '/goals/detail';

  String _targetLine(UserGoal g) {
    final unit =
        g.measurementKind == MeasurementKind.custom &&
            (g.customLabel?.isNotEmpty ?? false)
        ? g.customLabel!
        : g.measurementKind.displayLabel().toLowerCase();
    final suffix = switch (g.horizon) {
      GoalHorizon.weekly => 'this week',
      GoalHorizon.monthly => 'per day (in this month)',
      GoalHorizon.daily => 'per day',
    };
    return '${g.targetValue == g.targetValue.roundToDouble() ? g.targetValue.toInt() : g.targetValue} $unit ($suffix)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goalId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: const Center(child: Text('Missing goal')),
      );
    }

    final async = ref.watch(goalDetailProvider(goalId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (bundle) {
        if (bundle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Goal')),
            body: const Center(child: Text('Goal not found')),
          );
        }
        final g = bundle.goal;
        final todayKey = DateKeys.todayKey();
        final inPeriod = GoalPeriodHelpers.isDateKeyInPeriod(g, todayKey);
        final elapsed = GoalPeriodHelpers.daysElapsedInPeriodThrough(
          g,
          DateTime.now(),
        );
        final totalDays = GoalPeriodHelpers.totalCalendarDaysInPeriod(g);
        final metInPeriod = bundle.checkIns
            .where(
              (c) =>
                  c.metCommitment &&
                  GoalPeriodHelpers.isDateKeyInPeriod(g, c.dateKey),
            )
            .length;
        final doneMilestones = bundle.milestones
            .where((m) => m.completed)
            .length;
        final totalMilestones = bundle.milestones.length;
        GoalCheckIn? todayCheckIn;
        for (final c in bundle.checkIns) {
          if (c.dateKey == todayKey) {
            todayCheckIn = c;
            break;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(g.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _onMenu(context, ref, g, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (g.status == GoalStatus.active) ...[
                    const PopupMenuItem(value: 'pause', child: Text('Pause')),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark complete'),
                    ),
                  ],
                  if (g.status != GoalStatus.active)
                    const PopupMenuItem(value: 'reopen', child: Text('Reopen')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(GoalCategories.label(g.categoryId))),
                  Chip(label: Text(g.horizon.name)),
                  Chip(label: Text('Intensity ${g.intensity}/5')),
                  Chip(
                    label: Text(
                      'Mode: ${GoalIntensityMode.displayLabelForIntensity(g.intensity)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      g.status == GoalStatus.active
                          ? 'Active'
                          : g.status == GoalStatus.paused
                          ? 'Paused'
                          : 'Completed',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                GoalPeriodHelpers.formatPeriodSummary(g),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _targetLine(g),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              if (g.status == GoalStatus.active && inPeriod) ...[
                Text(
                  todayCheckIn?.metCommitment == true
                      ? 'You marked today done.'
                      : 'Did you meet your commitment today?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _toggleToday(
                    context,
                    ref,
                    g,
                    todayCheckIn?.metCommitment == true,
                  ),
                  child: Text(
                    todayCheckIn?.metCommitment == true
                        ? 'Undo today'
                        : 'I did it today',
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                elapsed > 0
                    ? '$metInPeriod days marked done in this period ($elapsed day${elapsed == 1 ? '' : 's'} elapsed of $totalDays).'
                    : 'Period not started yet.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              if (totalMilestones > 0) ...[
                Text(
                  'Milestones: $doneMilestones of $totalMilestones done',
                  style: const TextStyle(color: Colors.white70),
                ),
                LinearProgressIndicator(
                  value: totalMilestones == 0
                      ? 0
                      : doneMilestones / totalMilestones,
                  minHeight: 6,
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final a in bundle.actions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.play_circle_outline, size: 20),
                  title: Text(a.title),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Milestones',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addMilestoneDialog(context, ref, g.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (bundle.milestones.isEmpty)
                const Text(
                  'No milestones yet.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...bundle.milestones.map(
                  (m) => _MilestoneTile(goalId: g.id, milestone: m),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleToday(
    BuildContext context,
    WidgetRef ref,
    UserGoal g,
    bool currentlyMet,
  ) async {
    final repo = ref.read(goalsRepositoryProvider);
    final todayKey = DateKeys.todayKey();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await repo.upsertCheckIn(
        GoalCheckIn(
          goalId: g.id,
          dateKey: todayKey,
          metCommitment: !currentlyMet,
          updatedAtMs: now,
        ),
      );
      fireAndForgetAnalyticsEvent(
        ref,
        type: !currentlyMet
            ? AnalyticsEventType.habitCompleted
            : AnalyticsEventType.habitSkipped,
        entityId: g.id,
        entityKind: 'habit',
        sourceSurface: 'goal_detail',
        idempotencyKey:
            '${!currentlyMet ? 'habit_completed' : 'habit_skipped'}_${g.id}_$todayKey',
      );
      invalidateGoals(ref, goalId: g.id);
      ref.invalidate(dailyGoalHabitAnalyticsProvider(todayKey));
      ref.invalidate(analyticsPeriodBundleProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    UserGoal g,
    String value,
  ) async {
    final repo = ref.read(goalsRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (value) {
      case 'edit':
        if (!context.mounted) return;
        await Navigator.pushNamed(
          context,
          GoalEditorScreen.routeName,
          arguments: GoalEditorArgs(goalId: g.id),
        );
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'pause':
        final paused = g.copyWith(status: GoalStatus.paused, updatedAtMs: now);
        await repo.upsertGoal(paused);
        await ref.read(goalReminderSyncServiceProvider).applyForGoal(paused);
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'complete':
        final done = g.copyWith(status: GoalStatus.completed, updatedAtMs: now);
        await repo.upsertGoal(done);
        await ref.read(goalReminderSyncServiceProvider).applyForGoal(done);
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'reopen':
        final active = g.copyWith(status: GoalStatus.active, updatedAtMs: now);
        await repo.upsertGoal(active);
        await ref.read(goalReminderSyncServiceProvider).applyForGoal(active);
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete goal?'),
            content: Text(
              'Remove “${g.title}” and all its actions, milestones, and check-ins?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          await ref.read(goalReminderSyncServiceProvider).cancelForGoal(g.id);
          await repo.deleteGoal(g.id);
          invalidateGoals(ref, goalId: g.id);
          if (context.mounted) Navigator.pop(context);
        }
        return;
    }
  }

  Future<void> _addMilestoneDialog(
    BuildContext context,
    WidgetRef ref,
    String gid,
  ) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New milestone'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Finish lesson 1'),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final title = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !context.mounted) return;
    if (title.isEmpty) return;
    final repo = ref.read(goalsRepositoryProvider);
    final existing = await repo.getMilestones(gid);
    final nextIndex = existing.isEmpty
        ? 0
        : existing.map((m) => m.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    await repo.upsertMilestone(
      GoalMilestone(
        id: StableId.generate('gm'),
        goalId: gid,
        title: title,
        completed: false,
        orderIndex: nextIndex,
      ),
    );
    invalidateGoals(ref, goalId: gid);
  }
}

class _MilestoneTile extends ConsumerWidget {
  const _MilestoneTile({required this.goalId, required this.milestone});

  final String goalId;
  final GoalMilestone milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1A1C1F),
      margin: const EdgeInsets.only(bottom: 6),
      child: CheckboxListTile(
        value: milestone.completed,
        onChanged: (v) async {
          if (v == null) return;
          final repo = ref.read(goalsRepositoryProvider);
          await repo.upsertMilestone(milestone.copyWith(completed: v));
          invalidateGoals(ref, goalId: goalId);
        },
        title: Text(
          milestone.title,
          style: TextStyle(
            decoration: milestone.completed ? TextDecoration.lineThrough : null,
            color: milestone.completed ? Colors.white38 : null,
          ),
        ),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white38),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove milestone?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await ref
                  .read(goalsRepositoryProvider)
                  .deleteMilestone(goalId: goalId, milestoneId: milestone.id);
              invalidateGoals(ref, goalId: goalId);
            }
          },
        ),
      ),
    );
  }
}
