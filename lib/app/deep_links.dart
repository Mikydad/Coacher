import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../features/community/presentation/sheets/circle_join_code_sheet.dart';
import 'app_navigator.dart';

/// Dart side of the sidepal:// deep-link bridge (2026-08-26).
///
/// Mirrors [SiriVoiceEntry]: the native side (AppDelegate's DeepLinkBridge)
/// stamps a pending link consumed **idempotently** from launch/resume, and
/// forwards warm-app links over the channel. Whichever trigger runs first
/// wins; the rest see null and do nothing.
///
/// Routes handled:
///  - `sidepal://join/{KEY}` → the join-with-key sheet, prefilled.
class DeepLinks {
  DeepLinks._();

  static const _channel = MethodChannel('sidepal/deep_links');
  static bool _initialized = false;

  /// Installs the warm-path handler. Call once at startup.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'linkReceived') {
        _handle(call.arguments as String?);
      }
      return null;
    });
  }

  /// Checks (and clears) the native pending link; routes when set.
  /// Safe everywhere: on platforms without the channel this is a no-op.
  static Future<void> consumePendingLink() async {
    String? link;
    try {
      link = await _channel.invokeMethod<String>('consumePendingLink');
    } catch (e) {
      debugPrint('[DeepLinks] consume skipped: $e');
      return;
    }
    _handle(link);
  }

  static void _handle(String? link) {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme.toLowerCase() != 'sidepal') return;
    debugPrint('[DeepLinks] handling $link');
    if (uri.host == 'join') {
      final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (code.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = appNavigatorKey.currentContext;
        if (context == null) return;
        unawaited(showJoinWithCodeSheetForLink(context, code));
      });
    }
  }
}
