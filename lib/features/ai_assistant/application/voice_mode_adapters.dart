import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_mode_controller.dart';
import 'voice_selection.dart';
import 'voice_speech_text.dart';

/// Real STT adapter over the `speech_to_text` plugin (same plugin the
/// one-shot dictation mic uses — Voice Mode adds the loop, not a new
/// speech stack).
class SpeechToTextVoiceAdapter implements VoiceSpeechAdapter {
  SpeechToTextVoiceAdapter();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function() onError,
  }) async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onStatus: onStatus,
        onError: (_) => onError(),
      );
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) {
    return _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        // End-of-speech detection — the whole loop hangs on these. Without
        // pauseFor the OS session stays open (~1 min hard cap) and neither
        // finalResult nor the 'done' status ever arrives, so the controller
        // sits in `listening` forever. 3s of silence = the utterance is
        // over; listenFor bounds a single turn.
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 60),
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

/// Real TTS adapter over `flutter_tts` — on-device platform voices, so
/// output works in airplane mode (PRD §6: "voice speaks even the
/// deterministic mock when AI is down").
class FlutterTtsVoiceAdapter implements VoiceTtsAdapter {
  FlutterTtsVoiceAdapter();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  @override
  Future<void> configure() async {
    if (_configured) return;
    // speak() must resolve when playback FINISHES — the controller chains
    // sentence chunks on this contract.
    await _tts.awaitSpeakCompletion(true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Share the audio session with speech_to_text (the loop alternates
      // mic and speaker), and keep it ALIVE between utterances: the default
      // auto-stop deactivates the session after every sentence chunk, and
      // each reactivation re-picks the route — which is how replies ended
      // up on the earpiece.
      await _tts.setSharedInstance(true);
      await _tts.autoStopSharedSession(false);
      await _applySpeakerRoute();
      await _pickBestInstalledVoice();
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _configured = true;
  }

  /// Upgrade from the compact system default to the best installed
  /// enhanced/premium voice for the device locale (see voice_selection.dart
  /// for the ranking). Best-effort: any failure keeps the default voice —
  /// a robotic Coach beats a silent one.
  Future<void> _pickBestInstalledVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final tag = PlatformDispatcher.instance.locale.toLanguageTag();
      final preferred = pickPreferredIosVoice(voices, tag);
      if (preferred != null) await _tts.setVoice(preferred);
    } catch (e) {
      debugPrint('[VoiceMode] voice selection skipped: $e');
    }
  }

  /// playAndRecord's default output is the RECEIVER (the call earpiece);
  /// `defaultToSpeaker` must be in force when the route is decided. Because
  /// speech_to_text rewrites the session around every listen (remember →
  /// override → restore → deactivate), this is re-asserted before each
  /// speaking turn rather than trusted to survive from configure().
  Future<void> _applySpeakerRoute() {
    return _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playAndRecord,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );
  }

  /// Bumped by [stop]; the sentence loop abandons itself when it changes.
  int _speakGeneration = 0;

  @override
  Future<void> speak(String text) async {
    final generation = ++_speakGeneration;
    // Sentence-chunked so playback starts on the first sentence and an
    // interrupt lands cleanly between sentences (flutter_tts can only be
    // stopped whole-utterance without an audible cut).
    for (final chunk in splitIntoSentences(text)) {
      if (generation != _speakGeneration) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _applySpeakerRoute();
      }
      await _tts.speak(chunk);
    }
  }

  @override
  Future<void> stop() async {
    _speakGeneration++;
    await _tts.stop();
  }

  @override
  Future<void> release() async {
    // flutter_tts holds no per-session native resources worth freeing.
  }
}

/// TTS adapter over the `aiSpeech` Cloud Function proxy (OpenAI TTS,
/// voice pinned server-side — Coral). Synthesizes the reply as first
/// sentence + remainder, fetched in parallel and played sequentially, so
/// time-to-first-audio is one short synthesis instead of the whole reply.
///
/// Never used bare: [ResilientVoiceTtsAdapter] wraps it so any failure
/// (offline, quota, kill switch) silently degrades to the system voice.
class OpenAiTtsVoiceAdapter implements VoiceTtsAdapter {
  OpenAiTtsVoiceAdapter({required this.synthesize});

  /// Returns audio bytes (mp3) for [text] — in production
  /// `AiProxyClient.speak` with a short timeout.
  final Future<Uint8List> Function(String text) synthesize;

  final AudioPlayer _player = AudioPlayer();
  bool _configured = false;
  int _generation = 0;
  Completer<void>? _playing;

  @override
  Future<void> configure() async {
    if (_configured) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Same audio-session contract as FlutterTtsVoiceAdapter: share the
      // session with the mic and force the main speaker (playAndRecord
      // defaults to the call earpiece otherwise).
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    }
    await _player.setReleaseMode(ReleaseMode.stop);
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    final generation = ++_generation;
    final sentences = splitIntoSentences(text);
    if (sentences.isEmpty) return;
    final head = sentences.first;
    final tail = sentences.skip(1).join(' ');

    // Head failure throws (nothing spoken yet — the resilient wrapper can
    // fall back for the whole reply). The tail is pre-fetched in parallel
    // but must never surface as an unhandled async error, and a tail-only
    // failure is swallowed: the head was already heard, so falling back
    // would double-speak — the full text is on screen regardless.
    final Future<Uint8List?>? tailFuture = tail.isEmpty
        ? null
        : synthesize(tail).then<Uint8List?>((b) => b, onError: (_) => null);

    final headBytes = await synthesize(head);
    if (generation != _generation) return;
    await _play(headBytes, generation);

    if (tailFuture == null) return;
    final tailBytes = await tailFuture;
    if (tailBytes == null || generation != _generation) return;
    await _play(tailBytes, generation);
  }

  Future<void> _play(Uint8List bytes, int generation) async {
    if (generation != _generation) return;
    final done = Completer<void>();
    _playing = done;
    final sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      await done.future;
    } finally {
      await sub.cancel();
      if (identical(_playing, done)) _playing = null;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    // play() awaits onPlayerComplete, which never fires for a manual stop —
    // complete the latch here so speak() resolves promptly.
    final playing = _playing;
    if (playing != null && !playing.isCompleted) playing.complete();
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    await _player.dispose();
  }
}
