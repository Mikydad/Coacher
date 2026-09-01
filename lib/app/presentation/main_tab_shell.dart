import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/utils/stable_id.dart';
import '../../features/accountability/application/stakes_providers.dart';
import '../../features/accountability/domain/models/stake_challenge.dart';
import '../../features/accountability/presentation/accountability_hub_screen.dart';
import '../../features/analytics/application/focus_providers.dart';
import '../../features/auth/presentation/widgets/email_verification_banner.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/context_override/domain/models/interruption_level.dart';
import '../../features/goals/presentation/goal_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reminders/application/attention_orchestrator_providers.dart';
import '../../features/reminders/application/notification_route_resolver.dart';
import '../../features/reminders/domain/models/attention_outcome.dart';
import '../../features/reminders/domain/models/reminder_intent.dart';
import '../../core/presentation/cloud_sync_global_indicator.dart';
import '../application/main_tab_navigation.dart';
import 'main_tab_bar_inset.dart';
import 'obsidian_bottom_nav.dart';

/// Accountability's position in the tab row (badge + "View" jumps).
const int _kAccountabilityTabIndex = 2;

/// Profile's position in the tab row (unseen coaching-focus badge).
const int _kProfileTabIndex = 4;

/// Root shell: five primary tabs (Progress lives in Profile; Coach is
/// the omnipresent FAB + sheet) with a persistent watermark bottom nav.
class MainTabShell extends ConsumerWidget {
  const MainTabShell({super.key});

  static const routeName = '/';

