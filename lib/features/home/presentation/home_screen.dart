import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../ai_assistant/application/ai_assistant_providers.dart';
import '../../ai_assistant/presentation/ai_assistant_screen.dart';
import '../../ai_assistant/presentation/widgets/proactive_suggestion_section.dart';
import '../../profile/application/profile_providers.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../execution/domain/models/timer_session.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../planning/application/override_rules.dart';
import '../../planning/application/auto_next_task_flow.dart';
import '../../execution/application/execution_controller.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/application/task_schedule_display.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/application/daily_analytics_providers.dart';
import '../../analytics/application/delivery_providers.dart';
import '../../analytics/application/insight_generation_providers.dart';
import '../../analytics/presentation/coaching_focus_card.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/presentation/accountability_history_screen.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import '../../firebase_test/presentation/firebase_test_screen.dart';
import '../../focus/presentation/focus_selection_screen.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/goal_editor_screen.dart';
import '../../goals/presentation/goal_selection_screen.dart';
import '../../plan_tomorrow/presentation/plan_tomorrow_screen.dart';
import '../../analytics/presentation/analytics_progress_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../context_override/presentation/active_override_banner.dart';
import '../../context_override/presentation/context_override_quick_activate_sheet.dart';
import '../../context_override/presentation/post_override_review_card.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../timer/presentation/timer_session_screen.dart';
import 'quittr_app_bar_title.dart';

enum _PlansChangedAction { reshuffle, defer, skip }

