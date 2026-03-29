import 'package:flutter/material.dart';

/// Global navigator for flows that run outside the widget tree (e.g. notification taps).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
