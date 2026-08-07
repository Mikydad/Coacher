import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/voice_mode_controller.dart';
import 'package:sidepal/features/ai_assistant/application/voice_tts_resilience.dart';

class ScriptedTts implements VoiceTtsAdapter {
  ScriptedTts({this.failConfigure = false});

  bool failConfigure = false;
  bool failSpeak = false;
  final List<String> spoken = [];
  int configureCalls = 0;
  int stopCalls = 0;
  int releaseCalls = 0;

  @override
  Future<void> configure() async {
    configureCalls++;
    if (failConfigure) throw Exception('configure failed');
  }

  @override
  Future<void> speak(String text) async {
    if (failSpeak) throw Exception('speak failed');
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> release() async {
    releaseCalls++;
  }
}

void main() {
  late ScriptedTts primary;
  late ScriptedTts fallback;
  late DateTime now;

  ResilientVoiceTtsAdapter build() {
    primary = ScriptedTts();
    fallback = ScriptedTts();
    now = DateTime(2026, 8, 7, 12, 0, 0);
    return ResilientVoiceTtsAdapter(
      primary: primary,
      fallback: fallback,
      primaryCooldown: const Duration(seconds: 60),
      now: () => now,
    );
  }

  test('healthy primary speaks; fallback stays silent', () async {
    final tts = build();
    await tts.configure();
    await tts.speak('Hello there.');

    expect(primary.spoken, ['Hello there.']);
    expect(fallback.spoken, isEmpty);
  });

  test('primary speak failure degrades silently to the fallback', () async {
    final tts = build();
    await tts.configure();
    primary.failSpeak = true;

    await tts.speak('Hello there.');

    expect(primary.spoken, isEmpty);
    expect(fallback.spoken, ['Hello there.']);
  });

  test('after a failure the primary is skipped during cooldown', () async {
    final tts = build();
    await tts.configure();
    primary.failSpeak = true;
    await tts.speak('First.');

    // Primary healthy again, but within cooldown — not even attempted.
    primary.failSpeak = false;
    now = now.add(const Duration(seconds: 30));
    await tts.speak('Second.');
    expect(primary.spoken, isEmpty);
    expect(fallback.spoken, ['First.', 'Second.']);

    // Cooldown expired — primary restored.
    now = now.add(const Duration(seconds: 31));
    await tts.speak('Third.');
    expect(primary.spoken, ['Third.']);
    expect(fallback.spoken, ['First.', 'Second.']);
  });

  test('primary configure failure routes every reply to the fallback', () async {
    final tts = build();
    primary.failConfigure = true;
    await tts.configure();

    await tts.speak('Hello.');
    expect(primary.spoken, isEmpty);
    expect(fallback.spoken, ['Hello.']);
  });

  test('configure always configures the fallback floor', () async {
    final tts = build();
    primary.failConfigure = true;
    await tts.configure();
    expect(fallback.configureCalls, 1);
  });

  test('stop and release fan out to both adapters', () async {
    final tts = build();
    await tts.configure();
    await tts.stop();
    await tts.release();

    expect(primary.stopCalls, 1);
    expect(fallback.stopCalls, 1);
    expect(primary.releaseCalls, 1);
    expect(fallback.releaseCalls, 1);
  });
}
