import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../ai_assistant/application/ai_assistant_providers.dart';
import '../../community/application/circle_providers.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../direction/application/direction_providers.dart';
import '../../direction/application/new_month_prompt.dart';
import '../../time_tracker/application/time_tracker_providers.dart';
import '../../education/application/getting_started_controller.dart';
import '../../goals/application/goals_providers.dart';
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
void invalidateUserScopedProviders(WidgetRef ref) {
  // ── Community (circle) state ──────────────────────────────────────────────
  invalidateCircleScopedProviders(ref);
  ref.invalidate(circleActiveTabProvider);

  // ── AI assistant — most privacy-sensitive (in-memory conversation) ─────────
  // Invalidating the family clears every cached service instance, dropping the
  // in-memory message list that the Coach screen renders directly.
  ref.invalidate(aiAssistantServiceProvider);
  ref.invalidate(coachLastOpenedDateKeyProvider);

  // ── Execution / timer state ────────────────────────────────────────────────
  ref.invalidate(executionControllerProvider);
  ref.invalidate(activeExecutionTaskIdProvider);
  ref.invalidate(activeExecutionTaskLabelProvider);

  // ── Scoring ────────────────────────────────────────────────────────────────
  ref.invalidate(scoredTaskStatusesProvider);

  // ── Reminder / attention orchestration ──────────────────────────────────────
  ref.invalidate(suppressedIntentQueueProvider);
  ref.invalidate(recentDeliveriesProvider);

  // ── Context override ─────────────────────────────────────────────────────────
  ref.invalidate(pendingRecoveryReviewProvider);

  // ── Direction ────────────────────────────────────────────────────────────
  // The month-card controller caches its prefs flag in memory; the wipe
  // removes the key, so the controller must reload (and re-seed) for the
  // new account, and the clock re-stamps so periods resolve fresh.
  ref.invalidate(newMonthPromptControllerProvider);
  ref.invalidate(directionClockProvider);

  // ── Time Tracker ─────────────────────────────────────────────────────────
  ref.invalidate(timelineDayKeyProvider);
  ref.invalidate(timelineModeProvider);
  ref.invalidate(timelineWeekKeyProvider);

  // ── Education / onboarding ───────────────────────────────────────────────
  // The Getting Started controller decides new-vs-existing ONCE per
  // instance; without this, User A's 'hidden' controller survives in memory
  // and User B (a brand-new account) never gets onboarding.
  ref.invalidate(gettingStartedControllerProvider);

  // ── Ephemeral UI / navigation state ──────────────────────────────────────────
  ref.invalidate(selectedTaskProvider);
  ref.invalidate(timerRunningProvider);
  ref.invalidate(timerDisplayProvider);
  ref.invalidate(selectedGoalCategoryFilterProvider);
  ref.invalidate(mainTabIndexProvider);
  ref.invalidate(coachTabArgsProvider);
}
