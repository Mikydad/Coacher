import 'dart:async';

import 'package:flutter/foundation.dart';

import 'voice_speech_text.dart';

/// Where the voice loop currently is. The UI orb renders one look per
/// phase; every transition notifies.
enum VoiceModePhase {
  /// Not in the loop (paused after repeated silence, or before start).
  idle,

  /// Mic open, streaming a live transcript.
  listening,

  /// Utterance sent — waiting on the Coach reply.
  thinking,

  /// TTS is reading the reply, sentence by sentence. Tap interrupts.
  speaking,
}

/// STT seam — the controller never touches the plugin directly, so the
/// whole loop is unit-testable with fakes.
abstract class VoiceSpeechAdapter {
  /// Returns false when mic/speech permissions are unavailable.
  /// [onStatus] receives plugin status strings ('done', 'notListening'…).
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function() onError,
  });

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stop();
}

/// TTS seam. [speak] receives one whole sanitized reply and must complete
/// when playback finishes OR [stop] interrupts it — chunking/streaming is
/// the adapter's own business (flutter_tts chunks sentences; OpenAI TTS
/// synthesizes the reply in one or two calls).
abstract class VoiceTtsAdapter {
  Future<void> configure();
  Future<void> speak(String text);
  Future<void> stop();

  /// End-of-session cleanup (native players etc.). Called once from
  /// [VoiceModeController.dispose].
  Future<void> release();
}

/// Optional Level-2 capability: speak a reply THAT IS STILL BEING WRITTEN.
/// [deltas] emits raw text chunks as the model generates; the adapter
/// sentence-splits, sanitizes, synthesizes and plays them pipelined, and
/// completes when the full reply has been spoken or [VoiceTtsAdapter.stop]
/// interrupted it. Adapters without this capability are buffered by the
/// caller (full text → [VoiceTtsAdapter.speak]).
abstract class VoiceTtsStreamCapable {
  Future<void> speakStream(Stream<String> deltas);
}

/// The Voice Mode loop (humanizing Phase 3, PRD §6 L2):
/// auto-listen → auto-send on end-of-speech → speak the reply
/// sentence-chunked → auto-relisten. Tap-to-interrupt at any point.
///
/// Airplane-honest: TTS is on-device, so the loop speaks whatever the
/// Coach pipeline returns — including the deterministic mock reply and
/// honest network-error copy when AI is unreachable.
class VoiceModeController extends ChangeNotifier {
  VoiceModeController({
    required this.speech,
    required this.tts,
    required this.sendAndGetReply,
    this.tryStreamReply,
    this.maxConsecutiveSilentListens = 2,
    this.listenStallTimeout = const Duration(seconds: 7),
    this.maxListenStallRestarts = 2,
  });

  final VoiceSpeechAdapter speech;
  final VoiceTtsAdapter tts;

  /// Sends the utterance through the normal Coach path and returns the
  /// assistant's textual reply (never throws; error copy is a reply too).
  final Future<String?> Function(String userText) sendAndGetReply;

  /// Level 2 seam: asked FIRST for each turn. Returning a stream means
  /// "this turn streams" (conversational, online) and the reply is spoken
  /// sentence-pipelined as it generates; returning null falls back to
  /// [sendAndGetReply] (mutate-classified turns, offline, feature off).
  final Stream<String>? Function(String userText)? tryStreamReply;

  /// After this many empty listens in a row the loop pauses to [idle]
  /// instead of re-opening the mic forever.
  final int maxConsecutiveSilentListens;

  /// Dead-mic watchdog (Siri entry fix): a HEALTHY silent listen closes
  /// itself at the plugin's pauseFor (~1.7s → 'done'), so a listen that
  /// produces NO result and NO end-of-speech within this window has a dead
  /// audio session (Siri still held it when the mic opened) — restart it.
  final Duration listenStallTimeout;

  /// Stall restarts before giving up to [idle] with honest retry copy.
  final int maxListenStallRestarts;

  VoiceModePhase _phase = VoiceModePhase.idle;
  String _transcript = '';
  String? _statusMessage;
  bool _active = false;
  bool _disposed = false;
  bool _micAvailable = true;
  int _silentListens = 0;

  /// Bumped on every interrupt/exit — in-flight async work checks it and
  /// abandons itself instead of clobbering a newer state.
  int _generation = 0;

  Timer? _listenStallTimer;
  int _stallRestarts = 0;

  /// True while a stall recovery is stopping the dead session — blocks the
  /// stop-triggered 'done' status from finalizing an empty utterance (the
  /// recovery re-listens itself).
  bool _recoveringListen = false;

  VoiceModePhase get phase => _phase;

  /// Live partial transcript while listening.
  String get transcript => _transcript;

  /// One-line helper copy for the UI (silence hint, mic-unavailable…).
  String? get statusMessage => _statusMessage;

