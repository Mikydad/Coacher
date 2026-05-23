import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/analytics/presentation/analytics_progress_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/goals/presentation/goal_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../application/main_tab_navigation.dart';
import 'obsidian_bottom_nav.dart';

/// Root shell: six primary tabs with a persistent watermark bottom nav.
class MainTabShell extends ConsumerWidget {
  const MainTabShell({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

    final bottomInset = MediaQuery.paddingOf(context).bottom + 76;

    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.paddingOf(context).copyWith(
            bottom: bottomInset,
          ),
        ),
        child: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          AiAssistantScreen(),
          GoalSelectionScreen(),
          AnalyticsProgressScreen(),
          CommunityScreen(),
          ProfileScreen(),
        ],
        ),
      ),
      bottomNavigationBar: ObsidianBottomNav(
        selectedIndex: index,
        onTap: (i) => ref.read(mainTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
