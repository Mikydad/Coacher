import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_navigator.dart';
import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';

/// Set from [main] for notification / background navigation.
ProviderContainer? appRootProviderContainer;

/// Active tab in [MainTabShell] (Home → Profile).
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

/// Pending Coach tab payload when switching tabs without a nested route.
final coachTabArgsProvider = StateProvider<CoachRouteArgs?>((ref) => null);

abstract final class MainTabIndex {
  static const int home = 0;
  static const int coach = 1;
  static const int goals = 2;
  static const int progress = 3;
  static const int community = 4;
  static const int profile = 5;
}

/// Switches the main shell tab and returns to the root route stack.
void navigateToMainTab(
  BuildContext context,
  WidgetRef ref, {
  required int index,
  CoachRouteArgs? coachArgs,
}) {
  if (coachArgs != null) {
    ref.read(coachTabArgsProvider.notifier).state = coachArgs;
  }
  ref.read(mainTabIndexProvider.notifier).state = index;
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  }
}

/// Same as [navigateToMainTab] for code paths that only hold a [ProviderContainer].
void navigateToMainTabWithContainer(
  ProviderContainer container, {
  required int index,
  CoachRouteArgs? coachArgs,
}) {
  if (coachArgs != null) {
    container.read(coachTabArgsProvider.notifier).state = coachArgs;
  }
  container.read(mainTabIndexProvider.notifier).state = index;
  final nav = appNavigatorKey.currentState;
  nav?.popUntil((route) => route.isFirst);
}
