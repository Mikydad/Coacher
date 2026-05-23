import 'package:flutter/material.dart';

/// Approximate height of [ObsidianBottomNav] content above the safe area.
const double kMainTabBarContentHeight = 76;

/// Bottom clearance for content inside [MainTabShell] tabs (floating nav + home indicator).
///
/// Uses [MediaQuery.viewPadding] so it stays correct when a child [Scaffold]
/// resets [MediaQuery.padding] (e.g. Coach AI).
double mainTabBarBottomInset(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom + kMainTabBarContentHeight;
}

/// Bottom padding for a fixed footer (input bar) on a main tab: tab bar or keyboard.
double mainTabFooterPadding(BuildContext context, {double extra = 12}) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard + extra;
  return mainTabBarBottomInset(context) + extra;
}
