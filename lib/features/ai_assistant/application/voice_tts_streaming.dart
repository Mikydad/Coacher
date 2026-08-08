// StreamAudioSource is annotated @experimental in just_audio 0.10 — it has
// been the documented custom-source API for years and the whole point of
// this adapter. Accepted deliberately; a breaking change surfaces here.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'voice_mode_controller.dart' show VoiceTtsAdapter;

// Streaming OpenAI TTS for Voice Mode (latency batch 2, spike 2026-08-08).
//
// The buffered adapter waits for the whole first-sentence clip before any
// sound; this one plays OpenAI's mp3 bytes AS THEY ARRIVE from the
// aiSpeechStream endpoint, so time-to-first-audio is network + first
// chunks instead of a full synthesis. POST body carries the text (never a
// URL — request paths land in server logs); auth is the Firebase ID token.
//
// Same VoiceTtsAdapter contract as every other voice backend — the
// ResilientVoiceTtsAdapter wrapping and the system-voice floor are
// untouched. Any failure here throws, and the wrapper degrades silently.

/// A [StreamAudioSource] over bytes that are still arriving.
///
/// just_audio's local proxy reads this through a single non-range request
/// ([rangeRequestsSupported] is false): the stream yields what is buffered,
/// then live-follows [add] calls until [complete].
///
/// Pure Dart state machine (no platform calls) — unit-tested directly.
class GrowingBufferAudioSource extends StreamAudioSource {
  GrowingBufferAudioSource({String contentType = 'audio/mpeg'})
    : _contentType = contentType;

  final String _contentType;
  final List<List<int>> _chunks = [];
  int _length = 0;
  bool _done = false;
  final StreamController<void> _wake = StreamController<void>.broadcast();

  int get bufferedBytes => _length;
  bool get isComplete => _done;

  /// Appends bytes from the network. Ignored after [complete].
  void add(List<int> chunk) {
    if (_done || chunk.isEmpty) return;
    _chunks.add(chunk);
    _length += chunk.length;
    _wake.add(null);
  }

  /// Marks the source as fully delivered — readers finish once they have
  /// emitted everything buffered.
  void complete() {
    if (_done) return;
    _done = true;
    _wake.add(null);
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      rangeRequestsSupported: false,
      sourceLength: null,
      contentLength: null,
      offset: null,
      contentType: _contentType,
      stream: _bytesFrom(start ?? 0, end),
    );
  }

  Stream<List<int>> _bytesFrom(int start, int? end) async* {
    var position = start;
    while (true) {
      final available = end == null ? _length : math.min(end, _length);
      if (position < available) {
        final bytes = _copyRange(position, available);
        position = available;
        yield bytes;
        continue;
      }
      // Everything currently buffered has been emitted.
      if (_done) break;
      // Single-threaded Dart: add()/complete() cannot run between the
      // checks above and this await, so a wake-up can't be missed.
      await _wake.stream.first;
    }
  }

  Uint8List _copyRange(int from, int to) {
    final out = Uint8List(to - from);
    var chunkStart = 0;
    var written = 0;
    for (final chunk in _chunks) {
      final chunkEnd = chunkStart + chunk.length;
      if (chunkEnd > from && chunkStart < to) {
        final sliceFrom = math.max(from, chunkStart) - chunkStart;
        final sliceTo = math.min(to, chunkEnd) - chunkStart;
        out.setRange(
          written,
          written + (sliceTo - sliceFrom),
          chunk.sublist(sliceFrom, sliceTo),
        );
        written += sliceTo - sliceFrom;
      }
      chunkStart = chunkEnd;
      if (chunkStart >= to) break;
    }
    return out;
  }
}

/// Voice backend that streams synthesis from the aiSpeechStream endpoint
/// and starts playback on the first buffered chunks.
class StreamingOpenAiTtsVoiceAdapter implements VoiceTtsAdapter {
  StreamingOpenAiTtsVoiceAdapter({
    required this.endpoint,
    required this.idToken,
    this.connectTimeout = const Duration(seconds: 8),
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final Uri endpoint;

  /// Fresh Firebase ID token per request (they expire hourly).
  final Future<String?> Function() idToken;

  /// Bounds token fetch + connect + first audio byte — NOT the whole
  /// stream; a long reply keeps trickling while earlier bytes play.
  final Duration connectTimeout;

  final http.Client Function() _clientFactory;
  final AudioPlayer _player = AudioPlayer();

  bool _configured = false;
  int _generation = 0;

  /// ONE keep-alive client for the whole session (created lazily, closed
  /// in [release]): the 2026-08-08 device log showed firstChunk tracking
  /// the reply leg almost 1:1 — each turn was paying a fresh TCP+TLS
  /// handshake to us-central1 because the old code built a client per
  /// speak(). Interrupts cancel the response subscription instead of
  /// closing the client; dart:io tears down that request's socket on
  /// cancel, so the server still sees the disconnect and aborts upstream.
  http.Client? _http;
  StreamSubscription<List<int>>? _activeSub;
  Completer<void>? _speaking;

  http.Client get _client => _http ??= _clientFactory();

  @override
  Future<void> configure() async {
    if (_configured) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // The exact session contract every other voice actor uses (the
      // earpiece lesson): share with the mic, force the main speaker.
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp |
              AVAudioSessionCategoryOptions.duckOthers,
        ),
      );
      // The device gate (2026-08-08) showed bytes sitting on the phone for
      // ~2.9s before sound: AVPlayer's stall-avoidance pre-buffers streams
      // it can't measure (chunked, no length). Voice replies are short and
      // synthesis outpaces playback, so start the moment audio is decodable;
      // worst case on a bad link is a mid-sentence pause, and the full text
      // is on screen regardless.
      await _player.setAutomaticallyWaitsToMinimizeStalling(false);
    }
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    final generation = ++_generation;
    final t2 = DateTime.now();

