import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Platform audio-session interruptions as a `true` (began) / `false`
/// (ended) stream for [VoiceModeController.audioInterruptions] (audit
/// M9). A phone call or Siri taking the session pauses the voice loop
/// honestly instead of stranding it on SPEAKING/LISTENING; resumption is
/// always the user's orb tap (settled Q7). Best-effort: without the
/// platform channel the stream simply never emits.
Stream<bool> voiceAudioInterruptions() async* {
  AudioSession session;
  try {
    session = await AudioSession.instance;
  } catch (e) {
    debugPrint('[VoiceMode] audio session unavailable: $e');
    return;
  }
  yield* session.interruptionEventStream.map((event) => event.begin);
}
