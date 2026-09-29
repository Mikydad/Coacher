import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../application/education_providers.dart';
import '../application/getting_started_controller.dart';
import '../domain/page_explainers.dart';
import 'page_explainer_sheet.dart';

/// Wraps a concept page and opens its [PageExplainer] once, on the user's
/// first real visit.
///
/// "Real visit" = the page is showing (a tab page passes its [tabIndex]:
/// the shell builds every tab up front) AND this page's route is on top AND
/// the Getting Started tour isn't running. It waits [delay] so the page
/// draws first and the sheet never lands on a loading spinner. Each page
/// opens its own once — no per-session cap (Miko, 2026-09-29).
///
/// Seen-state shares the device-level education seen-set with the inline
/// first-time cards; it is marked when the sheet OPENS, so a user who kills
/// the app mid-read is not shown it again.
class FirstVisitExplainer extends ConsumerStatefulWidget {
  const FirstVisitExplainer({
    super.key,
    required this.explainer,
    this.tabIndex,
    this.delay = const Duration(milliseconds: 450),
    required this.child,
  });

  final PageExplainer explainer;

  /// The [MainTabIndex] this page lives on, or null for a pushed route.
  final int? tabIndex;
  final Duration delay;
  final Widget child;

  @override
  ConsumerState<FirstVisitExplainer> createState() =>
      _FirstVisitExplainerState();
}

class _FirstVisitExplainerState extends ConsumerState<FirstVisitExplainer> {
  Timer? _timer;

  bool _eligible() =>
      (widget.tabIndex == null ||
          ref.read(mainTabIndexProvider) == widget.tabIndex) &&
      ref.read(showFeatureCardProvider(widget.explainer.seenKey)) &&
      !_tourRunning();

  /// Peeks rather than watches: the tour controller is heavy (task streams,
  /// a settle timer) and only exists once the shell's tour layer made it.
  /// Not yet created means no tour is running.
  bool _tourRunning() =>
      ref.exists(gettingStartedControllerProvider) &&
      ref.read(gettingStartedControllerProvider).isActive;

  void _sync() {
    if (_eligible()) {
      _timer ??= Timer(widget.delay, _fire);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _fire() {
    _timer = null;
    if (!mounted || !_eligible()) return;
    // Something is pushed or presented over this page — try next visit.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    ref
        .read(educationSeenCardsProvider.notifier)
        .markSeen(widget.explainer.seenKey);
    showPageExplainer(context, widget.explainer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate whenever an input flips (prefs finish loading, the user
    // switches tabs).
    ref.watch(showFeatureCardProvider(widget.explainer.seenKey));
    if (widget.tabIndex != null) ref.watch(mainTabIndexProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
    return widget.child;
  }
}
