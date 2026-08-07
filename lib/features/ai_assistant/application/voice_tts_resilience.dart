import 'voice_mode_controller.dart';

/// Optimistic-then-honest composition of two TTS adapters: try the
/// network voice (OpenAI TTS via aiSpeech), degrade SILENTLY to the
/// on-device system voice on any failure — offline, quota, kill switch.
/// The conversation never stalls and no error UI exists; the only symptom
/// of degradation is the voice itself.
///
/// After a primary failure the primary is skipped for [primaryCooldown]
/// so an offline stretch doesn't pay the synthesis timeout on every
/// single reply; one success (or cooldown expiry) restores it.
///
/// Plugin-free by construction — unit-tested with fakes in
/// voice_tts_resilience_test.dart.
class ResilientVoiceTtsAdapter implements VoiceTtsAdapter {
  ResilientVoiceTtsAdapter({
    required this.primary,
    required this.fallback,
    this.primaryCooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VoiceTtsAdapter primary;
  final VoiceTtsAdapter fallback;
  final Duration primaryCooldown;
  final DateTime Function() _now;

  bool _primaryConfigured = false;
  DateTime? _lastPrimaryFailureAt;

  @override
  Future<void> configure() async {
    try {
      await primary.configure();
      _primaryConfigured = true;
    } catch (_) {
      _primaryConfigured = false;
    }
    // The fallback MUST configure — it is the floor the whole voice loop
    // stands on. Its errors propagate like the single-adapter setup did.
    await fallback.configure();
  }

  bool get _primaryOnCooldown {
    final last = _lastPrimaryFailureAt;
    return last != null && _now().difference(last) < primaryCooldown;
  }

  @override
  Future<void> speak(String text) async {
    if (_primaryConfigured && !_primaryOnCooldown) {
      try {
        await primary.speak(text);
        _lastPrimaryFailureAt = null;
        return;
      } catch (_) {
        _lastPrimaryFailureAt = _now();
      }
    }
    await fallback.speak(text);
  }

  @override
  Future<void> stop() async {
    try {
      await primary.stop();
    } catch (_) {}
    try {
      await fallback.stop();
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    try {
      await primary.release();
    } catch (_) {}
    try {
      await fallback.release();
    } catch (_) {}
  }
}