  bool get isActive => _active;
  bool get micAvailable => _micAvailable;

  /// Enters Voice Mode and opens the mic.
  ///
  /// [listenDelay] postpones the FIRST mic open — externally-launched
  /// entries (Siri) foreground the app while Siri's own audio session is
  /// still releasing; opening the mic into that session yields a dead
  /// recognizer (no results, no 'done', ever). An orb tap during the delay
  /// simply listens early.
  Future<void> start({Duration? listenDelay}) async {
    if (_active) return;
    _active = true;
    _statusMessage = null;
    _silentListens = 0;
    _stallRestarts = 0;
    await tts.configure();
    final ok = await speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (_disposed) return;
    if (!ok) {
      _micAvailable = false;
      _statusMessage =
          'Microphone unavailable — check mic and speech permissions '
          'in Settings.';
      _setPhase(VoiceModePhase.idle);
      return;
    }
    if (listenDelay != null && listenDelay > Duration.zero) {
      await Future<void>.delayed(listenDelay);
      if (_disposed || !_active) return;
      // The user woke the loop themselves mid-delay (orb tap) — don't
      // stack a second listen on top of theirs.
      if (_phase != VoiceModePhase.idle) return;
    }
    await _listen();
  }

  /// Leaves Voice Mode entirely (X button / sheet closed).
  Future<void> stopAndExit() async {
    _active = false;
    _generation++;
    _cancelListenStallWatchdog();
    _setPhase(VoiceModePhase.idle);
    try {
      await speech.stop();
    } catch (_) {}
    try {
      await tts.stop();
    } catch (_) {}
  }

  /// The orb tap — contextual: interrupt speech, finalize the current
  /// utterance, or wake from idle.
  Future<void> onOrbTap() async {
    switch (_phase) {
      case VoiceModePhase.speaking:
        await _interruptSpeech();
      case VoiceModePhase.listening:
        // Force end-of-speech now; _onSpeechStatus finalizes.
        await speech.stop();
      case VoiceModePhase.idle:
        if (_active) {
          _silentListens = 0;
          _statusMessage = null;
          await _listen();
        }
      case VoiceModePhase.thinking:
        break; // Nothing sensible to interrupt mid-request.
    }
  }

  // ─── Loop internals ─────────────────────────────────────────────────────────

  Future<void> _listen() async {
    if (!_active || _disposed) return;
    final generation = ++_generation;
    _transcript = '';
    _setPhase(VoiceModePhase.listening);
    _armListenStallWatchdog(generation);
    try {
      await speech.listen(
        onResult: (text, isFinal) {
          if (_disposed || generation != _generation) return;
          // Any result proves the audio session is alive.
          _cancelListenStallWatchdog();
          _stallRestarts = 0;
          _transcript = text;
          notifyListeners();
          if (isFinal) _finalizeUtterance();
        },
      );
    } catch (_) {
      if (generation != _generation) return;
      _cancelListenStallWatchdog();
      _statusMessage = 'Voice input failed — tap to retry.';
      _setPhase(VoiceModePhase.idle);
    }
  }

  /// Armed per listen. Fires only when the plugin went completely silent —
  /// no result AND no end-of-speech status — which never happens on a
  /// healthy session (silence self-closes at pauseFor). 'listening'-type
  /// statuses deliberately do NOT disarm it: a dead session still emits
  /// those.
  void _armListenStallWatchdog(int generation) {
    _listenStallTimer?.cancel();
    _listenStallTimer = Timer(listenStallTimeout, () {
      if (_disposed || !_active || generation != _generation) return;
      if (_phase != VoiceModePhase.listening) return;
      if (_transcript.trim().isNotEmpty) return;
      unawaited(_recoverStalledListen(generation));
    });
  }

  void _cancelListenStallWatchdog() {
    _listenStallTimer?.cancel();
    _listenStallTimer = null;
  }

  Future<void> _recoverStalledListen(int generation) async {
    _stallRestarts++;
    if (_stallRestarts > maxListenStallRestarts) {
      _stallRestarts = 0;
      _statusMessage = 'The microphone stalled — tap to try again.';
      _setPhase(VoiceModePhase.idle);
      try {
        await speech.stop();
      } catch (_) {}
      return;
    }
    _recoveringListen = true;
    try {
      await speech.stop();
    } catch (_) {}
    _recoveringListen = false;
    if (_disposed || !_active) return;
    // A result/finalize slipped in while we were stopping — that turn owns
    // the loop now.
    if (generation != _generation) return;
    await _listen();
  }

  void _onSpeechStatus(String status) {
    if (_disposed || !_active || _recoveringListen) return;
    // 'done' fires on end-of-speech even when the plugin never flagged a
    // final result (short utterances, some locales) — finalize from here.
    if ((status == 'done' || status == 'notListening') &&
        _phase == VoiceModePhase.listening) {
      _finalizeUtterance();
    }
  }

