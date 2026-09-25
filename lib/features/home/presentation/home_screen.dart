import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../ai_assistant/application/ai_assistant_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../execution/domain/models/timer_session.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/application/override_rules.dart';
import '../../planning/application/auto_next_task_flow.dart';
import '../../execution/application/execution_controller.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/application/task_schedule_display.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/application/progress_selection.dart';
import '../../analytics/domain/progress_period.dart';
import '../../analytics/application/analytics_period_bundle_notifier.dart';
import '../../analytics/application/announced_insight_store.dart';
import '../../analytics/application/coaching_insight_notification_policy.dart';
import '../../analytics/application/delivery_providers.dart';
import '../../analytics/presentation/coaching_insight_copy.dart';
import '../../analytics/application/focus_providers.dart';
import '../../analytics/application/insight_generation_providers.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../analytics/domain/models/current_coaching_focus.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/presentation/override_reason_dialog.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../scoring/presentation/score_task_dialog.dart';
import '../../add_task/presentation/add_task_sheet.dart';
import '../../tasks_hub/presentation/task_detail_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import '../../focus/presentation/focus_selection_screen.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/presentation/widgets/goal_counter_sheet.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../intentions/presentation/promises_section.dart';
import '../../intentions/presentation/seize_the_moment_card.dart';
import '../../goals/presentation/goal_template_picker_screen.dart';
import '../../plan_tomorrow/presentation/plan_tomorrow_screen.dart';
import '../../../app/application/main_tab_navigation.dart';
import '../../analytics/presentation/analytics_progress_screen.dart';
import '../../ai_assistant/presentation/widgets/coach_ai_fab.dart';
import '../../context_override/domain/models/interruption_level.dart';
import '../../reminders/presentation/recovery_card.dart';
import '../../reminders/presentation/reminder_health_section.dart';
import '../../reminders/presentation/recovery_navigation.dart';
import '../../context_override/presentation/active_override_banner.dart';
import '../../context_override/presentation/context_override_quick_activate_sheet.dart';
import '../../context_override/presentation/post_override_review_card.dart';
import '../../direction/presentation/new_month_direction_card.dart';
import '../../time_tracker/presentation/track_pill.dart';
import '../../reminders/application/attention_orchestrator_providers.dart';
import '../../reminders/application/notification_route_resolver.dart';
import '../../reminders/domain/models/attention_outcome.dart';
import '../../reminders/domain/models/reminder_intent.dart';
import '../../education/presentation/tour_targets.dart';
import '../../education/presentation/help_dot.dart';
import '../../timer/presentation/timer_session_screen.dart';
import 'sidepal_app_bar_title.dart';

import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/async_value_ui.dart';

enum _PlansChangedAction { reshuffle, defer, skip }

/// Tasks and goals shown on Home before "see more" links to the full hub.
const int kHomePreviewItemLimit = 3;

