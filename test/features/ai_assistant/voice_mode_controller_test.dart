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

  VoiceModeController build({
    Duration continuationGap = Duration.zero,
    Duration staleStatusWindow = Duration.zero,
  }) {
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
      // Zero by default so the fake's instant event timing finalizes
      // immediately — the continuation/stale-status behaviors get their
      // own tests with real windows.
      continuationGap: continuationGap,
      staleStatusWindow: staleStatusWindow,
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
        continuationGap: Duration.zero,
        staleStatusWindow: Duration.zero,
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

    test(
        'a session that dies AFTER partials arrived finalizes what it heard '
        'instead of hanging in listening forever', () async {
      final controller = buildWithWatchdog();
      await controller.start();
      speech.emitPartial('hello');

      // No further results and no end-of-speech status — a healthy session
      // would have closed at pauseFor long before the stall timeout.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(sentMessages, ['hello']);
      expect(controller.phase, VoiceModePhase.listening); // relistening
    });

    test('each new result re-arms the watchdog (no mid-speech finalize)',
        () async {
      final controller = buildWithWatchdog();
      await controller.start();

      // Keep partials flowing faster than the stall timeout — the watchdog
      // must not fire while the user is actively talking.
      for (var i = 0; i < 4; i++) {
        speech.emitPartial('word $i');
        await Future<void>.delayed(const Duration(milliseconds: 15));
      }
      expect(sentMessages, isEmpty);
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

  group('premature-endpoint continuation (mid-speech cutoff)', () {
    test(
        'a final hot on the heels of a partial keeps listening and stitches '
        'the segments into one utterance', () async {
      final controller = build(
        continuationGap: const Duration(milliseconds: 100),
      );
      await controller.start();

      speech.emitPartial('i wanna make');
      speech.emitFinal('i wanna make'); // gap ≈ 0 → premature cutoff
      await pumpEventQueue();

      expect(sentMessages, isEmpty); // nothing sent — mic reopened
      expect(controller.phase, VoiceModePhase.listening);
      expect(speech.listenCalls, 2);
      expect(controller.transcript, 'i wanna make');

      speech.emitPartial('a call tomorrow');
      expect(controller.transcript, 'i wanna make a call tomorrow');

      // A healthy endpoint (one full silence window after the last partial)
      // finalizes the stitched utterance.
      await Future<void>.delayed(const Duration(milliseconds: 130));
      speech.emitFinal('a call tomorrow');
      await pumpEventQueue();

      expect(sentMessages, ['i wanna make a call tomorrow']);
    });

    test('the dead session\'s trailing done-status cannot finalize the '
        'continuation listen early', () async {
      final controller = build(
        continuationGap: const Duration(milliseconds: 100),
        staleStatusWindow: const Duration(milliseconds: 400),
      );
      await controller.start();

      speech.emitPartial('i wanna make');
      speech.emitFinal('i wanna make');
      await pumpEventQueue();
      expect(speech.listenCalls, 2);

      // The old session's close status lands right as the new listen opens.
      speech.emitDone();
      await pumpEventQueue();
      expect(sentMessages, isEmpty);
      expect(controller.phase, VoiceModePhase.listening);
    });

    test(
        'identical re-emitted partials do not reset the endpoint clock '
        '(iOS re-scores during silence — over-wait bug)', () async {
      final controller = build(
        continuationGap: const Duration(milliseconds: 200),
      );
      await controller.start();

      speech.emitPartial('hello there');
      // Silence: iOS re-emits the SAME text while re-scoring…
      await Future<void>.delayed(const Duration(milliseconds: 250));
      speech.emitPartial('hello there');
      // …then the healthy endpoint. Gap must be measured from the last
      // text CHANGE (250ms ago), not the re-emission (0ms ago).
      speech.emitDone();
      await pumpEventQueue();

      expect(sentMessages, ['hello there']);
    });

    test('the old session replaying its words into the continuation listen '
        'does not double the utterance', () async {
      final controller = build(
        continuationGap: const Duration(milliseconds: 100),
        staleStatusWindow: const Duration(milliseconds: 400),
      );
      await controller.start();

      speech.emitPartial('hi how are you doing');
      speech.emitFinal('hi how are you doing'); // premature → continuation
      await pumpEventQueue();
      expect(speech.listenCalls, 2);

      // The dead session's delayed events land in the NEW session's
      // callback, replaying the same words cumulatively.
      speech.emitPartial('hi how are');
      speech.emitFinal('hi how are you doing');
      await pumpEventQueue();

      expect(sentMessages, isEmpty);
      expect(controller.transcript, 'hi how are you doing'); // not doubled
      expect(controller.phase, VoiceModePhase.listening);

      // Orb tap ends the (silent) continuation — the single utterance is
      // sent once.
      await controller.onOrbTap();
      await pumpEventQueue();
      expect(sentMessages, ['hi how are you doing']);
    });

    test('orb tap while listening sends immediately — no continuation wait',
        () async {
      final controller = build(
        continuationGap: const Duration(hours: 1), // would otherwise stitch
      );
      await controller.start();

      speech.emitPartial('send this now');
      await controller.onOrbTap(); // fake stop() emits 'done'
      await pumpEventQueue();

      expect(sentMessages, ['send this now']);
    });
  });

  group('promptAndListen (voice-mode Edit Plan)', () {
    test('speaks the prompt and reopens the mic for the answer', () async {
      final controller = build();
      await controller.start();
      expect(speech.listenCalls, 1);

      await controller.promptAndListen('What should I change?');
      await pumpEventQueue();

      expect(tts.spoken, contains('What should I change?'));
      expect(controller.phase, VoiceModePhase.listening);
      expect(speech.listenCalls, 2);

      speech.emitFinal('move it to 9am');
      await pumpEventQueue();
      expect(sentMessages, ['move it to 9am']);
    });
  });

}
