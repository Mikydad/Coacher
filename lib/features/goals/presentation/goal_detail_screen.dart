import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/application/daily_analytics_providers.dart';
import '../../analytics/application/delivery_providers.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../home/presentation/pathpal_app_bar_title.dart';
import '../application/goal_intensity_mode.dart';
import '../application/goal_period_helpers.dart';
import '../application/goals_providers.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';
import '../../education/presentation/help_dot.dart';
import 'goal_editor_screen.dart';

/// Obsidian Pulse goal detail — layered dark surfaces, no dividers, lime as
/// the light source for achievement. Visual language follows the Stitch
/// "productivity dashboard" mock (two-tone hero title, metadata pills,
/// streak counter, gradient cycle progress, operational checklist).
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

  /// Consecutive days (ending today or yesterday) with a met check-in.
  int _currentStreak(List<GoalCheckIn> checkIns) {
    final met = <String>{
      for (final c in checkIns)
        if (c.metCommitment) c.dateKey,
    };
    var day = DateTime.now();
    if (!met.contains(DateKeys.yyyymmdd(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (met.contains(DateKeys.yyyymmdd(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Scaffold _messageScaffold(String message, {bool spinner = false}) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: const PathPalAppBarTitle(),
      ),
      body: Center(
        child: spinner
            ? const CircularProgressIndicator()
            : Text(message, style: TextStyle(color: AppColors.textSoft)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goalId.isEmpty) {
      return _messageScaffold('Missing goal');
    }

    final async = ref.watch(goalDetailProvider(goalId));

    return async.when(
      loading: () => _messageScaffold('', spinner: true),
      error: (e, _) => _messageScaffold('Error: $e'),
      data: (bundle) {
        if (bundle == null) {
          return _messageScaffold('Goal not found');
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
        final doneActions = bundle.actions.where((a) => a.completed).length;
        final totalActions = bundle.actions.length;
        final streak = _currentStreak(bundle.checkIns);
        GoalCheckIn? todayCheckIn;
        for (final c in bundle.checkIns) {
          if (c.dateKey == todayKey) {
            todayCheckIn = c;
            break;
          }
        }
        final todayDone = todayCheckIn?.metCommitment == true;

        return Scaffold(
          backgroundColor: AppColors.ink,
          appBar: AppBar(
            backgroundColor: AppColors.ink,
            title: const PathPalAppBarTitle(),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeroTitle(title: g.title),
              const SizedBox(height: 14),
              // Single-line metadata strip; scrolls horizontally on narrow
              // screens instead of wrapping.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MetaPill(label: GoalCategories.label(g.categoryId)),
                    const SizedBox(width: 6),
                    _MetaPill(label: g.horizon.name),
                    const SizedBox(width: 6),
                    _MetaPill(label: 'Intensity ${g.intensity}/5'),
                    const SizedBox(width: 6),
                    _MetaPill(
                      label: GoalIntensityMode.displayLabelForIntensity(
                        g.intensity,
                      ),
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 6),
                    _MetaPill(
                      label: switch (g.status) {
                        GoalStatus.active => 'Active',
                        GoalStatus.paused => 'Paused',
                        GoalStatus.completed => 'Completed',
                      },
                      color: g.status == GoalStatus.active
                          ? AppColors.accentBright
                          : AppColors.textSoft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          GoalPeriodHelpers.formatPeriodSummary(g),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _targetLine(g).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Current Streak',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        streak.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: AppColors.accentBright,
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (g.status == GoalStatus.active && inPeriod) ...[
                _TodayCommitmentCard(
                  done: todayDone,
                  onToggle: () => _toggleToday(context, ref, g, todayDone),
                ),
                const SizedBox(height: 32),
              ],
              _SectionHeader(
                title: 'Cycle Progress',
                helpId: 'cycleProgress',
                trailing: _EmphasisCount(
                  strong: '$elapsed/$totalDays',
                  soft: ' DAYS',
                ),
              ),
              const SizedBox(height: 14),
              _GradientProgressBar(
                value: totalDays == 0 ? 0 : (elapsed / totalDays),
              ),
              const SizedBox(height: 10),
              Text(
                elapsed > 0
                    ? '$metInPeriod of $elapsed elapsed day${elapsed == 1 ? '' : 's'} marked done. Maintain the pulse to level up.'
                    : 'Period not started yet.',
                style: TextStyle(color: AppColors.textSoft, fontSize: 13),
              ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Actions',
                helpId: 'goalActions',
                subtitle: 'OPERATIONAL CHECKLIST',
                trailing: totalActions > 0
                    ? _EmphasisCount(
                        strong: '$doneActions / $totalActions',
                        soft: '  completed',
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              if (totalActions == 0)
                const _EmptyStateCard(
                  icon: Icons.checklist_rounded,
                  title: 'No actions yet.',
                  subtitle: 'Edit this goal to add operational steps.',
                )
              else
                for (final a in bundle.actions)
                  _ChecklistTile(
                    title: a.title,
                    completed: a.completed,
                    metaLabel: a.completed ? 'COMPLETED' : 'TAP TO CHECK OFF',
                    onToggle: () async {
                      final repo = ref.read(goalsRepositoryProvider);
                      await repo.upsertAction(
                        a.copyWith(completed: !a.completed),
                      );
                      invalidateGoals(ref, goalId: g.id);
                    },
                  ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Milestones',
                helpId: 'milestones',
                trailing: TextButton.icon(
                  onPressed: () => _addMilestoneDialog(context, ref, g.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentBright,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'ADD',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (bundle.milestones.isEmpty)
                const _EmptyStateCard(
                  icon: Icons.flag_outlined,
                  title: 'No strategic milestones defined yet.',
                  subtitle: 'Set targets to visualize your evolution.',
                )
              else
                for (final m in bundle.milestones)
                  _ChecklistTile(
                    title: m.title,
                    completed: m.completed,
                    metaLabel: m.completed ? 'REACHED' : 'IN PURSUIT',
                    onToggle: () async {
                      final repo = ref.read(goalsRepositoryProvider);
                      await repo.upsertMilestone(
                        m.copyWith(completed: !m.completed),
                      );
                      invalidateGoals(ref, goalId: g.id);
                    },
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.textFaint,
                      ),
                      onPressed: () =>
                          _confirmDeleteMilestone(context, ref, g.id, m),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMilestone(
    BuildContext context,
    WidgetRef ref,
    String gid,
    GoalMilestone milestone,
  ) async {
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
          .deleteMilestone(goalId: gid, milestoneId: milestone.id);
      invalidateGoals(ref, goalId: gid);
    }
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
      // migrated to coordinator (triggers analyticsPeriodBundle invalidation via UnifiedRecomputeGraph)
      await ScheduleMutationCoordinator.instance.run(
        GoalChangedMutation(
          entityId: g.id,
          sourceContext: 'goal_detail_screen.habit_toggle',
          changeKind: !currentlyMet ? 'completed' : 'skipped',
        ),
        commitOverride: () async {},
      );
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
        await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(g.id);
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'complete':
        final done = g.copyWith(status: GoalStatus.completed, updatedAtMs: now);
        await repo.upsertGoal(done);
        await ref.read(goalReminderSyncServiceProvider).applyForGoal(done);
        await clearEntityCoachingCachesForGoal(ref, done.id);
        await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(g.id);
        invalidateGoals(ref, goalId: g.id);
        return;
      case 'reopen':
        final active = g.copyWith(status: GoalStatus.active, updatedAtMs: now);
        await repo.upsertGoal(active);
        await ref.read(goalReminderSyncServiceProvider).applyForGoal(active);
        await ref
            .read(goalBlockSyncServiceProvider)
            .syncBlockForGoal(active, DateTime.now());
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
          await clearEntityCoachingCachesForGoal(ref, g.id);
          await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(g.id);
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
    final title = await showDialog<String?>(
      context: context,
      builder: (ctx) => const _NewMilestoneDialog(),
    );
    if (!context.mounted) return;
    if (title == null || title.trim().isEmpty) return;
    final repo = ref.read(goalsRepositoryProvider);
    final existing = await repo.getMilestones(gid);
    final nextIndex = existing.isEmpty
        ? 0
        : existing.map((m) => m.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    await repo.upsertMilestone(
      GoalMilestone(
        id: StableId.generate('gm'),
        goalId: gid,
        title: title.trim(),
        completed: false,
        orderIndex: nextIndex,
      ),
    );
    invalidateGoals(ref, goalId: gid);
  }
}

// ── Obsidian Pulse building blocks ──────────────────────────────────────────

/// Magazine-headline title: everything white, the last word in lime.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final words = title.trim().split(RegExp(r'\s+'));
    final lead = words.length > 1
        ? words.sublist(0, words.length - 1).join(' ')
        : null;
    final tail = words.isEmpty ? '' : words.last;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: AppColors.fg,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.08,
          letterSpacing: -1,
        ),
        children: [
          if (lead != null) TextSpan(text: '$lead '),
          TextSpan(
            text: tail,
            style: TextStyle(color: AppColors.accentBright),
          ),
        ],
      ),
    );
  }
}

/// All-caps metadata tag — compact rectangle so the whole strip fits one
/// line. Neutral by default; pass [color] for accent tags (cyan mode, lime
/// active-status).
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: 0.14) ?? AppColors.inkElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: accent ?? AppColors.textSoft,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.helpId,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Feature-guide id — renders a `?` that opens the help sheet.
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.fg,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (helpId != null) HelpDot(helpId!),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// "2 / 2 completed" style trailing: strong white number, soft caption.
class _EmphasisCount extends StatelessWidget {
  const _EmphasisCount({required this.strong, required this.soft});

  final String strong;
  final String soft;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: strong,
            style: TextStyle(
              color: AppColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: soft,
            style: TextStyle(color: AppColors.textSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Today's commitment card — "Mission Accomplished." once done, call to
/// action otherwise. Level-1 surface, no borders.
class _TodayCommitmentCard extends StatelessWidget {
  const _TodayCommitmentCard({required this.done, required this.onToggle});

  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.verified_outlined : Icons.bolt_outlined,
                color: done ? AppColors.accentBright : AppColors.cyan,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  done ? 'Mission Accomplished.' : 'Daily Commitment',
                  style: TextStyle(
                    color: AppColors.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? 'You marked today as done. Your discipline is building momentum.'
                : 'Did you meet your commitment today? Mark it to keep the pulse alive.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: done
                ? FilledButton(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inkElevated,
                      foregroundColor: AppColors.fg,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'UNDO TODAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBright,
                      foregroundColor: AppColors.accentDeep,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'I DID IT TODAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Signature gradient bar: lime → cyan "heat" of the cycle.
class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: AppColors.inkElevated,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [AppColors.accentDim, AppColors.cyan],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded checklist row with a circular check "LED": olive-filled with a
/// lime check when done, hollow when pending. Tap anywhere to toggle.
class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.title,
    required this.completed,
    required this.metaLabel,
    required this.onToggle,
    this.trailing,
  });

  final String title;
  final bool completed;
  final String metaLabel;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inkWarm,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.accentDeep : null,
                    border: completed
                        ? null
                        : Border.all(color: AppColors.textFaint, width: 1.5),
                  ),
                  child: completed
                      ? Icon(
                          Icons.check,
                          color: AppColors.accentBright,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: completed
                              ? AppColors.textSoft
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textSoft,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        metaLabel,
                        style: TextStyle(
                          color: completed
                              ? AppColors.limeOlive
                              : AppColors.textFaint,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft empty-state card (level-1 surface, centered icon + copy).
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textFaint, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSoft, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns [TextEditingController] for the milestone title so it is disposed only
/// after the dialog route is finished (avoids TextField use-after-dispose).
class _NewMilestoneDialog extends StatefulWidget {
  const _NewMilestoneDialog();

  @override
  State<_NewMilestoneDialog> createState() => _NewMilestoneDialogState();
}

class _NewMilestoneDialogState extends State<_NewMilestoneDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    Navigator.pop<String?>(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New milestone'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Finish lesson 1'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
