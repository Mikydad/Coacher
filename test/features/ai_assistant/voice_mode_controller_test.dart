import 'dart:async';

import 'package:sidepal/features/ai_assistant/application/voice_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scripted STT fake — the test emits partials/finals and plugin status
/// strings exactly like the platform would.
class FakeSpeechAdapter implements VoiceSpeechAdapter {
  bool available = true;
  int listenCalls = 0;
  int stopCalls = 0;
  void Function(String status)? _onStatus;
  void Function(String text, bool isFinal)? _onResult;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function() onError,
  }) async {
    _onStatus = onStatus;
    return available;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    listenCalls++;
    _onResult = onResult;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _onStatus?.call('done');
  }

  void emitPartial(String text) => _onResult!(text, false);
  void emitFinal(String text) => _onResult!(text, true);
  void emitDone() => _onStatus!('done');
}

/// TTS fake — records replies (one speak per reply); can hold playback
/// open so tests can interrupt mid-reply.
class FakeTtsAdapter implements VoiceTtsAdapter {
  final List<String> spoken = [];
  int stopCalls = 0;
  int releaseCalls = 0;
  bool holdPlayback = false;
  Completer<void>? _playing;

  @override
  Future<void> configure() async {}

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (holdPlayback) {
      _playing = Completer<void>();
      await _playing!.future;
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _playing?.complete();
    _playing = null;
  }

  @override
  Future<void> release() async {
    releaseCalls++;
  }
}

