import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Process-wide owner of the `speech_to_text` singleton's status/error
/// callbacks (fix-wave Phase 4, AUDIT.md §8 V1 / GPT-5.6 G11).
///
/// The plugin is a process singleton whose `initialize()` early-returns
/// once initialized WITHOUT re-registering `onStatus`/`onError` — so the
/// first initializer owned the callbacks forever. Every Voice Mode entry
/// creates a fresh adapter, and the dictation mic registers its own
/// handlers on the same singleton: from the SECOND voice session per app
/// launch (or the first, if dictation ran earlier) the active controller
/// was deaf to 'listening'/'done'/error events — the connecting phase
/// stuck, silent listens fell to the 7s stall watchdog and ended in the
/// false "microphone stalled" error, and the dictation button's lit state
/// never reset after Voice Mode ran.
///
/// The plugin's `statusListener`/`errorListener` are PUBLIC mutable
/// fields; this registry keeps them pinned to one pair of dispatchers and
/// routes events to whoever claimed last. Consumers claim on initialize
/// AND before every listen — ownership is cheap to re-assert and the
/// newest listener is always the one that matters.
abstract final class SharedSpeechCallbacks {
  static Object? _owner;
  static void Function(String status)? _onStatus;
  static void Function()? _onError;

  /// Routes the singleton's events to [onStatus]/[onError] until another
  /// consumer claims. Also re-asserts the plugin's public listener fields —
  /// the load-bearing half for every initialize() after the first.
  static void claim(
    Object owner, {
    required SpeechToText speech,
    required void Function(String status) onStatus,
    required void Function() onError,
  }) {
    _owner = owner;
    _onStatus = onStatus;
    _onError = onError;
    speech.statusListener = dispatchStatus;
    speech.errorListener = dispatchError;
  }

  /// Clears the routing when [owner] still holds it — a consumer going
  /// away must not leave its dead callbacks armed.
  static void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onStatus = null;
    _onError = null;
  }

  /// The one status listener ever handed to the plugin.
  static void dispatchStatus(String status) => _onStatus?.call(status);

  /// The one error listener ever handed to the plugin.
  static void dispatchError(SpeechRecognitionError error) => _onError?.call();
}
