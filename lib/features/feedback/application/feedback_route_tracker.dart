import 'package:flutter/widgets.dart';

/// Records the name of the top-most route so feedback reports can say which
/// screen the user was on.
///
/// A [NavigatorObserver] is used (rather than `ModalRoute.of`) because the
/// tester bug bubble lives in `MaterialApp.builder`, ABOVE the navigator —
/// there is no route in its own context. The notifier is static: the
/// MaterialApp (and its observer) is recreated on theme toggle, and every
/// instance writing to one shared notifier keeps the value continuous.
class FeedbackRouteTracker extends NavigatorObserver {
  static final ValueNotifier<String?> topRouteName = ValueNotifier(null);

  void _record(Route<dynamic>? route) {
    topRouteName.value = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _record(newRoute);
}
