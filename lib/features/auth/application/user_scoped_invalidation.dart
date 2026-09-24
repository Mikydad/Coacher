import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/session/session_scope.dart';
import '../../accountability/application/points_providers.dart';
import '../../accountability/application/stake_create_replicator.dart';
import '../../ai_assistant/application/ai_assistant_providers.dart';
import '../../ai_assistant/application/quick_directives_provider.dart';
import '../../analytics/application/announced_insight_store.dart';
import '../../community/application/circle_providers.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../direction/application/direction_providers.dart';
import '../../direction/application/new_month_prompt.dart';
import '../../time_tracker/application/time_tracker_providers.dart';
import '../../education/application/getting_started_controller.dart';
import '../../goals/application/goals_providers.dart';
import '../../plan_tomorrow/application/plan_tomorrow_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../reminders/application/attention_orchestrator_providers.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../ui_state/ui_state_providers.dart';
import '../../../app/application/main_tab_navigation.dart';

/// Clears all per-user, in-memory Riverpod state so no data survives a
/// logout or an account switch within the same app session.
///
/// Firestore-backed providers re-scope automatically when the uid changes
/// (via [firestoreClientProvider]) and Isar-backed providers are cleared by
/// [AuthSessionPolicy.clearLocalSession]. This helper covers the remaining
/// non-`autoDispose` providers that hold user data directly in memory and
/// would otherwise leak from User A into User B's session.
///
/// Called from **both** transition points:
///   * logout (`profile_screen._signOut`)
///   * uid-change sign-in (`AuthGate._onAuthStateChanged`)
///
/// Auth-control providers (e.g. `pendingAuthLandingProvider`, `authStateProvider`)
/// are intentionally **not** invalidated here.
///
/// Also begins the [SessionScope] teardown synchronously (audit H2–H6), so
/// any job that captured a session token before this call drops its result
/// instead of persisting into the next account's store.
void invalidateUserScopedProviders(WidgetRef ref) {
  SessionScope.beginTeardown();
  for (final provider in userScopedProviders) {
    ref.invalidate(provider);
  }
}

/// Same reset, driven from a [ProviderContainer] — for coordinators whose
/// lifetime is independent of any widget (account deletion, H14).
void invalidateUserScopedProvidersIn(ProviderContainer container) {
  SessionScope.beginTeardown();
  for (final provider in userScopedProviders) {
    container.invalidate(provider);
  }
}

/// The hand-maintained list. Post-launch this is retired by the guarded
/// write funnel + per-uid Isar (fix plan Batch B follow-up); until then
/// EVERY non-autoDispose provider that holds per-account state belongs here.
List<ProviderOrFamily> get userScopedProviders => [
  // ── Community (circle) state ──────────────────────────────────────────────
  ...circleScopedProviders,
  circleActiveTabProvider,

  // ── AI assistant — most privacy-sensitive (in-memory conversation) ─────────
  // Invalidating the family clears every cached service instance, dropping the
  // in-memory message list that the Coach screen renders directly.
  aiAssistantServiceProvider,
  coachLastOpenedDateKeyProvider,
  quickDirectivesProvider,

  // ── Execution / timer state ────────────────────────────────────────────────
  executionControllerProvider,
  activeExecutionTaskIdProvider,
  activeExecutionTaskLabelProvider,

  // ── Scoring ────────────────────────────────────────────────────────────────
  scoredTaskStatusesProvider,

  // ── Reminder / attention orchestration ──────────────────────────────────────
  suppressedIntentQueueProvider,
  recentDeliveriesProvider,

  // ── Context override ─────────────────────────────────────────────────────────
  pendingRecoveryReviewProvider,

  // ── Direction ────────────────────────────────────────────────────────────
  // The month-card controller caches its prefs flag in memory; the wipe
  // removes the key, so the controller must reload (and re-seed) for the
  // new account, and the clock re-stamps so periods resolve fresh.
  newMonthPromptControllerProvider,
  directionClockProvider,

  // ── Time Tracker ─────────────────────────────────────────────────────────
  timelineDayKeyProvider,
  timelineModeProvider,
  timelineWeekKeyProvider,

  // ── Plan Tomorrow (audit H5): one-shot reads of routines/tasks ───────────
  tomorrowRoutineSlotsProvider,
  tomorrowTasksForRoutineProvider,

  // ── Accountability (audit H6/M5) ─────────────────────────────────────────
  stakeCreateReplicatorProvider,
  pointsBalanceProvider,

  // ── Analytics / profile (audit H4/L1) ────────────────────────────────────
  announcedInsightTodayProvider,
  totalCompletionsCountProvider,

  // ── Education / onboarding ───────────────────────────────────────────────
  // The Getting Started controller decides new-vs-existing ONCE per
  // instance; without this, User A's 'hidden' controller survives in memory
  // and User B (a brand-new account) never gets onboarding. The provider
  // also watches the uid itself and its probe waits for the wipe to end
  // (SessionScope.whenIdle), so the rebuild this triggers cannot judge B by
  // A's rows.
  gettingStartedControllerProvider,

  // ── Ephemeral UI / navigation state ──────────────────────────────────────────
  selectedTaskProvider,
  timerRunningProvider,
  timerDisplayProvider,
  selectedGoalCategoryFilterProvider,
  mainTabIndexProvider,
  coachTabArgsProvider,
];
