import 'package:sidepal/features/ai_assistant/application/shared_speech_callbacks.dart';
import 'package:sidepal/features/ai_assistant/application/voice_mode_adapters.dart';
import 'package:sidepal/features/ai_assistant/application/voice_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice reliability (fix-wave Phase 4, AUDIT.md §8 V1/V3/V6):
/// the shared callback registry that unfreezes STT events from the first
/// initializer, the endpointing invariant that caused the 2026-08-26 dead
/// zone, and the lifecycle pause that stops the orb lying after a phone
/// call.

class _Fakes {
  final speech = _FakeSpeech();
  final tts = _FakeTts();

  VoiceModeController controller({
    Future<String?> Function(String)? send,
  }) => VoiceModeController(
    speech: speech,
    tts: tts,
    sendAndGetReply: send ?? (_) async => 'ok',
  );
}

class _FakeSpeech implements VoiceSpeechAdapter {
  void Function(String status)? onStatus;
  void Function(String text, bool isFinal)? onResult;
  int stopCalls = 0;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function() onError,
  }) async {
    this.onStatus = onStatus;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    this.onResult = onResult;
    onStatus?.call('listening');
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakeTts implements VoiceTtsAdapter {
  int stopCalls = 0;

  @override
  Future<void> configure() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> release() async {}
}

void main() {
  tearDown(() {
    // Force-clear the process-wide registry between tests.
    SharedSpeechCallbacks.claim(
      _anyOwner,
      speech: SpeechToText(),
      onStatus: (_) {},
      onError: () {},
    );
    SharedSpeechCallbacks.release(_anyOwner);
  });

  group('SharedSpeechCallbacks (§8 V1 — the frozen-listener bug)', () {
    test('the last claimer receives events; earlier claimers go quiet', () {
      final speech = SpeechToText();
      final first = <String>[];
      final second = <String>[];

      SharedSpeechCallbacks.claim(
        'owner-1',
        speech: speech,
        onStatus: first.add,
        onError: () {},
      );
      SharedSpeechCallbacks.dispatchStatus('listening');

      SharedSpeechCallbacks.claim(
        'owner-2',
        speech: speech,
        onStatus: second.add,
        onError: () {},
      );
      SharedSpeechCallbacks.dispatchStatus('done');

      expect(first, ['listening']);
      expect(second, ['done']);
    });

    test('claim pins the plugin PUBLIC listener fields to the dispatchers',
        () {
      // The load-bearing mechanism: initialize() refuses to re-register
      // once initialized, but these fields stay assignable.
      final speech = SpeechToText();
      SharedSpeechCallbacks.claim(
        'owner',
        speech: speech,
        onStatus: (_) {},
        onError: () {},
      );
      expect(speech.statusListener, SharedSpeechCallbacks.dispatchStatus);
      expect(speech.errorListener, SharedSpeechCallbacks.dispatchError);
    });

    test('release only clears when the releasing owner still holds', () {
      final speech = SpeechToText();
      final seen = <String>[];
      SharedSpeechCallbacks.claim(
        'owner-1',
        speech: speech,
        onStatus: seen.add,
        onError: () {},
      );
      SharedSpeechCallbacks.claim(
        'owner-2',
        speech: speech,
        onStatus: seen.add,
        onError: () {},
      );
      // owner-1 going away must not tear down owner-2's routing.
      SharedSpeechCallbacks.release('owner-1');
      SharedSpeechCallbacks.dispatchStatus('done');
      expect(seen, ['done']);
    });
  });

  test(
      'endpointing invariant: the adapter pauseFor stays ABOVE the '
      'controller continuationGap (the 2026-08-26 dead zone)', () {
    final fakes = _Fakes();
    final controller = fakes.controller();
    expect(
      SpeechToTextVoiceAdapter.pauseFor > controller.continuationGap,
      isTrue,
      reason:
          'pauseFor (${SpeechToTextVoiceAdapter.pauseFor}) must exceed '
          'continuationGap (${controller.continuationGap}) — endpoints '
          'landing between them counted as healthy and shipped half '
          'sentences. The pair moves together.',
    );
    controller.dispose();
  });

  group('pauseToIdle (§8 V3 — lifecycle honesty)', () {
    test('parks the loop at idle with honest copy and stops both legs',
        () async {
      final fakes = _Fakes();
      final controller = fakes.controller();
      await controller.start();
      expect(controller.phase, VoiceModePhase.listening);

      await controller.pauseToIdle();

      expect(controller.phase, VoiceModePhase.idle);
      expect(controller.statusMessage, contains('Paused'));
      expect(fakes.speech.stopCalls, greaterThan(0));
      expect(fakes.tts.stopCalls, greaterThan(0));
      controller.dispose();
    });

    test('a late result from the paused listen is ignored', () async {
      final fakes = _Fakes();
      final sent = <String>[];
      final controller = fakes.controller(
        send: (text) async {
          sent.add(text);
          return 'ok';
        },
      );
      await controller.start();
      final onResult = fakes.speech.onResult!;
      await controller.pauseToIdle();

      // The dead listen's endpoint straggles in after the pause.
      onResult('hello there', true);
      await Future<void>.delayed(Duration.zero);

      expect(sent, isEmpty);
      expect(controller.phase, VoiceModePhase.idle);
      controller.dispose();
    });
  });
}

const _anyOwner = 'test-cleanup';
