import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Root shell: five primary tabs (Progress lives in Profile; Coach is
/// the omnipresent FAB + sheet) with a persistent watermark bottom nav.
class MainTabShell extends ConsumerWidget {
  const MainTabShell({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

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
            ),
          ),
          const CloudSyncGlobalIndicator(),
        ],
      ),
    );
  }
}
