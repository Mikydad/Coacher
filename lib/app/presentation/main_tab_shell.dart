import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/notifications/local_notifications_service.dart';
import '../../features/accountability/application/stakes_providers.dart';
import '../../features/accountability/domain/models/stake_challenge.dart';
import '../../features/accountability/presentation/accountability_hub_screen.dart';
import '../../features/auth/presentation/widgets/email_verification_banner.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/goals/presentation/goal_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../core/presentation/cloud_sync_global_indicator.dart';
import '../application/main_tab_navigation.dart';
import 'main_tab_bar_inset.dart';
import 'obsidian_bottom_nav.dart';

/// Accountability's position in the tab row (badge + "View" jumps).
const int _kAccountabilityTabIndex = 2;

/// Root shell: five primary tabs (Progress lives in Profile; Coach is
/// the omnipresent FAB + sheet) with a persistent watermark bottom nav.
class MainTabShell extends ConsumerWidget {
  const MainTabShell({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);
    final stakeActions = ref.watch(stakeActionsNeededProvider);

    // Announce challenge invites the moment sync lands them: one local
    // notification + in-app snackbar per invite, exactly once per device
    // (seen-set in prefs). The badge carries the persistent state.
    ref.listen<List<StakeChallenge>>(stakePendingInvitesProvider, (_, next) {
      _announceNewInvites(context, ref, next);
    });

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
              badgeCounts: {_kAccountabilityTabIndex: stakeActions},
            ),
          ),
          const CloudSyncGlobalIndicator(),
        ],
      ),
    );
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
    final fresh = invites.where((c) => !seen.contains(c.id)).toList();
    if (fresh.isEmpty) return;
    await prefs.setStringList(key, {...seen, ...fresh.map((c) => c.id)}.toList());

    for (final c in fresh) {
      await LocalNotificationsService.instance.showNow(
        // Stable per challenge so a re-emit can't stack duplicates.
        id: c.id.hashCode & 0x7fffffff,
        title: 'You\'ve been challenged',
        body:
            '"${c.frozenGoal.title}" — accept or decline in Accountability.',
      );
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
