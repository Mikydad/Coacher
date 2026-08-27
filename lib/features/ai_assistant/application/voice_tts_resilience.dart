import 'dart:async';

import 'voice_mode_controller.dart';
import 'voice_speech_text.dart' show sanitizeForSpeech;

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
class ResilientVoiceTtsAdapter
    implements VoiceTtsAdapter, VoiceTtsStreamCapable {
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

  /// Cancels the degraded-mode delta buffering; set only while buffering.
  void Function()? _cancelBuffered;

  /// Bumped by [stop]/[release]. A speak() whose generation went stale
  /// mid-flight was cancelled by the user — it must NOT proceed to the
  /// fallback, or the full stale reply speaks over the re-opened mic (or
  /// after Voice Mode closed): the primary tends to throw exactly when the
  /// user gives up waiting and taps (Tier-1 review fix, "ghost speech").
  int _generation = 0;

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
    final generation = _generation;
    if (_primaryConfigured && !_primaryOnCooldown) {
      try {
        await primary.speak(text);
        _lastPrimaryFailureAt = null;
        return;
      } catch (_) {
        // A stale generation means OUR OWN stop() killed the in-flight
        // clip fetch — the class doc's "the primary tends to throw exactly
        // when the user taps" case. Recording that as a primary failure
        // put the good voice on a 60s cooldown every time an interactive
        // user interrupted (fix-wave Phase 4, §8 V2 / GPT-5.6 G20).
        if (generation == _generation) _lastPrimaryFailureAt = _now();
      }
    }
    // Cancelled while the primary was failing — swallow, don't ghost-speak.
    if (generation != _generation) return;
    await fallback.speak(text);
  }

  /// Level 2: pipeline through the primary when it is stream-capable and
  /// healthy; otherwise (or on failure) buffer the full reply and degrade
  /// through the normal [speak] path. Primary failures cluster at the
  /// first clip — nothing audible yet — so falling back with the WHOLE
  /// reply matches the buffered path's semantics.
  @override
  Future<void> speakStream(Stream<String> deltas) async {
    final generation = _generation;
    final primaryAdapter = primary;
    final canPipeline =
        _primaryConfigured &&
        !_primaryOnCooldown &&
        primaryAdapter is VoiceTtsStreamCapable;
    if (!canPipeline) {
      // Cancellable buffering (§8 V2's second half): `deltas.forEach` had
      // no way to stop, so during a cooldown an interrupt left the model
      // stream generating to completion while the orb claimed SPEAKING
      // into silence — and later interrupts stopped nothing.
      final full = StringBuffer();
      final done = Completer<void>();
      final sub = deltas.listen(
        full.write,
        onError: (Object _) {
          if (!done.isCompleted) done.complete();
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      _cancelBuffered = () {
        if (!done.isCompleted) done.complete();
        unawaited(sub.cancel());
      };
      await done.future;
      _cancelBuffered = null;
      await sub.cancel();
      if (generation != _generation) return;
      final text = sanitizeForSpeech(full.toString());
      if (text.isEmpty) return;
      await speak(text);
      return;
    }

    // Tee: the primary consumes live; the buffer keeps the full text for
    // the fallback should the primary fail mid-reply.
    final buffered = StringBuffer();
    final tee = StreamController<String>();
    final sub = deltas.listen(
      (d) {
        buffered.write(d);
        if (!tee.isClosed) tee.add(d);
      },
      onError: (Object e) {
        if (!tee.isClosed) tee.addError(e);
      },
      onDone: () {
        if (!tee.isClosed) tee.close();
      },
    );
    try {
      await (primaryAdapter as VoiceTtsStreamCapable).speakStream(tee.stream);
      _lastPrimaryFailureAt = null;
    } catch (_) {
      if (generation == _generation) _lastPrimaryFailureAt = _now();
      // Let the reply finish arriving, then speak it via the floor voice.
      await sub.asFuture<void>().catchError((_) {});
      if (generation != _generation) return;
      final text = sanitizeForSpeech(buffered.toString());
      if (text.isNotEmpty) await fallback.speak(text);
    } finally {
      await sub.cancel();
      if (!tee.isClosed) await tee.close();
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    _cancelBuffered?.call();
    _cancelBuffered = null;
    try {
      await primary.stop();
    } catch (_) {}
    try {
      await fallback.stop();
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    _generation++;
    try {
      await primary.release();
    } catch (_) {}
    try {
      await fallback.release();
    } catch (_) {}
  }
}
