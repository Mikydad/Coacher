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

/// TTS seam. [speak] must complete only when playback finishes — the
/// controller chains sentence chunks on that contract.
abstract class VoiceTtsAdapter {
  Future<void> configure();
  Future<void> speak(String text);
  Future<void> stop();
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
    this.maxConsecutiveSilentListens = 2,
  });

  final VoiceSpeechAdapter speech;
  final VoiceTtsAdapter tts;

  /// Sends the utterance through the normal Coach path and returns the
  /// assistant's textual reply (never throws; error copy is a reply too).
  final Future<String?> Function(String userText) sendAndGetReply;

  /// After this many empty listens in a row the loop pauses to [idle]
  /// instead of re-opening the mic forever.
  final int maxConsecutiveSilentListens;

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

  VoiceModePhase get phase => _phase;

  /// Live partial transcript while listening.
  String get transcript => _transcript;

  /// One-line helper copy for the UI (silence hint, mic-unavailable…).
  String? get statusMessage => _statusMessage;

  bool get isActive => _active;
  bool get micAvailable => _micAvailable;

  /// Enters Voice Mode and opens the mic.
  Future<void> start() async {
    if (_active) return;
    _active = true;
    _statusMessage = null;
    _silentListens = 0;
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
    await _listen();
  }

  /// Leaves Voice Mode entirely (X button / sheet closed).
  Future<void> stopAndExit() async {
    _active = false;
    _generation++;
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
    try {
      await speech.listen(
        onResult: (text, isFinal) {
          if (_disposed || generation != _generation) return;
          _transcript = text;
          notifyListeners();
          if (isFinal) _finalizeUtterance();
        },
      );
    } catch (_) {
      if (generation != _generation) return;
      _statusMessage = 'Voice input failed — tap to retry.';
      _setPhase(VoiceModePhase.idle);
    }
  }

  void _onSpeechStatus(String status) {
    if (_disposed || !_active) return;
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
    String? reply;
    try {
      reply = await sendAndGetReply(text);
    } catch (_) {
      reply = null;
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
    _setPhase(VoiceModePhase.speaking);
    final chunks = speechChunksFor(reply);
    for (final chunk in chunks) {
      if (_disposed || !_active || generation != _generation) return;
      try {
        await tts.speak(chunk);
      } catch (_) {
        break; // TTS failure: fall through to relisten — text is on screen.
      }
    }
    if (_disposed || !_active || generation != _generation) return;
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
    speech.stop();
    tts.stop();
    super.dispose();
  }
}
