import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_mode_controller.dart';

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
      // mic and speaker) and route to the speaker, ducking other audio.
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