/// Tasks and goals shown on Home before "see more" links to the full hub.
const int kHomePreviewItemLimit = 3;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(scoredTaskStatusesProvider);
    final tasksAsync = ref.watch(todayAllTasksRowsProvider);
    final todaysGoalsAsync = ref.watch(todaysActiveGoalsProvider);
    final flowSnapshotAsync = ref.watch(homeFlowSnapshotProvider);
    final analyticsBundleAsync = ref.watch(analyticsPeriodBundleProvider);
    final execState = ref.watch(executionControllerProvider);

    // Morning brief: show snackbar once per day between 06:00–10:00 if enabled
    _maybeTriggerMorningBrief(context, ref);

    final hasRunningFocusTask =
        execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty &&
        (execState.phase == ExecutionPhase.inProgress ||
            execState.phase == ExecutionPhase.paused);

    return Scaffold(
      floatingActionButton: _CoachAiFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const QuittrAppBarTitle(),
        actions: [
          const _SyncFromCloudAction(),
          IconButton(
            tooltip: 'Accountability history',
            onPressed: () => Navigator.pushNamed(
              context,
              AccountabilityHistoryScreen.routeName,
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Layer4NotificationDispatchBridge(),
          const _HomeTopAnalyticsCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCircle(
                  icon: Icons.bolt,
                  label: 'START FOCUS',
                  onTap: () => Navigator.pushNamed(
                    context,
                    FocusSelectionScreen.routeName,
                    arguments: hasRunningFocusTask
                        ? FocusLaunchArgs(
                            taskId: execState.taskId,
                            taskLabel: execState.taskLabel,
                            taskDurationMinutes:
                                execState.targetDurationMinutes,
                            autoOpenTimer: true,
                            autoStartDelaySeconds: 10,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.add,
                  label: 'ADD TASK',
                  onTap: () =>
                      Navigator.pushNamed(context, AddTaskScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.calendar_today,
                  label: 'PLAN\nTOMORROW',
                  onTap: () => Navigator.pushNamed(
                    context,
                    PlanTomorrowScreen.routeName,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.do_not_disturb_on_outlined,
                  label: 'SET\nMODE',
                  onTap: () => showContextOverrideQuickActivateSheet(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ActiveOverrideBanner(),
          const PostOverrideReviewCard(),
          const _DailyDisciplineSection(),
          const SizedBox(height: 16),
          _FlowNowStrip(flowSnapshotAsync: flowSnapshotAsync),
          const SizedBox(height: 16),
          const HomeCoachingFocusCard(),
          const SizedBox(height: 8),
          // Proactive AI suggestion cards (Phase 4) — collapse when empty
          const ProactiveSuggestionSection(),
          const SizedBox(height: 16),
          _NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, TasksHubScreen.routeName),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's Tasks",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          TasksHubScreen.routeName,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                tasksAsync.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Text(
                        'No tasks yet. Tap ADD TASK to create one.',
                        style: TextStyle(color: Colors.white54),
                      );
                    }
                    final visible =
                        rows.take(kHomePreviewItemLimit).toList();
                    final remaining = rows.length - visible.length;
                    return Column(
                      children: [
                        for (final row in visible)
                          _TaskItem(
                            title: row.task.title,
                            subtitle: _homeTaskSubtitle(row, scores),
                            done:
                                row.task.status == TaskStatus.completed ||
                                scores[row.task.id] == 100,
                            partial:
                                row.task.status != TaskStatus.completed &&
                                scores[row.task.id] != null &&
                                scores[row.task.id]! < 100,
                            onCheckedChange: (checked) {
                              if (checked) {
                                _completeTaskFromHome(context, ref, row);
                              } else {
                                _uncompleteTaskFromHome(context, ref, row);
                              }
                            },
                            onPlansChanged: () =>
                                _openPlansChangedFlow(context, ref, row),
                          ),
                        if (remaining > 0)
                          _HomeSectionSeeMoreLink(
                            label: remaining == 1
                                ? '1 more task'
                                : '$remaining more tasks',
                            onTap: () => Navigator.pushNamed(
                              context,
                              TasksHubScreen.routeName,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Could not load tasks.',
                    style: TextStyle(color: Colors.red.shade200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    GoalSelectionScreen.routeName,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's goals",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          GoalSelectionScreen.routeName,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Commitments active today — tap a goal to log progress.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                todaysGoalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No goals in progress for today.',
                            style: TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              GoalEditorScreen.routeName,
                            ),
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                              color: Color(0xFFB7FF00),
                            ),
                            label: const Text('Create a goal'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB7FF00),
                            ),
                          ),
                        ],
                      );
                    }
                    final visible =
                        goals.take(kHomePreviewItemLimit).toList();
                    final remaining = goals.length - visible.length;
                    return Column(
                      children: [
                        for (final g in visible)
                          _TodayGoalTile(
                            title: g.title,
                            subtitle: _homeGoalSubtitle(g),
                            onTap: () => Navigator.pushNamed(
                              context,
                              GoalDetailScreen.routeName,
                              arguments: g.id,
                            ),
                          ),
                        if (remaining > 0)
                          _HomeSectionSeeMoreLink(
                            label: remaining == 1
                                ? '1 more goal'
                                : '$remaining more goals',
                            onTap: () => Navigator.pushNamed(
                              context,
                              GoalSelectionScreen.routeName,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => Text(
                    'Could not load goals.',
                    style: TextStyle(color: Colors.red.shade200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NeonCard(
            child: analyticsBundleAsync.when(
              data: (bundle) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COACHING INSIGHTS',
                    style: TextStyle(
                      color: Color(0xFF00E6FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goals/Habits today: ${(bundle.goalHabitDay.weightedCompletionRate * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tasks today: ${(bundle.taskDay.weightedCompletionRate * 100).round()}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This week: Goals/Habits ${(bundle.goalHabitWeek.weightedCompletionRate * 100).round()}% · Tasks ${(bundle.taskWeek.weightedCompletionRate * 100).round()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text(
                'Could not load analytics insights.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          tasksAsync.when(
            data: (rows) {
              final completed = _completedForRows(rows, scores);
              final partial = _partialForRows(rows, scores);
              return Text(
                'Completed: $completed • Partial: $partial',
                style: const TextStyle(color: Colors.white70),
              );
            },
            loading: () => const Text(
              'Completed: … • Partial: …',
              style: TextStyle(color: Colors.white70),
            ),
            error: (Object? error, StackTrace? stackTrace) =>
                const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<int>(
            valueListenable: SyncService.instance.pendingCount,
            builder: (context, pending, _) => Text(
              pending > 0
                  ? 'Pending sync operations: $pending'
                  : 'All changes synced',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF301615),
              foregroundColor: const Color(0xFFFF6D4E),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () {},
            child: const Text(
              "I'M DISTRACTED",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                Navigator.pushNamed(context, FirebaseTestScreen.routeName),
            child: const Text('Open Firebase Test Screen'),
          ),
        ],
      ),
      bottomNavigationBar: _ObsidianBottomNav(
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/coach');
          }
          if (index == 2) {
            Navigator.pushNamed(context, GoalSelectionScreen.routeName);
          }
          if (index == 3) {
            Navigator.pushNamed(context, AnalyticsProgressScreen.routeName);
          }
          if (index == 4) {
            Navigator.pushNamed(context, CommunityScreen.routeName);
          }
          if (index == 5) {
            Navigator.pushNamed(context, ProfileScreen.routeName);
          }
        },
      ),
    );
  }
}

/// Shows a one-time morning brief snackbar when the feature is enabled.
void _maybeTriggerMorningBrief(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isMorningWindow = now.hour >= 6 && now.hour < 10;
    if (!isMorningWindow) return;

    final coachOpenedToday = ref.read(coachLastOpenedDateKeyProvider);
    final todayKey = DateKeys.todayKey();
    if (coachOpenedToday == todayKey) return;

    // Check preference asynchronously — best-effort, no blocking
    final prefAsync = ref.read(userProfilePreferenceStreamProvider);
    final morningBriefEnabled =
        prefAsync.whenOrNull(data: (p) => p?.morningBriefEnabled) ?? false;
    if (!morningBriefEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF201f1f),
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Coach AI has suggestions for today — tap to review.',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Open',
            textColor: const Color(0xFFB2ED00),
            onPressed: () => Navigator.pushNamed(
              context,
              '/coach',
              arguments: const CoachRouteArgs(
                openSuggestionsPanel: true,
                preDraftedText: 'Give me a quick plan for today',
              ),
            ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    });
}

class _HomeTopAnalyticsCard extends ConsumerStatefulWidget {
  const _HomeTopAnalyticsCard();

  @override
  ConsumerState<_HomeTopAnalyticsCard> createState() =>
      _HomeTopAnalyticsCardState();
}

class _HomeTopAnalyticsCardState extends ConsumerState<_HomeTopAnalyticsCard>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _milestonePopController;
  late final Animation<double> _introCurve;
  late final Animation<double> _sparklineCurve;
  late final Animation<double> _popScale;

  bool _introPlayed = false;
  int? _previousStreak;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _milestonePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _introCurve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _sparklineCurve = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _popScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _milestonePopController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _milestonePopController.dispose();
    super.dispose();
  }

  Color _scoreAccent(int scorePercent) {
    if (scorePercent >= 80) return const Color(0xFFB7FF00);
    if (scorePercent >= 50) return const Color(0xFFFFD54F);
    return const Color(0xFFFF6D4E);
  }

  void _handleMilestones({required int streak, required int scorePercent}) {
    if (!_introPlayed) {
      _introPlayed = true;
      _previousStreak = streak;
      _introController.forward(from: 0);
      return;
    }
    if (_previousStreak != null && streak > _previousStreak!) {
      _milestonePopController
          .forward(from: 0)
          .then((_) => _milestonePopController.reverse());
    }
    _previousStreak = streak;
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(analyticsPeriodBundleProvider);
    return _NeonCard(
      child: bundleAsync.when(
        data: (bundle) {
          final streak = bundle.goalHabitWeek.currentStreakDays;
          final scorePercent =
              (bundle.goalHabitDay.weightedCompletionRate * 100).round();
          _handleMilestones(streak: streak, scorePercent: scorePercent);
          return AnimatedBuilder(
            animation: Listenable.merge([
              _introController,
              _milestonePopController,
            ]),
            builder: (context, _) {
              final introValue = _introController.isAnimating
                  ? _introCurve.value
                  : 1.0;
              final displayStreak = _introController.isAnimating
                  ? (streak * introValue).round()
                  : streak;
              final displayScore = _introController.isAnimating
                  ? (scorePercent * introValue).round()
                  : scorePercent;
              final sparkProgress = _introController.isAnimating
                  ? _sparklineCurve.value
                  : 1.0;
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Transform.scale(
                    scale: _popScale.value,
                    child: Text(
                      '$displayStreak',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'DAY STREAK',
                    style: TextStyle(letterSpacing: 2, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Today's Progress",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _scoreAccent(scorePercent).withAlpha(24),
                      border: Border.all(
                        color: _scoreAccent(scorePercent).withAlpha(110),
                      ),
                    ),
                    child: Text(
                      '$displayScore% Goals/Habits',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _scoreAccent(scorePercent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '7-day trend',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MiniSparkline(
                    valuesA: bundle.goalHabitWeekSeries,
                    valuesB: bundle.taskWeekSeries,
                    drawProgress: sparkProgress,
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Column(
          children: [
            SizedBox(height: 8),
            Text(
              '0',
              style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
            ),
            Text(
              'DAY STREAK',
              style: TextStyle(letterSpacing: 2, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyDisciplineSection extends ConsumerWidget {
  const _DailyDisciplineSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(analyticsPeriodBundleProvider);
    return bundleAsync.when(
      data: (bundle) {
        final clamped = bundle.goalHabitWeek.weightedCompletionRate.clamp(
          0.0,
          1.0,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEEKLY DISCIPLINE ${(clamped * 100).round()}%',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: clamped, minHeight: 8),
            ),
          ],
        );
      },
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY DISCIPLINE',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(value: 0, minHeight: 8),
          ),
        ],
      ),
      error: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY DISCIPLINE',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(value: 0, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({
    required this.valuesA,
    required this.valuesB,
    this.drawProgress = 1.0,
  });

  final List<double> valuesA;
  final List<double> valuesB;
  final double drawProgress;

  @override
  Widget build(BuildContext context) {
    final a = valuesA.length >= 7
        ? valuesA.sublist(valuesA.length - 7)
        : [...List<double>.filled(7 - valuesA.length, 0), ...valuesA];
    final b = valuesB.length >= 7
        ? valuesB.sublist(valuesB.length - 7)
        : [...List<double>.filled(7 - valuesB.length, 0), ...valuesB];
    return SizedBox(
      height: 44,
      child: CustomPaint(
        painter: _SparklinePainter(
          a: a,
          b: b,
          drawProgress: drawProgress.clamp(0.0, 1.0),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}


class _Layer4NotificationDispatchBridge extends ConsumerStatefulWidget {
  const _Layer4NotificationDispatchBridge();

  @override
  ConsumerState<_Layer4NotificationDispatchBridge> createState() =>
      _Layer4NotificationDispatchBridgeState();
}

class _Layer4NotificationDispatchBridgeState
    extends ConsumerState<_Layer4NotificationDispatchBridge> {
  String? _lastPrimaryInsightId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Layer4NotificationDecisionViewModel>>(
      layer4TodayNotificationDecisionProvider,
      (previous, next) async {
        final vm = next.valueOrNull;
        if (vm == null) return;
        final primaryId = vm.primaryInsightId;
        final notifications = ref.read(localNotificationsServiceProvider);
        final notificationId = primaryId == null
            ? null
            : ('layer4:$primaryId').hashCode.abs() % 2147483647;
        if (!vm.isEligible || primaryId == null || primaryId.trim().isEmpty) {
          final lastId = _lastPrimaryInsightId;
          if (lastId != null && lastId.isNotEmpty) {
            final oldNotificationId =
                ('layer4:$lastId').hashCode.abs() % 2147483647;
            await notifications.cancel(oldNotificationId);
          }
          _lastPrimaryInsightId = null;
          return;
        }
        if (_lastPrimaryInsightId == primaryId) return;
        final insights = ref.read(layer3TodayDeliveryInsightsProvider).valueOrNull ??
            const <GeneratedInsight>[];
        final selected = insights.where((item) => item.insightId == primaryId).toList();
        final body = selected.isEmpty
            ? 'You have a coaching insight ready.'
            : selected.first.message;
        final granted = await notifications.requestPermissionsIfNeeded();
        if (!granted || notificationId == null) return;
        await notifications.schedule(
          id: notificationId,
          title: 'Coach Insight Ready',
          body: body,
          when: DateTime.now().add(const Duration(minutes: 1)),
          payload: 'layer4:$primaryId',
        );
        _lastPrimaryInsightId = primaryId;
      },
    );
    return const SizedBox.shrink();
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.a,
    required this.b,
    required this.drawProgress,
  });

  final List<double> a;
  final List<double> b;
  final double drawProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      base,
    );

    _drawSeries(canvas, size, a, const Color(0xFFB7FF00), drawProgress);
    _drawSeries(canvas, size, b, const Color(0xFF00E6FF), drawProgress);
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
    double progress,
  ) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final maxPoint = (values.length - 1) * progress;
    final fullPoints = maxPoint.floor();
    for (var i = 0; i <= fullPoints && i < values.length; i++) {
      final x = values.length == 1
          ? 0.0
          : (size.width * i / (values.length - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final hasFractional = fullPoints < values.length - 1;
    if (hasFractional) {
      final t = maxPoint - fullPoints;
      final i0 = fullPoints;
      final i1 = fullPoints + 1;
      final x0 = values.length == 1
          ? 0.0
          : (size.width * i0 / (values.length - 1));
      final y0 = size.height - (values[i0].clamp(0.0, 1.0) * size.height);
      final x1 = values.length == 1
          ? 0.0
          : (size.width * i1 / (values.length - 1));
      final y1 = size.height - (values[i1].clamp(0.0, 1.0) * size.height);
      final xf = x0 + (x1 - x0) * t;
      final yf = y0 + (y1 - y0) * t;
      if (fullPoints == 0 && progress <= 0.0001) {
        path.moveTo(x0, y0);
      }
      path.lineTo(xf, yf);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.a != a ||
        oldDelegate.b != b ||
        oldDelegate.drawProgress != drawProgress;
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: 108,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB7FF00)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Flow now: one status line + slim next-task row (~72px vs ~140px).
class _FlowNowStrip extends ConsumerWidget {
  const _FlowNowStrip({required this.flowSnapshotAsync});

  final AsyncValue<HomeFlowSnapshot> flowSnapshotAsync;

  static const _kAccent = Color(0xFF00E6FF);
  static const _kMuted = Color(0xFFADAAAA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionControllerProvider);
    final todayRows = ref.watch(todayAllTasksRowsProvider).valueOrNull ?? const [];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: flowSnapshotAsync.when(
        data: (flow) => _buildContent(context, ref, flow, execState, todayRows),
        loading: () => const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, _) => const Text(
          'Flow unavailable',
          style: TextStyle(color: _kMuted, fontSize: 12),
        ),
      ),
    );
  }

  PlannedTask? _findTask(List<PlannedTaskRow> rows, String taskId) {
    for (final row in rows) {
      if (row.task.id == taskId) return row.task;
    }
    return null;
  }

  void _openTimerScreen(BuildContext context, WidgetRef ref, PlannedTask task) {
    ref.read(activeExecutionTaskIdProvider.notifier).state = task.id;
    ref.read(activeExecutionTaskLabelProvider.notifier).state = task.title;
    ref.read(executionControllerProvider.notifier).setTask(
          id: task.id,
          label: task.title,
          durationMinutes: task.durationMinutes,
        );
    Navigator.pushNamed(context, TimerSessionScreen.routeName);
  }

  Future<void> _toggleFocusTimer(
    BuildContext context,
    WidgetRef ref,
    PlannedTask task,
    ExecutionState execState,
  ) async {
    final ctrl = ref.read(executionControllerProvider.notifier);
    final isThisTask = execState.targetType == TimerSessionTargetType.task &&
        execState.taskId == task.id;

    if (isThisTask) {
      if (execState.phase == ExecutionPhase.inProgress) {
        ctrl.pause();
        return;
      }
      if (execState.phase == ExecutionPhase.paused) {
        ctrl.resume();
        return;
      }
      if (execState.phase == ExecutionPhase.notStarted) {
        ctrl.start();
        unawaited(
          ref.read(reminderSyncServiceProvider).markTaskStarted(task.id),
        );
      }
      return;
    }

    final otherRunning = execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty &&
        execState.taskId != task.id &&
        (execState.phase == ExecutionPhase.inProgress ||
            execState.phase == ExecutionPhase.paused);
    if (otherRunning) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task "${execState.taskLabel}" is already in focus. '
            'Pause or stop it before switching.',
          ),
        ),
      );
      return;
    }

    ref.read(activeExecutionTaskIdProvider.notifier).state = task.id;
    ref.read(activeExecutionTaskLabelProvider.notifier).state = task.title;
    ctrl.setTask(
      id: task.id,
      label: task.title,
      durationMinutes: task.durationMinutes,
    );
    ctrl.start();
    unawaited(ref.read(reminderSyncServiceProvider).markTaskStarted(task.id));
  }

  static String _formatElapsed(Duration elapsed) {
    final mins = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hrs = elapsed.inHours;
    if (hrs > 0) {
      return '${hrs.toString().padLeft(2, '0')}:$mins:$secs';
    }
    return '$mins:$secs';
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HomeFlowSnapshot flow,
    ExecutionState execState,
    List<PlannedTaskRow> todayRows,
  ) {
    final block = flow.currentBlockLabel;
    final open = flow.openTaskCount;
    final next = flow.nextTaskRow?.task;

    final focusActive = execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty &&
        (execState.phase == ExecutionPhase.inProgress ||
            execState.phase == ExecutionPhase.paused);

    final displayTask = focusActive
        ? (_findTask(todayRows, execState.taskId) ?? next)
        : next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'FLOW NOW',
              style: TextStyle(
                color: _kAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$block · $open open',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (displayTask != null) ...[
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFF1A1D22),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _FlowNowTimerControl(
                    task: displayTask,
                    execState: execState,
                    onPressed: () => unawaited(
                      _toggleFocusTimer(context, ref, displayTask, execState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _openTimerScreen(context, ref, displayTask),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              focusActive &&
                                      execState.taskId == displayTask.id
                                  ? (execState.phase == ExecutionPhase.paused
                                      ? 'Focus paused'
                                      : 'Focus active')
                                  : 'Next up',
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              focusActive &&
                                      execState.taskId == displayTask.id
                                  ? execState.taskLabel
                                  : displayTask.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _FlowNowStrip._subtitleFor(
                                task: displayTask,
                                execState: execState,
                                focusActive: focusActive &&
                                    execState.taskId == displayTask.id,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () =>
                        _openTimerScreen(context, ref, displayTask),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: _kMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'No next task — add one or check Tasks.',
              style: TextStyle(color: _kMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }

  static String _subtitleFor({
    required PlannedTask task,
    required ExecutionState execState,
    required bool focusActive,
  }) {
    final parts = <String>[];
    if (focusActive) {
      final targetMin =
          execState.targetDurationMinutes ?? task.durationMinutes;
      parts.add('${_formatElapsed(execState.elapsed)} / ${targetMin}m');
    } else {
      parts.add('${task.durationMinutes}m target');
    }
    final timeLabel = taskScheduledTimeLabel(task);
    if (timeLabel != null) {
      parts.add(timeLabel);
    }
    return parts.join(' · ');
  }
}

class _FlowNowTimerControl extends StatelessWidget {
  const _FlowNowTimerControl({
    required this.task,
    required this.execState,
    required this.onPressed,
  });

  final PlannedTask task;
  final ExecutionState execState;
  final VoidCallback onPressed;

  static const _kAccent = Color(0xFF00E6FF);

  @override
  Widget build(BuildContext context) {
    final isThisTask = execState.targetType == TimerSessionTargetType.task &&
        execState.taskId == task.id;
    final running =
        isThisTask && execState.phase == ExecutionPhase.inProgress;
    final paused = isThisTask && execState.phase == ExecutionPhase.paused;
    final showProgress = running || paused;

    final targetMin = isThisTask
        ? (execState.targetDurationMinutes ?? task.durationMinutes)
        : task.durationMinutes;
    final target = Duration(minutes: targetMin);
    final progress = showProgress && target.inSeconds > 0
        ? (execState.elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showProgress)
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white12,
                  color: _kAccent,
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: _kAccent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSectionSeeMoreLink extends StatelessWidget {
  const _HomeSectionSeeMoreLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB7FF00),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TodayGoalTile extends StatelessWidget {
  const _TodayGoalTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.track_changes_outlined,
              color: Color(0xFFB7FF00),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

String _homeGoalSubtitle(UserGoal g) {
  final unit =
      g.measurementKind == MeasurementKind.custom &&
          (g.customLabel?.isNotEmpty ?? false)
      ? g.customLabel!
      : g.measurementKind.displayLabel().toLowerCase();
  final suffix = switch ((g.periodMode, g.horizon)) {
    (GoalPeriodMode.durationDays, _) => 'per day in this run',
    (_, GoalHorizon.weekly) => 'this week',
    (_, GoalHorizon.monthly) => 'per day (in this month)',
    (_, GoalHorizon.daily) => 'per day',
  };
  final value = g.targetValue == g.targetValue.roundToDouble()
      ? g.targetValue.toInt().toString()
      : g.targetValue.toString();
  return '${GoalCategories.label(g.categoryId)} · $value $unit ($suffix)';
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    this.subtitle,
    this.done = false,
    this.partial = false,
    required this.onCheckedChange,
    required this.onPlansChanged,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final bool partial;
  final void Function(bool checked) onCheckedChange;
  final VoidCallback onPlansChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: done,
        onChanged: (value) {
          if (value == null) return;
          onCheckedChange(value);
        },
        activeColor: const Color(0xFFB7FF00),
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          fontStyle: partial ? FontStyle.italic : FontStyle.normal,
          color: Colors.white70,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
      trailing: IconButton(
        tooltip: 'Plans Changed?',
        icon: const Icon(Icons.swap_horiz, color: Colors.white54),
        onPressed: onPlansChanged,
      ),
    );
  }
}

Future<void> _openPlansChangedFlow(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final action = await showDialog<_PlansChangedAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Plans Changed?'),
      content: const Text('How should we adjust this task right now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.reshuffle),
          child: const Text('Reshuffle'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.defer),
          child: const Text('Defer'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.skip),
          child: const Text('Skip'),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;

  final reason = await _promptOverrideReason(context);
  if (reason == null) return;
  if (!context.mounted) return;
  final routineForPolicy = await _routineForPlannedRow(ref, row);
  if (!context.mounted) return;
  if (OverrideRules.requiresStrictOverrideConfirm(
    row.task,
    routine: routineForPolicy,
  )) {
    final ok = await _confirmStrictOverride(context, row.task, action);
    if (ok != true) return;
  }

  final planning = ref.read(planningRepositoryProvider);
  final t = row.task;
  final now = DateTime.now().millisecondsSinceEpoch;
  var nextUrgencyDelta = 0;
  switch (action) {
    case _PlansChangedAction.reshuffle:
      final reshuffled = PlannedTask(
        id: t.id,
        routineId: t.routineId,
        blockId: t.blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: t.orderIndex + 1,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderTimeIso,
        status: t.status,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: t.planDateKey ?? row.dateKey,
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Reshuffle] ${reason.note}',
        ),
        sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 100,
        isHabitAnchor: t.isHabitAnchor,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(reshuffled);
      nextUrgencyDelta = 10;
      break;
    case _PlansChangedAction.defer:
      final deferTime = DateTime.now().add(const Duration(hours: 1));
      final deferred = PlannedTask(
        id: t.id,
        routineId: t.routineId,
        blockId: t.blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: t.orderIndex,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderEnabled
            ? deferTime.toIso8601String()
            : t.reminderTimeIso,
        status: TaskStatus.notStarted,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: t.planDateKey ?? row.dateKey,
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Defer] ${reason.note}',
        ),
        sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 500,
        isHabitAnchor: t.isHabitAnchor,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(deferred);
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.taskDeferred,
        entityId: t.id,
        entityKind: 'task',
        sourceSurface: 'home',
        idempotencyKey:
            'task_deferred_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
        modeRefId: t.modeRefId,
        reason: reason.note,
      );
      nextUrgencyDelta = 20;
      break;
    case _PlansChangedAction.skip:
      final skipped = PlannedTask(
        id: t.id,
        routineId: t.routineId,
        blockId: t.blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: t.orderIndex,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderTimeIso,
        status: TaskStatus.completed,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: t.planDateKey ?? row.dateKey,
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Skip] ${reason.note}',
        ),
        sequenceIndex: t.sequenceIndex,
        isHabitAnchor: t.isHabitAnchor,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(skipped);
      nextUrgencyDelta = -20;
      break;
  }

  final blocks = await planning.getBlocks(row.routineId);
  TaskBlock? currentBlock;
  for (final b in blocks) {
    if (b.id == row.blockId) {
      currentBlock = b;
      break;
    }
  }
  if (currentBlock != null) {
    final adjusted = (currentBlock.urgencyScore + nextUrgencyDelta).clamp(
      0,
      100,
    );
    await planning.upsertBlock(
      TaskBlock(
        id: currentBlock.id,
        routineId: currentBlock.routineId,
        title: currentBlock.title,
        orderIndex: currentBlock.orderIndex,
        startMinutesFromMidnight: currentBlock.startMinutesFromMidnight,
        endMinutesFromMidnight: currentBlock.endMinutesFromMidnight,
        urgencyScore: adjusted,
        modeRefId: currentBlock.modeRefId,
        createdAtMs: currentBlock.createdAtMs,
        updatedAtMs: now,
      ),
    );
  }

  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: t.id,
      type: FlowTransitionType.moveWithReason,
      planChangeIntent: PlanChangeIntent.logical,
      reasonCategory: reason.reason,
      reasonNote: '[${action.name}] ${reason.note}',
      createdAtMs: now,
    ),
  );
  await planning.logAccountability(
    AccountabilityLog(
      id: StableId.generate('acct'),
      taskId: t.id,
      action: switch (action) {
        _PlansChangedAction.reshuffle => AccountabilityAction.reshuffle,
        _PlansChangedAction.defer => AccountabilityAction.defer,
        _PlansChangedAction.skip => AccountabilityAction.skip,
      },
      reasonCategory: reason.reason,
      reasonNote: reason.note,
      modeRefId: t.modeRefId,
      taskPriority: t.priority,
      createdAtMs: now,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(t.id);

  invalidateTaskListProviders(ref);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Updated "${t.title}" with ${action.name} decision.'),
    ),
  );
}

Future<bool?> _confirmStrictOverride(
  BuildContext context,
  PlannedTask task,
  _PlansChangedAction action,
) async {
  final confirmCtrl = TextEditingController();
  String? errorText;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Strict confirmation required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a high-importance task ("${task.title}"). '
              'You are choosing to ${action.name}.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Type CONFIRM to proceed.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(labelText: 'Type CONFIRM'),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!OverrideRules.isStrictConfirmInputValid(confirmCtrl.text)) {
                setState(() => errorText = 'Please type CONFIRM exactly.');
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    ),
  );
  confirmCtrl.dispose();
  return ok;
}

Future<({OverrideReasonCategory reason, String note})?> _promptOverrideReason(
  BuildContext context,
) async {
  final reasons = OverrideReasonCategory.values;
  OverrideReasonCategory selectedReason = reasons.first;
  final noteCtrl = TextEditingController();
  String? errorText;
  final choice =
      await showDialog<({OverrideReasonCategory reason, String note})>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Why are plans changing?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OverrideReasonCategory>(
                  initialValue: selectedReason,
                  items: [
                    for (final r in reasons)
                      DropdownMenuItem(value: r, child: Text(r.label)),
                  ],
                  onChanged: (v) =>
                      setState(() => selectedReason = v ?? reasons.first),
                  decoration: const InputDecoration(
                    labelText: 'Reason category',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Logical reason (1-2 sentences)',
                    hintText: 'Explain clearly why this is the best move now.',
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final note = noteCtrl.text.trim();
                  try {
                    FlowTransitionEvent.validateReasonNote(note);
                  } catch (_) {
                    setState(
                      () => errorText = 'Give a clear reason in 1-2 sentences.',
                    );
                    return;
                  }
                  Navigator.pop(ctx, (reason: selectedReason, note: note));
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
  noteCtrl.dispose();
  return choice;
}

class _NeonCard extends StatelessWidget {
  const _NeonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

class _SyncFromCloudAction extends StatefulWidget {
  const _SyncFromCloudAction();

  @override
  State<_SyncFromCloudAction> createState() => _SyncFromCloudActionState();
}

class _SyncFromCloudActionState extends State<_SyncFromCloudAction> {
  late bool _wasSyncing;

  @override
  void initState() {
    super.initState();
    final n = SyncService.instance.isSyncingFromRemote;
    _wasSyncing = n.value;
    n.addListener(_onSyncingChanged);
  }

  @override
  void dispose() {
    SyncService.instance.isSyncingFromRemote.removeListener(_onSyncingChanged);
    super.dispose();
  }

  void _onSyncingChanged() {
    final syncing = SyncService.instance.isSyncingFromRemote.value;
    if (_wasSyncing && !syncing && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated from cloud'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
    _wasSyncing = syncing;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncService.instance.isSyncingFromRemote,
      builder: (context, syncing, _) {
        if (syncing) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return IconButton(
          tooltip: 'Sync from cloud',
          onPressed: () =>
              unawaited(SyncService.instance.syncFromRemote(force: true)),
          icon: const Icon(Icons.sync),
        );
      },
    );
  }
}

Future<Routine?> _routineForPlannedRow(
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final planning = ref.read(planningRepositoryProvider);
  try {
    final routines = await planning.getRoutinesForDate(row.dateKey);
    for (final r in routines) {
      if (r.id == row.routineId) return r;
    }
  } catch (_) {}
  return null;
}

String? _homeTaskSubtitle(PlannedTaskRow row, Map<String, int> scores) {
  final id = row.task.id;
  final p = scores[id];
  if (p != null && p < 100) return '$p% complete';
  return null;
}

int _completedForRows(List<PlannedTaskRow> rows, Map<String, int> scores) {
  var n = 0;
  for (final row in rows) {
    if (row.task.status == TaskStatus.completed || scores[row.task.id] == 100) {
      n++;
    }
  }
  return n;
}

int _partialForRows(List<PlannedTaskRow> rows, Map<String, int> scores) {
  var n = 0;
  for (final row in rows) {
    if (row.task.status == TaskStatus.completed) continue;
    final v = scores[row.task.id];
    if (v != null && v < 100) n++;
  }
  return n;
}

Future<void> _completeTaskFromHome(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final t = row.task;
  final routineForPolicy = await _routineForPlannedRow(ref, row);
  if (!context.mounted) return;
  if (OverrideRules.requiresMandatoryTimer(t, routine: routineForPolicy)) {
    final sessions = await ref
        .read(executionRepositoryProvider)
        .getSessionsForTask(t.id);
    final ok = OverrideRules.hasSatisfiedMandatoryTimer(sessions);
    if (!ok) {
      if (!context.mounted) return;
      final start = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Timer required'),
          content: Text(
            'This task requires a completed timer session before marking done.\n\nTask: ${t.title}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start timer'),
            ),
          ],
        ),
      );
      if (start == true && context.mounted) {
        ref.read(activeExecutionTaskIdProvider.notifier).state = t.id;
        ref.read(activeExecutionTaskLabelProvider.notifier).state = t.title;
        ref
            .read(executionControllerProvider.notifier)
            .setTask(
              id: t.id,
              label: t.title,
              durationMinutes: t.durationMinutes,
            );
        await Navigator.pushNamed(context, TimerSessionScreen.routeName);
      }
      return;
    }
  }
  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  final updated = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: t.durationMinutes,
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: TaskStatus.completed,
    createdAtMs: t.createdAtMs,
    updatedAtMs: now,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: t.notes,
    sequenceIndex: t.sequenceIndex,
    isHabitAnchor: t.isHabitAnchor,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  try {
    await planning.upsertTask(updated);
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.taskCompleted,
      entityId: t.id,
      entityKind: 'task',
      sourceSurface: 'home',
      idempotencyKey:
          'task_completed_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
      modeRefId: t.modeRefId,
    );
    await ref.read(reminderSyncServiceProvider).markTaskStarted(t.id);
    await ref
        .read(scoringControllerProvider)
        .submit(taskId: t.id, completionPercent: 100);
    final prev = ref.read(scoredTaskStatusesProvider);
    ref.read(scoredTaskStatusesProvider.notifier).state = {...prev, t.id: 100};
    invalidateTaskListProviders(ref);
    invalidateTodayCoachingDelivery(ref);
    if (!context.mounted) return;
    await runAutoNextTaskFlow(
      context,
      ref,
      completedTaskId: t.id,
      completionPercent: 100,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not complete: $e')));
    }
  }
}

String _appendMoveReason({
  required String? existing,
  required OverrideReasonCategory reason,
  required String explanation,
}) {
  final stamp = DateTime.now().toIso8601String();
  final entry = '[Moved $stamp] ${reason.label}: $explanation';
  if (existing == null || existing.trim().isEmpty) return entry;
  return '$existing\n$entry';
}

Future<void> _uncompleteTaskFromHome(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final t = row.task;
  final scoreMap = ref.read(scoredTaskStatusesProvider);
  final isDone = t.status == TaskStatus.completed || scoreMap[t.id] == 100;
  if (!isDone) return;

  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  final updated = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: t.durationMinutes,
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: TaskStatus.notStarted,
    createdAtMs: t.createdAtMs,
    updatedAtMs: now,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: t.notes,
    sequenceIndex: t.sequenceIndex,
    isHabitAnchor: t.isHabitAnchor,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  try {
    await planning.upsertTask(updated);
    final prev = ref.read(scoredTaskStatusesProvider);
    final next = Map<String, int>.from(prev)..remove(t.id);
    ref.read(scoredTaskStatusesProvider.notifier).state = next;
    invalidateTaskListProviders(ref);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update task: $e')));
    }
  }
}

// ─── Obsidian Pulse bottom nav ────────────────────────────────────────────────

// ─── Coach AI FAB ─────────────────────────────────────────────────────────────

class _CoachAiFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/coach'),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF262626).withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEAFFB8).withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFEAFFB8),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _ObsidianBottomNav extends ConsumerWidget {
  const _ObsidianBottomNav({required this.onTap});

  final void Function(int index) onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.auto_awesome_rounded, label: 'Coach'),
    (icon: Icons.track_changes_rounded, label: 'Goals'),
    (icon: Icons.leaderboard_rounded, label: 'Progress'),
    (icon: Icons.group_rounded, label: 'Community'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _kSurface = Color(0xFF0E0E0E);
  static const _kVariant = Color(0xFFADAAAA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show red badge on Coach tab when there is a pending blocked plan
    final aiServiceAsync = ref.watch(resolvedAiAssistantProvider);
    final hasBlockedPlan = aiServiceAsync.whenOrNull(
          data: (svc) => svc.pendingPlan?.isBlockedByContext == true,
        ) ??
        false;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: _kSurface.withValues(alpha: 0.8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                // Coach tab (index 1) gets a badge when there's a blocked plan
                final showBadge = i == 1 && hasBlockedPlan;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              item.icon,
                              size: 24,
                              color: _kVariant,
                            ),
                            if (showBadge)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _kVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
