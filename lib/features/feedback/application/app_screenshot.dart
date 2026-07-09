import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wraps the whole app in `main.dart`. Lives ABOVE the MaterialApp because
/// that widget is rebuilt (keyed on brightness) on theme toggle — this
/// boundary stays stable across rebuilds.
final GlobalKey appScreenshotBoundaryKey = GlobalKey(
  debugLabel: 'appScreenshotBoundary',
);

/// Captures the current frame as PNG bytes, or null when capture isn't
/// possible — the bug report then simply goes out without a screenshot.
///
/// pixelRatio 1.0 (logical resolution) keeps files at a few hundred KB —
/// legible for triage and far under the 5MB storage-rules cap.
Future<Uint8List?> captureAppScreenshot() async {
  try {
    final boundary =
        appScreenshotBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || boundary.debugNeedsPaint) return null;
    final image = await boundary.toImage(pixelRatio: 1.0);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  }
}