  /// Invites already announced (or attempted) this app session — prevents
  /// snackbar/evaluate spam on every stream emission while a suppressed
  /// invite intentionally stays out of the persisted seen-list.
  static final Set<String> _sessionAnnounced = <String>{};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);
    final stakeActions = ref.watch(stakeActionsNeededProvider);
    // Unseen coaching focus (2026-08-23): the focus card lives on Progress
    // (inside Profile), so a fresh focus shows as a badge on the Profile
    // tab — same pattern as accountability's needs-action bubble.
    final unseenFocus = ref.watch(hasUnseenCoachingFocusProvider);

    // Announce challenge invites the moment sync lands them: one local
    // notification + in-app snackbar per invite, exactly once per device
    // (seen-set in prefs). The badge carries the persistent state.
    ref.listen<List<StakeChallenge>>(stakePendingInvitesProvider, (_, next) {
      _announceNewInvites(context, ref, next);
    });
    // Public commitment result cards (OQ-1): the moment sync lands a
    // terminal outcome, announce that the card is ready — once per
    // challenge, through the orchestrator like invites.
    ref.listen<AsyncValue<List<StakeChallenge>>>(
      stakeChallengesStreamProvider,
      (_, next) {
        final all = next.valueOrNull;
        if (all != null) _announceReadyCards(ref, all);
      },
    );

    return EmailVerificationBanner(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: index,
              children: const [
                MainTabInset(child: HomeScreen()),
                MainTabInset(child: GoalSelectionScreen()),
                MainTabInset(child: AccountabilityHubScreen()),
                MainTabInset(child: CommunityScreen()),
                MainTabInset(child: ProfileScreen()),
              ],
            ),
            bottomNavigationBar: ObsidianBottomNav(
              selectedIndex: index,
              onTap: (i) => ref.read(mainTabIndexProvider.notifier).state = i,
              badgeCounts: {
                _kAccountabilityTabIndex: stakeActions,
                _kProfileTabIndex: unseenFocus ? 1 : 0,
              },
            ),
          ),
          const CloudSyncGlobalIndicator(),
        ],
      ),
    );
  }

  /// Result cards already announced (or attempted) this app session.
  static final Set<String> _sessionCardAnnounced = <String>{};

  /// OQ-1 — "your card is ready": one notification per public commitment
  /// when its outcome lands, routed through the orchestrator so overrides,
  /// spacing, and the ledger apply. Only outcomes decided in the last 48h
  /// announce, so a fresh install never replays history.
  Future<void> _announceReadyCards(
    WidgetRef ref,
    List<StakeChallenge> all,
  ) async {
    final uid = FirestorePaths.activeUid;
    if (uid.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const freshMs = 48 * 60 * 60 * 1000;
    final ready = all
        .where(
          (c) =>
              c.type == StakeChallengeType.soloPublic &&
              (c.status == StakeChallengeStatus.completedSuccess ||
                  c.status == StakeChallengeStatus.completedForfeit ||
                  c.status == StakeChallengeStatus.completedSurrendered) &&
              c.decidedAtMs != null &&
              nowMs - c.decidedAtMs! < freshMs,
        )
        .toList();
    if (ready.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'stake_card_notified_v1_$uid';
    final seen = (prefs.getStringList(key) ?? const []).toSet();
    final fresh = ready
        .where(
          (c) => !seen.contains(c.id) && !_sessionCardAnnounced.contains(c.id),
        )
        .toList();
    if (fresh.isEmpty) return;
    _sessionCardAnnounced.addAll(fresh.map((c) => c.id));

    final orchestrator = ref.read(attentionOrchestratorServiceProvider);
    final delivered = <String>[];
    for (final c in fresh) {
      final won = c.status == StakeChallengeStatus.completedSuccess;
      final now = DateTime.now();
      final decision = await orchestrator.evaluate(
        ReminderIntent(
          id: StableId.generate('ri_stakecard'),
          entityId: c.id,
          entityKind: ReminderEntityKinds.stakeCard,
          entityTitle: won ? 'You did it' : 'Challenge ended',
          proposedAt: now,
          importance: 60,
          interruptionLevel: InterruptionLevel.medium,
          enforcementMode: 'flexible',
          sourceReason: 'stake_card_ready',
          bodyOverride: won
              ? '"${c.frozenGoal.title}" — your victory card is ready to '
                    'share.'
              : '"${c.frozenGoal.title}" — your result card is ready. '
                    'A setback, not the end.',
          createdAtMs: now.millisecondsSinceEpoch,
        ),
      );
      if (decision.outcome != AttentionOutcome.suppressed) {
        delivered.add(c.id);
      }
    }
    if (delivered.isNotEmpty) {
      await prefs.setStringList(key, {...seen, ...delivered}.toList());
    }
  }

  Future<void> _announceNewInvites(
    BuildContext context,
    WidgetRef ref,
    List<StakeChallenge> invites,
  ) async {
    if (invites.isEmpty) return;
    final uid = FirestorePaths.activeUid;
    if (uid.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);

    final prefs = await SharedPreferences.getInstance();
    final key = 'stake_invite_notified_v1_$uid';
    final seen = (prefs.getStringList(key) ?? const []).toSet();
    final fresh = invites
        .where((c) => !seen.contains(c.id) && !_sessionAnnounced.contains(c.id))
        .toList();
    if (fresh.isEmpty) return;
    // Session-level dedupe keeps the snackbar/evaluate loop from re-running
    // on every stream emission while an invite stays suppressed.
    _sessionAnnounced.addAll(fresh.map((c) => c.id));

    // Routed through the AttentionOrchestrator (Phase 0, decision log
    // 2026-07-23): invites respect overrides/collision spacing, land in the
    // notification ledger, and carry a `stake:` payload so taps navigate.
    final orchestrator = ref.read(attentionOrchestratorServiceProvider);
    final delivered = <String>[];
    for (final c in fresh) {
      final now = DateTime.now();
      final decision = await orchestrator.evaluate(
        ReminderIntent(
          id: StableId.generate('ri_stake'),
          entityId: c.id,
          entityKind: ReminderEntityKinds.stakeInvite,
          entityTitle: 'You\'ve been challenged',
          proposedAt: now,
          importance: 70,
          interruptionLevel: InterruptionLevel.high,
          enforcementMode: 'flexible',
          sourceReason: 'stake_invite_announce',
          bodyOverride:
              '"${c.frozenGoal.title}" — accept or decline in Accountability.',
          createdAtMs: now.millisecondsSinceEpoch,
        ),
      );
      if (decision.outcome != AttentionOutcome.suppressed) {
        delivered.add(c.id);
      }
    }
    // Persist only DELIVERED invites (review C): a suppressed one retries
    // next session (or via the override-end flush), instead of being marked
    // seen forever with no notification ever shown.
    if (delivered.isNotEmpty) {
      await prefs.setStringList(key, {...seen, ...delivered}.toList());
    }

    final text = fresh.length == 1
        ? 'Challenge invite: "${fresh.first.frozenGoal.title}"'
        : '${fresh.length} new challenge invites';
    messenger?.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => ref.read(mainTabIndexProvider.notifier).state =
              _kAccountabilityTabIndex,
        ),
      ),
    );
  }
}
