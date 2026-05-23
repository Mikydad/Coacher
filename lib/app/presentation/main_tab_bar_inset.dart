import 'package:flutter/material.dart';

/// Height of [ObsidianBottomNav] above the safe area, including outer margin.
const double kMainTabBarContentHeight = 76;

/// Extra gap so scroll content / FABs clear the blurred nav pill.
const double kMainTabBarBreathingRoom = 12;

/// Bottom clearance for content inside [MainTabShell] tabs (floating nav + home indicator).
///
/// Uses [MediaQuery.viewPadding] so it stays correct when a child [Scaffold]
/// resets [MediaQuery.padding] (e.g. Coach AI).
double mainTabBarBottomInset(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom +
      kMainTabBarContentHeight +
      kMainTabBarBreathingRoom;
}

/// Bottom padding for a fixed footer (input bar) on a main tab: tab bar or keyboard.
double mainTabFooterPadding(BuildContext context, {double extra = 12}) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard + extra;
  return mainTabBarBottomInset(context) + extra;
}

/// Adds [base] padding plus clearance for the floating bottom nav.
EdgeInsets mainTabScrollPadding(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
}) {
  final inset = mainTabBarBottomInset(context);
  return EdgeInsets.fromLTRB(
    base.left,
    base.top,
    base.right,
    base.bottom + inset,
  );
}

/// Shrinks a main-tab root so [Scaffold] body / FAB sit above [ObsidianBottomNav].
///
/// Coach AI opts out and uses [mainTabFooterPadding] on its input footer instead.
class MainTabInset extends StatelessWidget {
  const MainTabInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: mainTabBarBottomInset(context)),
      child: child,
    );
  }
}