/// Card heading inside Home's white cards (redesign 2026-09-14): 22px bold,
/// one step under the recovery card's 24px headline.
TextStyle get _kCardTitleStyle => TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 1.15,
  letterSpacing: -0.3,
  color: AppColors.textPrimary,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(scoredTaskStatusesProvider);
    final tasksAsync = ref.watch(todayAllTasksRowsProvider);
    final todaysGoalsAsync = ref.watch(todaysActiveGoalsProvider);
    final flowSnapshotAsync = ref.watch(homeFlowSnapshotProvider);
    // No execution-state watch here: the top-level build doesn't render
    // session state ( _FlowNowStrip watches it itself), and the Focus button
    // reads it at press time — so per-second `elapsed` ticks never rebuild
    // the whole home Scaffold.

    // Morning brief: show snackbar once per day between 06:00–10:00 if enabled
    _maybeTriggerMorningBrief(context, ref);

    return Scaffold(
      // Lifted to match the satellite position on tabs that stack it above
      // their own FAB — the coach button must not change size or hop
      // vertically as you switch tabs (full-size everywhere since 2026-08-25).
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 66),
        child: CoachAiFab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Header (redesign 2026-09-14): a plain wordmark on the left, three
      // white circular buttons on the right — intentional touch targets
      // rather than loose icons.
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SidePalAppBarTitle(),
        actions: [
          // One action in the chrome (2026-09-19): the accountability
          // history shortcut and the placeholder bell left — the history
          // screen keeps its route, the bell returns with a notification
          // center.
          const _SyncFromCloudAction(),
          const SizedBox(width: 20),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _Layer4NotificationDispatchBridge(),
          // Keyed as a guided-tour target ("this is your progress").
          _HomeTopAnalyticsCard(key: TourTargets.progressCard),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.bolt_rounded,
                  label: 'Start focus',
                  tooltip: 'Start focus',
                  active: true,
                  onTap: () {
                    final exec = ref.read(executionControllerProvider);
                    Navigator.pushNamed(
                      context,
                      FocusSelectionScreen.routeName,
                      arguments: exec.hasActiveFocusTask
                          ? FocusLaunchArgs(
                              taskId: exec.taskId,
                              taskLabel: exec.taskLabel,
                              taskDurationMinutes: exec.targetDurationMinutes,
                              autoOpenTimer: true,
                              autoStartDelaySeconds: 10,
                            )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  // Guided-tour target: "tap here to create your first task".
                  key: TourTargets.addTaskTile,
                  icon: Icons.add_rounded,
                  label: 'Add task',
                  tooltip: 'Add task',
                  onTap: () => showAddTaskSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Plan tomorrow',
                  tooltip: 'Plan tomorrow',
                  onTap: () => Navigator.pushNamed(
                    context,
                    PlanTomorrowScreen.routeName,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.do_not_disturb_on_outlined,
                  label: 'Set status',
                  tooltip: 'Set status',
                  onTap: () => showContextOverrideQuickActivateSheet(context),
                ),
              ),
            ],
          ),
          // Time Tracker (2026-09-12): capture is one tap from Home — a
          // pill, not a card; it opens the sheet, never the timeline. The
          // Time page's footer switch hides it (2026-09-18) — that switch
          // decides this and nothing else.
          if (ref.watch(homeTrackPillEnabledProvider)) ...[
            const SizedBox(height: 16),
            const TrackPill(),
          ],
          const SizedBox(height: 24),
          // Humanizing Phase 1 — promises live near the top: seize-the-moment
          // (only when a free window fits an open promise right now), then
          // the ambient promises strip.
          const SeizeTheMomentCard(),
          const PromisesSection(),
          const SizedBox(height: 24),
          const ActiveOverrideBanner(),
          // What SidePal still owes you leads the recovery band (FR-R-50):
          // above the post-override review, because an overdue task is a
          // standing debt while that card is a one-off.
          // Silence is the normal state (FR-R-80): this appears only when
          // reminders genuinely cannot do their job.
          const ReminderHealthHomeHint(),
          RecoveryCard(
            onOpenTask: (entityId, entityKind) => openRecoveryTask(
              context,
              ref,
              entityId,
              entityKind: entityKind,
            ),
            onResolve: (row, kind) =>
                resolveRecoveryRow(context, ref, row, kind),
          ),
          // Direction's month-rollover ask (2026-09-11): a one-off in the
          // one-off band, above the post-override review. Silent otherwise.
          const NewMonthDirectionCard(),
          const PostOverrideReviewCard(),
          const _DailyDisciplineSection(),
          const SizedBox(height: 24),
          _FlowNowStrip(flowSnapshotAsync: flowSnapshotAsync),
          const SizedBox(height: 20),
          // Coaching focus + proactive suggestions left Home (2026-08-23):
          // focus lives on Progress (notification + Profile-tab dot when a
          // new one lands); suggestions live behind the Coach FAB's dot.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, TasksHubScreen.routeName),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text("Today's Tasks", style: _kCardTitleStyle),
                      ),
                      const HelpDot('todaysTasks'),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: AppColors.fg54),
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No tasks yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          _createTaskLink(context),
                        ],
                      );
                    }
                    final visible = rows.take(kHomePreviewItemLimit).toList();
                    final remaining = rows.length - visible.length;
                    return Column(
                      children: [
                        for (final row in visible)
                          _TaskItem(
                            // Guided-tour target: the first task's circle.
                            checkboxKey: row == visible.first
                                ? TourTargets.firstTaskCheckbox
                                : null,
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              TaskDetailScreen.routeName,
                              arguments: TaskDetailArgs.fromRow(row),
                            ),
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
                        // Direct add from Home (2026-08-25) — mirrors the
                        // goals card's "Create a goal" link.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _createTaskLink(context),
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
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => navigateToMainTab(
                    context,
                    ref,
                    index: MainTabIndex.goals,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text("Today's goals", style: _kCardTitleStyle),
                      ),
                      const HelpDot('todaysGoals'),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: AppColors.fg54),
                        onPressed: () => navigateToMainTab(
                          context,
                          ref,
                          index: MainTabIndex.goals,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commitments active today — tap a goal to log progress.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                todaysGoalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) {
                      final otherDays = ref.watch(otherDayGoalsCountProvider);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherDays == 0
                                ? 'No goals in progress for today.'
                                : 'No goals due today. $otherDays saved for '
                                      'other days in the Goals tab.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          _createGoalLink(context),
                        ],
                      );
                    }
                    final visible = goals.take(kHomePreviewItemLimit).toList();
                    final remaining = goals.length - visible.length;
                    return Column(
                      children: [
                        // Tap = log progress (2026-08-25) — the same
                        // quick-log sheet as the Goals page, honoring the
                        // section's own "tap a goal to log progress" line.
                        // Goal detail stays reachable via the sheet's
                        // Details pill; while progress is still loading
                        // the tap falls back to the detail push.
                        for (final g in visible)
                          Consumer(
                            builder: (context, tileRef, _) {
                              final progress = tileRef
                                  .watch(goalTodayProgressProvider(g.id))
                                  .valueOrNull;
                              return _TodayGoalTile(
                                title: g.title,
                                subtitle: _homeGoalSubtitle(g),
                                onTap: () {
                                  if (progress == null) {
                                    Navigator.pushNamed(
                                      context,
                                      GoalDetailScreen.routeName,
                                      arguments: g.id,
                                    );
                                    return;
                                  }
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => GoalCounterSheet(
                                      goal: g,
                                      initialProgress: progress,
                                    ),
                                  ).then(
                                    (_) => tileRef.invalidate(
                                      goalTodayProgressProvider(g.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        if (remaining > 0)
                          _HomeSectionSeeMoreLink(
                            label: remaining == 1
                                ? '1 more goal'
                                : '$remaining more goals',
                            onTap: () => navigateToMainTab(
                              context,
                              ref,
                              index: MainTabIndex.goals,
                            ),
                          ),
                        // Direct goal creation stays visible even with
                        // goals listed (2026-08-25) — it used to appear
                        // only in the empty state.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _createGoalLink(context),
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
                  error: (e, _) => swallowedAsyncError(
                    'home_screen',
                    e,
                    Text(
                      'Could not load goals.',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // COACHING INSIGHTS card removed (2026-08-23): it restated the
          // hero card's numbers — Progress is the analytics surface.
          tasksAsync.when(
            data: (rows) {
              final completed = _completedForRows(rows, scores);
              final partial = _partialForRows(rows, scores);
              return Text(
                'Completed: $completed • Partial: $partial',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              );
            },
            loading: () => Text(
              'Completed: … • Partial: …',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            error: (Object? error, StackTrace? stackTrace) =>
                const SizedBox.shrink(),
          ),
          // Routine sync is silent — no "syncing"/"all synced" status line during
          // normal operation. Only surface when the write queue is stuck and the
          // user should know their changes haven't reached the cloud.
          ValueListenableBuilder<bool>(
            valueListenable: SyncService.instance.hasSyncIssue,
            builder: (context, hasIssue, _) {
              if (!hasIssue) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Some changes haven’t synced yet. They’ll retry '
                  'automatically when you’re back online.',
                  style: TextStyle(color: AppColors.amber),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Date key the morning brief was last scheduled for. Guards the build-phase
/// trigger below: without it, every home rebuild during the morning window
/// queues another post-frame callback and another snackbar.
String? _morningBriefShownForDateKey;

/// Shows a one-time morning brief snackbar when the feature is enabled.
void _maybeTriggerMorningBrief(BuildContext context, WidgetRef ref) {
  final now = DateTime.now();
  final isMorningWindow = now.hour >= 6 && now.hour < 10;
  if (!isMorningWindow) return;

  final todayKey = DateKeys.todayKey();
  if (_morningBriefShownForDateKey == todayKey) return;

  final coachOpenedToday = ref.read(coachLastOpenedDateKeyProvider);
  if (coachOpenedToday == todayKey) return;

  // Check preference asynchronously — best-effort, no blocking
  final prefAsync = ref.read(userProfilePreferenceStreamProvider);
  final morningBriefEnabled =
      prefAsync.whenOrNull(data: (p) => p?.morningBriefEnabled) ?? false;
  if (!morningBriefEnabled) return;

  _morningBriefShownForDateKey = todayKey;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.inkWarm,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Suggestions for today are ready — tap to review.',
          style: TextStyle(color: AppColors.fg),
        ),
        action: SnackBarAction(
          label: 'Open',
          textColor: AppColors.accentDim,
          // Suggestions live on the Progress DAY view now (2026-09-22).
          onPressed: () {
            ref
                .read(progressSelectionProvider.notifier)
                .setHorizon(ProgressHorizon.day);
            Navigator.of(context).pushNamed(AnalyticsProgressScreen.routeName);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  });
}

class _HomeTopAnalyticsCard extends ConsumerStatefulWidget {
  const _HomeTopAnalyticsCard({super.key});

  @override
  ConsumerState<_HomeTopAnalyticsCard> createState() =>
      _HomeTopAnalyticsCardState();
}

class _HomeTopAnalyticsCardState extends ConsumerState<_HomeTopAnalyticsCard>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _introCurve;
  late final Animation<double> _sparklineCurve;

  bool _introPlayed = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _introCurve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _sparklineCurve = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  /// One intro sweep per Home visit: the ring fills and the bars grow.
  void _playIntroOnce() {
    if (_introPlayed) return;
    _introPlayed = true;
    _introController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(analyticsPeriodBundleProvider);
    // Redesign 2026-09-14: one white dashboard card — today's ring | this
    // week's bars — instead of the stacked orange pill + sparkline. The
    // day-streak column came out in the plain-language pass (2026-09-25):
    // testers read it as a score they were losing, not progress.
    return AppCard(
      color: AppColors.homeHeroCard,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      onTap: () =>
          Navigator.pushNamed(context, AnalyticsProgressScreen.routeName),
      child: bundleAsync.when(
        skipLoadingOnReload: true,
        data: (bundle) {
          // Goals and habits that are ACTIVE AND DUE today (action days
          // only, plus habit tasks) — not every goal on the Goals tab. The
          // ring is the weighted rate, so partial progress shows; the
          // sub-line counts only fully completed items.
          final day = bundle.goalHabitDay;
          final rate = day.weightedCompletionRate.clamp(0.0, 1.0);
          final scorePercent = (rate * 100).round();
          _playIntroOnce();
          return AnimatedBuilder(
            animation: _introController,
            builder: (context, _) {
              final animating = _introController.isAnimating;
              final introValue = animating ? _introCurve.value : 1.0;
              final barsProgress = animating ? _sparklineCurve.value : 1.0;
              return _HeroDashboard(
                ringValue: rate * introValue,
                percent: (scorePercent * introValue).round(),
                completed: day.completedCount,
                total: day.createdCount,
                weekValues: bundle.blendedWeekSeries,
                barsProgress: barsProgress,
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (e, _) => swallowedAsyncError(
          'home_screen',
          e,
          const _HeroDashboard(
            ringValue: 0,
            percent: 0,
            completed: 0,
            total: 0,
            weekValues: [],
            barsProgress: 1,
          ),
        ),
      ),
    );
  }
}

/// The two dashboard columns — today's ring and this week's bars. On wide
/// phones they sit side by side with a hairline divider; under
/// [_kWideDashboard] the trend drops to its own full-width row so nothing
/// gets cramped.
class _HeroDashboard extends StatelessWidget {
  const _HeroDashboard({
    required this.ringValue,
    required this.percent,
    required this.completed,
    required this.total,
    required this.weekValues,
    required this.barsProgress,
  });

  final double ringValue;
  final int percent;
  final int completed;
  final int total;
  final List<double> weekValues;
  final double barsProgress;

  /// Inner card width (screen − 20 page pad − 20 card pad, each side) at
  /// which the columns sit side by side. Was 330, which only Plus / Pro
  /// Max phones (430 pt → 350) reached: an iPhone 16 (393 → 313) and even
  /// a 16 Pro (402 → 322) got the stacked layout with the bigger ring and
  /// the trend on its own row, so the card looked "bigger" there (Miko,
  /// 2026-09-24). At 300 every current iPhone but the 320-pt SE gets the
  /// row. With two columns (2026-09-25) the ring takes 5/11 of the width
  /// (~140 pt at 313) and the trend 6/11 (~170 pt, ~24 pt per bar cell).
  static const double _kWideDashboard = 300;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideDashboard;
        final ring = _ProgressRingColumn(
          value: ringValue,
          percent: percent,
          completed: completed,
          total: total,
          diameter: wide ? 104 : 116,
        );
        final trend = _WeekTrend(
          values: weekValues,
          drawProgress: barsProgress,
          compact: wide,
        );
        if (wide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: ring),
                const _HeroDivider(),
                Expanded(flex: 6, child: trend),
              ],
            ),
          );
        }
        return Column(
          children: [
            ring,
            const SizedBox(height: 18),
            Divider(height: 1, thickness: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            trend,
          ],
        );
      },
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: AppColors.divider,
    );
  }
}

class _ProgressRingColumn extends StatelessWidget {
  const _ProgressRingColumn({
    required this.value,
    required this.percent,
    required this.completed,
    required this.total,
    required this.diameter,
  });

  final double value;
  final int percent;
  final int completed;
  final int total;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              value: value.clamp(0.0, 1.0),
              track: AppColors.surfaceLight,
              fill: AppColors.accent,
              strokeWidth: diameter * 0.095,
            ),
            child: Center(
              child: Text(
                '$percent%',
                // One px under the scaled size (Miko, 2026-09-15): "100%"
                // sat a touch too close to the ring.
                style: TextStyle(
                  fontSize: diameter * 0.28 - 1,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Today's progress",
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const HelpDot('todaysProgress', dense: true),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$completed of $total goals/habits completed',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.25,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Open-bottom arc: a 270° sweep starting at the lower-left so the gap sits
/// centred under the percentage.
class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Color fill;
  final double strokeWidth;

  static const double _start = 135 * math.pi / 180;
  static const double _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(rect, _start, _sweep * value, false, base..color = fill);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}

/// Seven rounded bars, Monday → Sunday. [values] runs Monday → today, so
/// bars after it are the future: short hollow stubs, visibly different from
/// a past day that scored zero (a short filled stub). Today is teal.
class _WeekTrend extends StatelessWidget {
  const _WeekTrend({
    required this.values,
    required this.drawProgress,
    required this.compact,
  });

  final List<double> values;
  final double drawProgress;
  final bool compact;

  static const _labels = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final maxHeight = compact ? 64.0 : 72.0;
    // Two-column layout (2026-09-25): the trend column is ~170 pt wide on
    // a 393-pt phone, so the compact bars can be 10 pt instead of 8.
    final barWidth = compact ? 10.0 : 12.0;
    // Defensive: the series is 1–7 entries; anything longer is clipped to
    // the last seven so today stays the last bar.
    final series = values.length > 7
        ? values.sublist(values.length - 7)
        : values;
    final todayIndex = series.isEmpty ? -1 : series.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'This week so far',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        SizedBox(
          height: maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: _TrendBar(
                      value: i < series.length
                          ? series[i].clamp(0.0, 1.0) * drawProgress
                          : null,
                      isToday: i == todayIndex,
                      maxHeight: maxHeight,
                      width: barWidth,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // 10 in the compact column: each of the seven cells is
                    // ~24 pt on a 393-pt phone since the streak column went.
                    fontSize: compact ? 10 : 11.5,
                    fontWeight: i == todayIndex
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i == todayIndex
                        ? AppColors.coach
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.isToday,
    required this.maxHeight,
    required this.width,
  });

  /// Null = a future day.
  final double? value;
  final bool isToday;
  final double maxHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width / 2);
    final v = value;
    // Future days, and past days that scored nothing, are hollow: a solid
    // minimum stub read as "something happened" on days with zero tasks
    // (QA, 2026-09-23). Today stays solid at zero — it is in progress.
    if (v == null || (v <= 0 && !isToday)) {
      return Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
      );
    }
    final minStub = isToday ? width * 1.25 : width;
    final height = math.max(minStub, maxHeight * v);
    // Past days are the same teal as today, just softer — the slate grey
    // they used to wear read as "unselected", as if six of the seven days
    // were disabled (Miko, 2026-09-18). Today alone is full strength.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: isToday
            ? AppColors.coach
            : AppColors.coach.withValues(alpha: 0.42),
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
      skipLoadingOnReload: true,
      data: (bundle) => _DisciplineHeading(
        value: bundle.goalHabitWeek.weightedCompletionRate.clamp(0.0, 1.0),
      ),
      loading: () => const _DisciplineHeading(value: null),
      error: (e, _) => swallowedAsyncError(
        'home_screen',
        e,
        const _DisciplineHeading(value: null),
      ),
    );
  }
}

/// "WEEKLY DISCIPLINE 42%" — bold heading, the percentage a shade lighter,
/// olive bar under it. [value] null = not loaded yet (no number, empty bar).
class _DisciplineHeading extends StatelessWidget {
  const _DisciplineHeading({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      height: 1.1,
      color: AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                'WEEKLY DISCIPLINE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headingStyle,
              ),
            ),
            if (v != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(v * 100).round()}%',
                style: headingStyle.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: v ?? 0,
            minHeight: 8,
            color: AppColors.accent,
            backgroundColor: AppColors.surfaceLight,
          ),
        ),
      ],
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
  String? _lastScheduledPrimaryInsightId;
  String? _dispatchInFlightForInsightId;
  String? _focusDispatchInFlightForFocusId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Layer4NotificationDecisionViewModel>>(
      layer4TodayNotificationDecisionProvider,
      (previous, next) {
        unawaited(_onNotificationDecisionChanged(next));
      },
    );
    // New-focus push (2026-08-23): the focus card left Home, so a freshly
    // selected focus announces itself once — then waits on Progress behind
    // the Profile-tab dot. Fires only when focusId changes, never on
    // recomputes that keep the same focus.
    ref.listen<AsyncValue<CurrentCoachingFocus?>>(
      currentCoachingFocusProvider,
      (previous, next) {
        unawaited(_onCoachingFocusChanged(next));
      },
    );
    return const SizedBox.shrink();
  }

  Future<void> _onCoachingFocusChanged(
    AsyncValue<CurrentCoachingFocus?> next,
  ) async {
    final focus = next.valueOrNull;
    if (focus == null || !isFocusLive(focus.lifecycleState)) return;
    final focusId = focus.focusId;
    if (focusId.isEmpty || _focusDispatchInFlightForFocusId == focusId) return;

    // EVERY ref.read happens before the first await (2026-08-26): this
    // bridge outlives its awaits only sometimes — `ref` after the widget's
    // disposal threw an uncaught "Cannot use ref" at boot.
    final prefService = ref.read(profilePreferenceServiceProvider);
    final notifications = ref.read(localNotificationsServiceProvider);
    final orchestrator = ref.read(attentionOrchestratorServiceProvider);
    final announcedStore = ref.read(announcedInsightStoreProvider);
    final insights =
        ref.read(layer3TodayDeliveryInsightsProvider).valueOrNull ??
        const <GeneratedInsight>[];
    final pref = await prefService.getPreference();
    if (pref.lastNotifiedCoachingFocusId == focusId) return;

    // Same delivery window and shared 3/day budget as insight pushes —
    // the two coaching producers must never stack past the budget.
    final hour = DateTime.now().hour;
    if (hour < 8 || hour >= 21) return;
    final budget = await prefService.evaluateCoachingInsightNotificationSend();
    if (!budget.allowed) return;

    _focusDispatchInFlightForFocusId = focusId;
    try {
      final selected = insights
          .where((item) => item.insightId == focus.primaryInsightId)
          .toList();
      final body = selected.isEmpty
          ? 'Your coach picked a new focus — open Progress to see it.'
          : selected.first.message;

      final granted = await notifications.requestPermissionsIfNeeded();
      if (!granted) return;

      final budgetAfter = await prefService
          .evaluateCoachingInsightNotificationSend();
      if (!budgetAfter.allowed) return;

      // Routed through the AttentionOrchestrator (Phase 0 single-brain
      // rule). entityId is the primary insight so the tap lands on
      // Progress via the existing `layer4:` route.
      final decision = await orchestrator.evaluate(
        ReminderIntent(
          id: StableId.generate('ri_coach_focus'),
          entityId: focus.primaryInsightId,
          entityKind: ReminderEntityKinds.coachInsight,
          entityTitle: 'New coaching focus',
          proposedAt: DateTime.now().add(const Duration(minutes: 1)),
          importance: 55,
          interruptionLevel: InterruptionLevel.low,
          enforcementMode: 'flexible',
          sourceReason: 'coaching_focus_selected',
          bodyOverride: body,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (decision.outcome != AttentionOutcome.suppressed) {
        await prefService.recordCoachingInsightNotificationSent();
        // Same frozen-copy rule as insight pushes: the tap must be
        // honorable after a recompute replaces the advertised insight.
        if (selected.isNotEmpty) {
          await announcedStore.save(
            AnnouncedInsight(
              insightId: focus.primaryInsightId,
              message: selected.first.message,
              caption: coachingDetailCaption(selected.first) ?? '',
              dateKey: DateKeys.todayKey(),
            ),
          );
        }
      }
      // Either way this focus is handled — a suppressed intent retries via
      // the orchestrator's own queue, not by re-dispatching here.
      await prefService.markCoachingFocusNotified(focusId);
    } finally {
      if (_focusDispatchInFlightForFocusId == focusId) {
        _focusDispatchInFlightForFocusId = null;
      }
    }
  }

  Future<void> _onNotificationDecisionChanged(
    AsyncValue<Layer4NotificationDecisionViewModel> next,
  ) async {
    final vm = next.valueOrNull;
    if (vm == null) return;

    // EVERY ref.read happens before the first await (2026-08-26): the
    // store read after `notifications.cancel` threw an uncaught
    // "Cannot use ref after the widget was disposed" at boot.
    final notifications = ref.read(localNotificationsServiceProvider);
    final prefService = ref.read(profilePreferenceServiceProvider);
    final orchestrator = ref.read(attentionOrchestratorServiceProvider);
    final announcedStore = ref.read(announcedInsightStoreProvider);
    final insights =
        ref.read(layer3TodayDeliveryInsightsProvider).valueOrNull ??
        const <GeneratedInsight>[];
    final primaryId = vm.primaryInsightId?.trim();

    if (!vm.isEligible || primaryId == null || primaryId.isEmpty) {
      await notifications.cancel(kCoachingInsightNotificationId);
      // No banner, no promise — drop the frozen copy too.
      await announcedStore.clear();
      _lastScheduledPrimaryInsightId = null;
      _dispatchInFlightForInsightId = null;
      return;
    }

    if (_lastScheduledPrimaryInsightId == primaryId ||
        _dispatchInFlightForInsightId == primaryId) {
      return;
    }

    final budget = await prefService.evaluateCoachingInsightNotificationSend();
    if (!budget.allowed) {
      return;
    }

    // Delivery window (Layer_four.md): coaching may only banner during
    // waking hours. Outside 08–21 the insight stays on the Home card and
    // this bridge re-fires on the next in-window decision change.
    final hour = DateTime.now().hour;
    if (hour < 8 || hour >= 21) {
      return;
    }

    _dispatchInFlightForInsightId = primaryId;
    try {
      final selected = insights
          .where((item) => item.insightId == primaryId)
          .toList();
      final body = selected.isEmpty
          ? 'You have a coaching insight ready.'
          : selected.first.message;

      final granted = await notifications.requestPermissionsIfNeeded();
      if (!granted) return;

      // Re-check budget in case another dispatch completed while awaiting permission.
      final budgetAfter = await prefService
          .evaluateCoachingInsightNotificationSend();
      if (!budgetAfter.allowed) return;

      // V-01: this producer keeps its own 3/day + 4h budget, but the send
      // itself goes through the AttentionOrchestrator — a coach insight
      // must never banner into a context override, a coaching-focus
      // silence, or a collision window, and it must land in the ledger
      // like every other surface (Phase 0 single-brain rule).
      final decision = await orchestrator.evaluate(
        ReminderIntent(
          id: StableId.generate('ri_coach_insight'),
          entityId: primaryId,
          entityKind: ReminderEntityKinds.coachInsight,
          entityTitle: 'Coach Insight Ready',
          proposedAt: DateTime.now().add(const Duration(minutes: 1)),
          importance: 55,
          interruptionLevel: InterruptionLevel.low,
          enforcementMode: 'flexible',
          sourceReason: 'layer4_insight_ready',
          bodyOverride: body,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (decision.outcome != AttentionOutcome.suppressed) {
        // Count against the producer budget only when something was
        // actually scheduled; a suppressed intent retries via the
        // orchestrator's own queue.
        await prefService.recordCoachingInsightNotificationSent();
        // Freeze the bannered copy: recomputes wholesale-replace today's
        // insights, so the tap must be honored from this snapshot when
        // the live id no longer resolves.
        if (selected.isNotEmpty) {
          await announcedStore.save(
            AnnouncedInsight(
              insightId: primaryId,
              message: selected.first.message,
              caption: coachingDetailCaption(selected.first) ?? '',
              dateKey: DateKeys.todayKey(),
            ),
          );
        }
      }
      _lastScheduledPrimaryInsightId = primaryId;
    } finally {
      if (_dispatchInFlightForInsightId == primaryId) {
        _dispatchInFlightForInsightId = null;
      }
    }
  }
}

/// Quick-action tile (redesign 2026-09-14): icon over a sentence-case label
/// inside one rounded rectangle. Exactly one tile is [active] — filled
/// olive with a stronger shadow — so the primary action reads at a glance
/// without the other three looking disabled.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tileColor = active
        ? AppColors.actionTileActive
        : AppColors.actionTile;
    final glyphColor = active
        ? AppColors.onActionTileActive
        : AppColors.onActionTile;
    final radius = BorderRadius.circular(22);
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: radius,
          boxShadow: active ? appPrimaryShadow : appCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              height: 92,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: glyphColor, size: 26),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: glyphColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Flow now: one status line + slim next-task row (~72px vs ~140px).
class _FlowNowStrip extends ConsumerWidget {
  const _FlowNowStrip({required this.flowSnapshotAsync});

  final AsyncValue<HomeFlowSnapshot> flowSnapshotAsync;

  static Color get _kAccent => AppColors.cyan;
  static Color get _kMuted => AppColors.textSoft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionControllerProvider);
    final todayRows =
        ref.watch(todayAllTasksRowsProvider).valueOrNull ?? const [];

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
        error: (e, _) => swallowedAsyncError(
          'home_screen',
          e,
          Text(
            'Unavailable',
            style: TextStyle(color: _kMuted, fontSize: 12),
          ),
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
    ref
        .read(executionControllerProvider.notifier)
        .setTask(
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
    final isThisTask =
        execState.targetType == TimerSessionTargetType.task &&
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
          ref
              .read(reminderSyncServiceProvider)
              .markTaskStarted(
                task.id,
                sessionLength: task.durationMinutes > 0
                    ? Duration(minutes: task.durationMinutes)
                    : null,
              ),
        );
      }
      return;
    }

    final otherRunning =
        execState.targetType == TimerSessionTargetType.task &&
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
    unawaited(
      ref
          .read(reminderSyncServiceProvider)
          .markTaskStarted(
            task.id,
            sessionLength: task.durationMinutes > 0
                ? Duration(minutes: task.durationMinutes)
                : null,
          ),
    );
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

    final focusActive =
        execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty &&
        (execState.phase == ExecutionPhase.inProgress ||
            execState.phase == ExecutionPhase.paused);

    final displayTask = focusActive
        ? (_findTask(todayRows, execState.taskId) ?? next)
        : next;
    final isThisFocus =
        focusActive &&
        displayTask != null &&
        execState.taskId == displayTask.id;
    // Plain-language pass (2026-09-25): the strip's label carries the
    // state — IN FOCUS / PAUSED / UP NEXT — so the task row's second line no
    // longer repeats it.
    final stripLabel = !isThisFocus
        ? 'UP NEXT'
        : (execState.phase == ExecutionPhase.paused ? 'PAUSED' : 'IN FOCUS');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              stripLabel,
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
                style: TextStyle(
                  color: AppColors.fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const HelpDot('flowNow'),
          ],
        ),
        if (displayTask != null) ...[
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      onTap: () => _openTimerScreen(context, ref, displayTask),
                      borderRadius: BorderRadius.circular(8),
                      // Two lines matching the 36px button height: title on
                      // top, status + timer merged below — keeps the row slim.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isThisFocus
                                ? execState.taskLabel
                                : displayTask.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.fg,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _FlowNowStrip._subtitleFor(
                              task: displayTask,
                              execState: execState,
                              focusActive: isThisFocus,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.fg, fontSize: 11),
                          ),
                        ],
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
                    icon: Icon(Icons.chevron_right, color: _kMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ] else
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Nothing planned — add a task or check Tasks.',
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
      final targetMin = execState.targetDurationMinutes ?? task.durationMinutes;
      parts.add('${_formatElapsed(execState.elapsed)} / ${targetMin}m');
    } else {
      parts.add('${task.durationMinutes}m target');
    }
    final timeLabel = taskScheduledTimeLabelForDisplay(task);
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

  static Color get _kAccent => AppColors.cyan;

  @override
  Widget build(BuildContext context) {
    final isThisTask =
        execState.targetType == TimerSessionTargetType.task &&
        execState.taskId == task.id;
    final running = isThisTask && execState.phase == ExecutionPhase.inProgress;
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
                  backgroundColor: AppColors.fg12,
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
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
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

/// "+ Create a task" link at the bottom of the Today's Tasks card
/// (2026-08-25) — same shape as the goals card's "Create a goal".
Widget _createTaskLink(BuildContext context) {
  return TextButton.icon(
    onPressed: () => showAddTaskSheet(context),
    icon: Icon(Icons.add, size: 20, color: AppColors.accent),
    label: const Text('Create a task'),
    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
  );
}

/// "+ Create a goal" — always visible at the bottom of the Today's goals
/// card (2026-08-25; it used to exist only in the empty state).
Widget _createGoalLink(BuildContext context) {
  return TextButton.icon(
    onPressed: () =>
        Navigator.pushNamed(context, GoalTemplatePickerScreen.routeName),
    icon: Icon(Icons.add, size: 20, color: AppColors.accent),
    label: const Text('Create a goal'),
    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
  );
}

class _HomeSectionSeeMoreLink extends StatelessWidget {
  const _HomeSectionSeeMoreLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
            Icon(
              Icons.track_changes_outlined,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.fg24, size: 20),
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
  final suffix = switch (g.horizon) {
    GoalHorizon.weekly => 'this week',
    GoalHorizon.monthly => 'this month',
    GoalHorizon.daily => 'per day',
    GoalHorizon.entireGoal => 'entire goal',
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
    this.onTap,
    this.checkboxKey,
  });

  final Key? checkboxKey;
  final String title;
  final String? subtitle;
  final bool done;
  final bool partial;
  final void Function(bool checked) onCheckedChange;
  final VoidCallback onPlansChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Transparent Material so the tap ripple renders above the decorated
    // card behind this tile (otherwise Flutter warns splashes may be
    // invisible on every build).
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(
          key: checkboxKey,
          value: done,
          onChanged: (value) {
            if (value == null) return;
            onCheckedChange(value);
          },
          activeColor: AppColors.accent,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            fontStyle: partial ? FontStyle.italic : FontStyle.normal,
            color: AppColors.fg70,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
        trailing: IconButton(
          tooltip: 'Plans Changed?',
          icon: Icon(Icons.swap_horiz, color: AppColors.fg54),
          onPressed: onPlansChanged,
        ),
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
          // The filled-button theme is the lime primary; keep this one soft.
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.fg12,
            foregroundColor: AppColors.fg,
          ),
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.skip),
          child: const Text('Skip'),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;

  final reason = await promptOverrideReason(context);
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

  // migrated to coordinator
  await ScheduleMutationCoordinator.instance.run(
    TaskDeferredMutation(
      entityId: t.id,
      sourceContext: 'home_screen.skip_task',
      fromDateStr: t.planDateKey ?? DateKeys.todayKey(),
      toDateStr: DateKeys.todayKey(),
    ),
    commitOverride: () async {},
  );
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
            Text(
              'Type CONFIRM to proceed.',
              style: TextStyle(color: AppColors.fg70),
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

class _SyncFromCloudAction extends StatefulWidget {
  const _SyncFromCloudAction();

  @override
  State<_SyncFromCloudAction> createState() => _SyncFromCloudActionState();
}

class _SyncFromCloudActionState extends State<_SyncFromCloudAction> {
  // Tracks only the sync THIS button started. Routine background syncs are
  // deliberately ignored here so they produce no spinner and no snackbar —
  // feedback is reserved for the pull the user explicitly asked for.
  bool _userSyncing = false;

  Future<void> _syncFromCloud() async {
    if (_userSyncing) return;
    setState(() => _userSyncing = true);
    var ok = false;
    try {
      // Light path: what's new since the cursors, capped at 20 s — not the
      // minute-long full reconcile (2026-09-19). Sign-in owns that one.
      ok = await SyncService.instance.syncFromRemote(
        bypassThrottle: true,
        timeout: const Duration(seconds: 20),
      );
    } finally {
      if (mounted) setState(() => _userSyncing = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Updated from cloud' : 'Could not sync. Try again.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCircleIconButton(
      icon: Icons.sync_rounded,
      tooltip: _userSyncing ? 'Syncing from cloud' : 'Sync from cloud',
      onPressed: _userSyncing ? null : () => unawaited(_syncFromCloud()),
      child: _userSyncing
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            )
          : null,
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
  } catch (e) {
    debugPrint('home_screen: swallowed error: $e');
  }
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
  final mode = EffectiveTaskMode.effectiveModeRefId(
    task: t,
    routine: routineForPolicy,
  );
  // The mandatory-timer gate only applies to extreme (and explicitly
  // strict-required) tasks on Home; disciplined tasks go straight to the
  // rating card so the checkbox stays low-friction.
  if (mode == 'extreme' || t.strictModeRequired) {
    // A failed fetch (offline, rules, missing index) must not kill the
    // completion flow — treat it as "no sessions" so the timer-required
    // dialog still appears and the policy stays enforced.
    List<TimerSession> sessions = const [];
    try {
      sessions = await ref
          .read(executionRepositoryProvider)
          .getSessionsForTask(t.id);
    } catch (e) {
      debugPrint('completeTaskFromHome: session fetch failed: $e');
    }
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
  if (!context.mounted) return;
  // Ask for the completion rate — same score dialog the focus/timer flow
  // uses, with the discipline-mode contract:
  // flexible → dismissing the card (tap outside / back) accepts the default,
  //   done at 100% (mis-taps are recoverable by unchecking the checkbox);
  // disciplined → must submit a score (reason below 100%);
  // extreme → must submit a score and a reason at any percentage.
  final scoreResult =
      await ScoreTaskDialog.show(
        context,
        taskTitle: t.title,
        requireSubmit: mode == 'disciplined' || mode == 'extreme',
        requireReasonAlways: mode == 'extreme',
        reasonThresholdPercent: ScoreTaskDialog.reasonThresholdForMode(mode),
      ) ??
      const ScoreTaskDialogResult(completionPercent: 100, reason: null);
  if (!context.mounted) return;
  final completionPercent = scoreResult.completionPercent;
  final isComplete = completionPercent >= 100;

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
    status: isComplete ? TaskStatus.completed : TaskStatus.partial,
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
      type: isComplete
          ? AnalyticsEventType.taskCompleted
          : AnalyticsEventType.taskDeferred,
      entityId: t.id,
      entityKind: 'task',
      sourceSurface: 'home',
      idempotencyKey:
          '${isComplete ? 'task_completed' : 'task_deferred'}_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
      reason: scoreResult.reason,
      modeRefId: t.modeRefId,
    );
    // R2.2 missed this site: Home's check-in called markTaskStarted even on
    // completion, leaving the day's occurrence open on the Recovery Card.
    // Partial keeps markTaskStarted deliberately — the task is genuinely
    // unfinished, and Active stops the ladder while staying visible.
    if (isComplete) {
      await ref.read(reminderSyncServiceProvider).markTaskCompleted(t.id);
    } else {
      await ref.read(reminderSyncServiceProvider).markTaskStarted(t.id);
    }
    await ref
        .read(scoringControllerProvider)
        .submit(
          taskId: t.id,
          completionPercent: completionPercent,
          reason: scoreResult.reason,
        );
    final prev = ref.read(scoredTaskStatusesProvider);
    ref.read(scoredTaskStatusesProvider.notifier).state = {
      ...prev,
      t.id: completionPercent,
    };
    // migrated to coordinator
    await ScheduleMutationCoordinator.instance.run(
      isComplete
          ? TaskCompletedMutation(
              entityId: t.id,
              sourceContext: 'home_screen.complete_task',
              dateStr: t.planDateKey ?? DateKeys.todayKey(),
            )
          : TaskUpdatedMutation(
              entityId: t.id,
              sourceContext: 'home_screen.complete_task',
              dateStr: t.planDateKey ?? DateKeys.todayKey(),
            ),
      commitOverride: () async {},
    );
    if (!context.mounted) return;
    invalidateTaskListProviders(ref);
    // Only a full completion suggests the next task. On Home the suggestion is
    // dismissible (tap outside stays on Home) and never auto-opens Focus.
    if (isComplete) {
      await runAutoNextTaskFlow(
        context,
        ref,
        completedTaskId: t.id,
        completionPercent: completionPercent,
        fromHome: true,
      );
    }
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
    // migrated to coordinator
    await ScheduleMutationCoordinator.instance.run(
      TaskUpdatedMutation(
        entityId: t.id,
        sourceContext: 'home_screen.undo_completion',
        dateStr: t.planDateKey ?? DateKeys.todayKey(),
      ),
      commitOverride: () async {},
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update task: $e')));
    }
  }
}