    final token = await idToken();
    if (token == null || token.isEmpty) {
      throw StateError('No auth token for speech streaming');
    }
    if (generation != _generation) return;

    final request = http.Request('POST', endpoint)
      ..headers['authorization'] = 'Bearer $token'
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({'text': text});

    final response = await _client.send(request).timeout(connectTimeout);
    if (response.statusCode != 200) {
      // Drain so the keep-alive connection returns to the pool healthy.
      unawaited(response.stream.drain<void>().catchError((_) {}));
      throw http.ClientException(
        'aiSpeechStream HTTP ${response.statusCode}',
        endpoint,
      );
    }
    if (generation != _generation) {
      unawaited(response.stream.drain<void>().catchError((_) {}));
      return;
    }

    final source = GrowingBufferAudioSource();
    final firstChunk = Completer<void>();
    final sub = response.stream.listen(
      (chunk) {
        source.add(chunk);
        if (!firstChunk.isCompleted) firstChunk.complete();
      },
      onDone: () {
        source.complete();
        if (!firstChunk.isCompleted) {
          firstChunk.completeError(StateError('Speech stream was empty'));
        }
      },
      onError: (Object error) {
        // Mid-stream drop: end the clip so the player finishes what it
        // has — the full text is on screen regardless.
        source.complete();
        if (!firstChunk.isCompleted) firstChunk.completeError(error);
      },
      cancelOnError: true,
    );
    _activeSub = sub;

    try {
      final done = Completer<void>();
      _speaking = done;
      final stateSub = _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed && !done.isCompleted) {
          done.complete();
        }
      });

      try {
        // Player prep (local proxy + AVPlayerItem, ~1s cold) runs WHILE
        // the network works on the first byte — serialized, that startup
        // was most of the audible-after-firstChunk lag in the device log.
        var setSourceFailed = false;
        final setSource = _player
            .setAudioSource(source)
            .then<void>((_) {}, onError: (_) => setSourceFailed = true);

        // Still gate audio on the first real bytes: a pre-audio failure
        // must throw (so the resilient wrapper falls back) instead of
        // handing AVPlayer an empty stream.
        await firstChunk.future.timeout(connectTimeout);
        if (generation != _generation) return;
        final t3 = DateTime.now();

        await setSource;
        if (setSourceFailed) {
          throw StateError('Player failed to open the speech stream');
        }
        if (generation != _generation) return;
        final playFuture = _player.play();
        if (kDebugMode) {
          unawaited(
            _player.playingStream.firstWhere((playing) => playing).then((_) {
              final t4 = DateTime.now();
              debugPrint(
                '[voice-timing] tts firstChunk=${t3.difference(t2).inMilliseconds}ms '
                'audible=${t4.difference(t2).inMilliseconds}ms '
                'chars=${text.length}',
              );
            }),
          );
        }
        await done.future;
        await playFuture.catchError((_) {});
      } finally {
        await stateSub.cancel();
        if (identical(_speaking, done)) _speaking = null;
        // Idle the player so the next setAudioSource starts clean.
        try {
          await _player.stop();
        } catch (_) {}
      }
    } finally {
      // Cancelling before the body finished tears down this request's
      // socket (dart:io never pools a half-read connection) — that is the
      // disconnect the server watches to abort its OpenAI request. The
      // keep-alive client itself stays open for the next turn.
      await sub.cancel();
      if (identical(_activeSub, sub)) _activeSub = null;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    // Wake the speak() latch first so it unwinds promptly.
    final speaking = _speaking;
    if (speaking != null && !speaking.isCompleted) speaking.complete();
    await _activeSub?.cancel();
    _activeSub = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    await stop();
    _http?.close();
    _http = null;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
