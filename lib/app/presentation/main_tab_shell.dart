import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/analytics/presentation/analytics_progress_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/goals/presentation/goal_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../core/presentation/cloud_sync_global_indicator.dart';
import '../application/main_tab_navigation.dart';
import 'main_tab_bar_inset.dart';
import 'obsidian_bottom_nav.dart';

/// Root shell: six primary tabs with a persistent watermark bottom nav.
class MainTabShell extends ConsumerWidget {
  const MainTabShell({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: index,
            children: const [
              MainTabInset(child: HomeScreen()),
              AiAssistantScreen(),
              MainTabInset(child: GoalSelectionScreen()),
              MainTabInset(child: AnalyticsProgressScreen()),
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
    );
  }
}