  void _onSpeechError() {
    if (_disposed || !_active) return;
    if (_phase == VoiceModePhase.listening) {
      _statusMessage = 'I didn\'t catch that — tap to retry.';
      _setPhase(VoiceModePhase.idle);
    }
  }

  bool _finalizing = false;

  Future<void> _finalizeUtterance() async {
    if (_finalizing || _phase != VoiceModePhase.listening) return;
    _finalizing = true;
    _cancelListenStallWatchdog();
    try {
      final text = _transcript.trim();
      if (text.isEmpty) {
        _silentListens++;
        if (_silentListens >= maxConsecutiveSilentListens) {
          _statusMessage = 'Tap when you\'re ready to talk.';
          _setPhase(VoiceModePhase.idle);
        } else {
          await _listen();
        }
        return;
      }
      _silentListens = 0;
      await _sendAndSpeak(text);
    } finally {
      _finalizing = false;
    }
  }

  Future<void> _sendAndSpeak(String text) async {
    final generation = ++_generation;
    _setPhase(VoiceModePhase.thinking);
    // Level 2 fast path: stream + speak sentence-pipelined.
    final replyStream = tryStreamReply?.call(text);
    if (replyStream != null) {
      await _streamAndSpeak(replyStream, generation);
      return;
    }
    // T0→T1 of the turn's latency ledger; the TTS adapter logs its own
    // T2→T4 leg. Together one spoken turn reads as two [voice-timing]
    // lines (measure, don't estimate — latency batch 2).
    final t0 = DateTime.now();
    String? reply;
    try {
      reply = await sendAndGetReply(text);
    } catch (_) {
      reply = null;
    }
    if (kDebugMode) {
      debugPrint(
        '[voice-timing] reply=${DateTime.now().difference(t0).inMilliseconds}ms '
        'chars=${reply?.length ?? 0}',
      );
    }
    if (_disposed || !_active || generation != _generation) return;
    if (reply == null || reply.trim().isEmpty) {
      _statusMessage = 'No reply — tap to try again.';
      _setPhase(VoiceModePhase.idle);
      return;
    }
    await _speak(reply, generation);
  }

  Future<void> _speak(String reply, int generation) async {
    final text = sanitizeForSpeech(reply);
    if (text.isNotEmpty) {
      _setPhase(VoiceModePhase.speaking);
      try {
        await tts.speak(text);
      } catch (_) {
        // TTS failure: fall through to relisten — text is on screen.
      }
    }
    if (_disposed || !_active || generation != _generation) return;
    await _listen();
  }

  /// Level 2 turn: deltas flow into the TTS pipeline as they generate.
  /// Phase flips to speaking on the FIRST delta; stream cancellation on
  /// interrupt propagates upstream (the transport aborts the HTTP stream).
  Future<void> _streamAndSpeak(
    Stream<String> replyStream,
    int generation,
  ) async {
    final t0 = DateTime.now();
    var sawText = false;
    final monitored = replyStream.map((delta) {
      if (!sawText && delta.trim().isNotEmpty) {
        sawText = true;
        if (kDebugMode) {
          debugPrint(
            '[voice-timing] firstDelta='
            '${DateTime.now().difference(t0).inMilliseconds}ms',
          );
        }
        if (generation == _generation && _active) {
          _setPhase(VoiceModePhase.speaking);
        }
      }
      return delta;
    });
    final tts0 = tts;
    try {
      if (tts0 is VoiceTtsStreamCapable) {
        await (tts0 as VoiceTtsStreamCapable).speakStream(monitored);
      } else {
        final full = StringBuffer();
        await monitored.forEach(full.write);
        if (_disposed || !_active || generation != _generation) return;
        final text = full.toString().trim();
        if (text.isNotEmpty) await _speak(text, generation);
        if (text.isNotEmpty) return; // _speak relistens itself
      }
    } catch (_) {
      // Speech failed — the reply text is in the thread regardless.
    }
    if (kDebugMode) {
      debugPrint(
        '[voice-timing] streamed turn=${DateTime.now().difference(t0).inMilliseconds}ms',
      );
    }
    if (_disposed || !_active || generation != _generation) return;
    if (!sawText) {
      _statusMessage = 'No reply — tap to try again.';
      _setPhase(VoiceModePhase.idle);
      return;
    }
    await _listen();
  }

  Future<void> _interruptSpeech() async {
    _generation++;
    try {
      await tts.stop();
    } catch (_) {}
    if (_disposed || !_active) return;
    await _listen();
  }

  void _setPhase(VoiceModePhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _generation++;
    _cancelListenStallWatchdog();
    unawaited(_teardown());
    super.dispose();
  }

  Future<void> _teardown() async {
    try {
      await speech.stop();
    } catch (_) {}
    try {
      await tts.stop();
    } catch (_) {}
    try {
      await tts.release();
    } catch (_) {}
  }
}