void main() {
  late FakeSpeechAdapter speech;
  late FakeTtsAdapter tts;
  late List<String> sentMessages;
  String? nextReply;

  VoiceModeController build() {
    speech = FakeSpeechAdapter();
    tts = FakeTtsAdapter();
    sentMessages = [];
    nextReply = 'Sounds good. Anything else?';
    return VoiceModeController(
      speech: speech,
      tts: tts,
      sendAndGetReply: (text) async {
        sentMessages.add(text);
        return nextReply;
      },
    );
  }

  test('start opens the mic and streams a live transcript', () async {
    final controller = build();
    await controller.start();
    expect(controller.phase, VoiceModePhase.listening);
    expect(speech.listenCalls, 1);

    speech.emitPartial('call my');
    expect(controller.transcript, 'call my');
    speech.emitPartial('call my cousin');
    expect(controller.transcript, 'call my cousin');
  });

  test(
    'final result → sends → speaks the sanitized reply → auto-relistens',
    () async {
      final controller = build();
      nextReply = '**Sounds good.** Anything else? [mem:f_1|stated]';
      await controller.start();

      speech.emitFinal('call my cousin tomorrow');
      await pumpEventQueue();

      expect(sentMessages, ['call my cousin tomorrow']);
      // One speak per reply — chunking is the adapter's business now —
      // with chat chrome (markdown, mem markers) stripped.
      expect(tts.spoken, ['Sounds good. Anything else?']);
      // Loop closed: mic reopened for the next turn.
      expect(controller.phase, VoiceModePhase.listening);
      expect(speech.listenCalls, 2);
    },
  );

  test('plugin done-status without a final flag still finalizes', () async {
    final controller = build();
    await controller.start();

    speech.emitPartial('quick note');
    speech.emitDone();
    await pumpEventQueue();

    expect(sentMessages, ['quick note']);
    expect(controller.phase, VoiceModePhase.listening);
  });

  test('repeated silence pauses to idle instead of looping the mic', () async {
    final controller = build();
    await controller.start();

    speech.emitFinal('');
    await pumpEventQueue();
    expect(controller.phase, VoiceModePhase.listening);
    expect(speech.listenCalls, 2);

    speech.emitFinal('');
    await pumpEventQueue();
    expect(controller.phase, VoiceModePhase.idle);
    expect(controller.statusMessage, isNotNull);
    expect(sentMessages, isEmpty);

    // Orb tap wakes the loop back up.
    await controller.onOrbTap();
    expect(controller.phase, VoiceModePhase.listening);
  });

  test('orb tap interrupts speech and reopens the mic', () async {
    final controller = build();
    await controller.start();
    tts.holdPlayback = true;

    speech.emitFinal('hello');
    await pumpEventQueue();
    expect(controller.phase, VoiceModePhase.speaking);
    expect(tts.spoken, hasLength(1)); // reply still "playing"

    await controller.onOrbTap();
    await pumpEventQueue();

    expect(tts.stopCalls, greaterThanOrEqualTo(1));
    expect(tts.spoken, hasLength(1)); // nothing new spoken after interrupt
    expect(controller.phase, VoiceModePhase.listening);
  });

  test('dispose releases the TTS adapter', () async {
    final controller = build();
    await controller.start();

    controller.dispose();
    await pumpEventQueue();

    expect(tts.stopCalls, greaterThanOrEqualTo(1));
    expect(tts.releaseCalls, 1);
  });

  test('null reply pauses to idle with a retry hint', () async {
    final controller = build();
    nextReply = null;
    await controller.start();

    speech.emitFinal('hello');
    await pumpEventQueue();

    expect(controller.phase, VoiceModePhase.idle);
    expect(controller.statusMessage, contains('tap'));
  });

  test('unavailable mic reports and stays idle', () async {
    final controller = build();
    speech.available = false;
    // rebuild wires the same fakes; flip before start
    await controller.start();

    expect(controller.phase, VoiceModePhase.idle);
    expect(controller.micAvailable, isFalse);
    expect(controller.statusMessage, contains('permissions'));
  });

  test('stopAndExit silences everything and ignores late results', () async {
    final controller = build();
    await controller.start();
    speech.emitPartial('half a tho');

    await controller.stopAndExit();
    expect(controller.phase, VoiceModePhase.idle);
    expect(speech.stopCalls, greaterThanOrEqualTo(1));

    // A straggling final result must not trigger a send.
    speech.emitFinal('half a thought');
    await pumpEventQueue();
    expect(sentMessages, isEmpty);
  });

  group('listen stall watchdog (Siri dead-session entry)', () {
    VoiceModeController buildWithWatchdog({int maxRestarts = 1}) {
      speech = FakeSpeechAdapter();
      tts = FakeTtsAdapter();
      sentMessages = [];
      return VoiceModeController(
        speech: speech,
        tts: tts,
        sendAndGetReply: (text) async {
          sentMessages.add(text);
          return 'ok';
        },
        listenStallTimeout: const Duration(milliseconds: 30),
        maxListenStallRestarts: maxRestarts,
      );
    }

    test('dead listen (no callbacks at all) restarts the mic, then gives up '
        'to idle with honest copy', () async {
      final controller = buildWithWatchdog(maxRestarts: 1);
      await controller.start();
      expect(speech.listenCalls, 1);

      // First stall: recovery stops the dead session and re-listens; the
      // stop-triggered 'done' from the plugin must NOT finalize an empty
      // utterance on top of that (no double listen).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(speech.stopCalls, 1);
      expect(speech.listenCalls, 2);
      expect(controller.phase, VoiceModePhase.listening);

      // Second stall exceeds maxRestarts → honest idle, mic torn down.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(speech.listenCalls, 2);
      expect(controller.phase, VoiceModePhase.idle);
      expect(controller.statusMessage, contains('stalled'));
    });

    test('a result disarms the watchdog — healthy sessions never restart',
        () async {
      final controller = buildWithWatchdog();
      await controller.start();
      speech.emitPartial('hello');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(speech.listenCalls, 1);
      expect(speech.stopCalls, 0);
      expect(controller.phase, VoiceModePhase.listening);
    });

    test('start listenDelay defers the first mic open (Siri session grace)',
        () async {
      final controller = buildWithWatchdog();
      final started = controller.start(
        listenDelay: const Duration(milliseconds: 80),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(speech.listenCalls, 0);
      expect(controller.phase, VoiceModePhase.idle);

      await started;
      expect(speech.listenCalls, 1);
      expect(controller.phase, VoiceModePhase.listening);
    });
  });
}
