import 'package:flutter/services.dart';

/// Platform glue for the reveal viewer's screenshot policy (PRD P-6/§7.5).
///
/// Android genuinely BLOCKS capture (FLAG_SECURE — screenshots and the
/// recents preview come out black). iOS can only DETECT: [onScreenshot]
/// fires after the fact so the offender's own device self-reports the
/// strike, and [onCaptureChanged] flips while screen recording is live so
/// the UI can hide the photo. A second phone photographing the screen is
/// undetectable — the short reveal windows are the real mitigation; never
/// promise "screenshots are impossible".
class SecureScreen {
  SecureScreen._();

  static const _channel = MethodChannel('sidepal/secure_screen');

  static VoidCallback? _onScreenshot;
  static ValueChanged<bool>? _onCaptureChanged;
  static bool _handlerInstalled = false;

  /// Enables secure mode while a reveal route is on screen. Returns true if
  /// a screen RECORDING is already running (iOS) so the caller can start
  /// hidden. Safe on platforms without the channel (no-op).
  static Future<bool> enable({
    VoidCallback? onScreenshot,
    ValueChanged<bool>? onCaptureChanged,
  }) async {
    _onScreenshot = onScreenshot;
    _onCaptureChanged = onCaptureChanged;
    if (!_handlerInstalled) {
      _handlerInstalled = true;
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'screenshotTaken':
            _onScreenshot?.call();
          case 'captureChanged':
            _onCaptureChanged?.call(call.arguments == true);
        }
      });
    }
    try {
      final capturing = await _channel.invokeMethod<bool>('enableSecure');
      return capturing ?? false;
    } on MissingPluginException {
      return false; // tests / unsupported platforms
    } on PlatformException {
      return false;
    }
  }

  static Future<void> disable() async {
    _onScreenshot = null;
    _onCaptureChanged = null;
    try {
      await _channel.invokeMethod<void>('disableSecure');
    } on MissingPluginException {
      // no-op
    } on PlatformException {
      // no-op
    }
  }
}
