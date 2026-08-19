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
import 'voice_speech_text.dart' show splitIntoSentences;

// OpenAI TTS over the aiSpeechStream endpoint (latency batch 4, 2026-08-19).
//
// HISTORY, because this file reversed course once: batch 2 tried true
// progressive playback — pipe the mp3 into a growing source and let
// AVPlayer start early. The device stage ledgers proved it never streamed:
// audible-minus-firstChunk tracked the server's pipeMs 1:1 on every turn,
// i.e. AVPlayer waits for EOF on an unbounded chunked mp3 no matter what
// (stall-avoidance off included). So batch 4 stopped gambling on player
// internals: split the reply into HEAD (first sentence) and TAIL (rest),
// fetch both as small COMPLETE clips in parallel over one keep-alive
// connection, and play them back-to-back. The head is short, so its full
// synthesis+download is ~1-2s warm — that is the time-to-first-audio, and
// the tail downloads while the head plays.
//
// Same VoiceTtsAdapter contract as every other voice backend — the
// ResilientVoiceTtsAdapter wrapping and the system-voice floor are
// untouched. A head failure throws (wrapper falls back for the whole
// reply); a tail-only failure is swallowed — the head was already heard,
// and the full text is on screen regardless.

/// A [StreamAudioSource] over an in-memory buffer.
///
/// Two modes:
/// - [GrowingBufferAudioSource.completed]: all bytes known up front —
///   reports honest lengths and range support, so AVPlayer starts
///   immediately (this is the batch-4 playback path).
/// - live (default ctor + [add]/[complete]): bytes still arriving —
///   kept for tests and future use; readers block until fed.
///
/// Pure Dart state machine (no platform calls) — unit-tested directly.
class GrowingBufferAudioSource extends StreamAudioSource {
  GrowingBufferAudioSource({String contentType = 'audio/mpeg'})
    : _contentType = contentType;

  /// A source whose full content is already known — honest lengths, range
  /// requests supported, playback can start without guessing.
  GrowingBufferAudioSource.completed(
    Uint8List bytes, {
    String contentType = 'audio/mpeg',
  }) : _contentType = contentType {
    add(bytes);
    complete();
  }

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
    final from = start ?? 0;
    if (_done) {
      // Everything is known: answer like a normal file server so the
      // player trusts the media and starts at once.
      final to = end == null ? _length : math.min(end, _length);
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: _length,
        contentLength: to - from,
        offset: from,
        contentType: _contentType,
        stream: Stream.value(_copyRange(from, to)),
      );
    }
    return StreamAudioResponse(
      rangeRequestsSupported: false,
      sourceLength: null,
      contentLength: null,
      offset: null,
      contentType: _contentType,
      stream: _bytesFrom(from, end),
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

/// Voice backend that synthesizes the reply as head-sentence + tail clips
/// through the aiSpeechStream endpoint over one keep-alive connection.
class StreamingOpenAiTtsVoiceAdapter implements VoiceTtsAdapter {
  StreamingOpenAiTtsVoiceAdapter({
    required this.endpoint,
    required this.idToken,
    this.connectTimeout = const Duration(seconds: 8),
    this.clipTimeout = const Duration(seconds: 20),
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final Uri endpoint;

  /// Fresh Firebase ID token per request (they expire hourly).
  final Future<String?> Function() idToken;

  /// Bounds token fetch + connect + response headers for the head clip.
  final Duration connectTimeout;

  /// Bounds a whole clip download — generous because the TAIL of a long
  /// reply legitimately takes several seconds to synthesize; it has the
  /// head's playback time to spare.
  final Duration clipTimeout;

  final http.Client Function() _clientFactory;
  final AudioPlayer _player = AudioPlayer();

  bool _configured = false;
  int _generation = 0;

  /// ONE keep-alive client for the whole session (created lazily, closed
  /// in [release]): the 2026-08-08 device log showed each turn paying a
  /// fresh TCP+TLS handshake because the old code built a client per
  /// speak(). Requests that die mid-body close their own socket, which is
  /// the disconnect signal the server watches to abort upstream OpenAI.
  http.Client? _http;
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
    }
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    final generation = ++_generation;
    final t2 = DateTime.now();

    final sentences = splitIntoSentences(text);
    if (sentences.isEmpty) return;
    final head = sentences.first;
    final tail = sentences.skip(1).join(' ');

    // Both clips start NOW: the tail synthesizes server-side while the
    // head downloads and plays. Head failure throws (nothing spoken yet,
    // wrapper falls back); tail failure resolves null and is swallowed.
    final headFuture = _fetchClip(head, connectTimeout);
    final Future<Uint8List?>? tailFuture = tail.isEmpty
        ? null
        : _fetchClip(
            tail,
            clipTimeout,
          ).then<Uint8List?>((b) => b, onError: (_) => null);

    final headBytes = await headFuture;
    if (generation != _generation) return;
    final t3 = DateTime.now();

    if (kDebugMode) {
      unawaited(
        _player.playingStream.firstWhere((playing) => playing).then((_) {
          final t4 = DateTime.now();
          debugPrint(
            '[voice-timing] tts headClip=${t3.difference(t2).inMilliseconds}ms '
            'audible=${t4.difference(t2).inMilliseconds}ms '
            'chars=${text.length}',
          );
        }),
      );
    }

    await _playClip(headBytes, generation);
    if (tailFuture == null || generation != _generation) return;

    final tailBytes = await tailFuture;
    if (tailBytes == null || generation != _generation) return;
    await _playClip(tailBytes, generation);
  }

  /// POSTs [text] and buffers the complete mp3 clip. The endpoint streams;
  /// we simply read to the end — for a head sentence that is ~1-2s total,
  /// and the response begins flowing before synthesis finishes.
  Future<Uint8List> _fetchClip(String text, Duration timeout) async {
    final token = await idToken();
    if (token == null || token.isEmpty) {
      throw StateError('No auth token for speech streaming');
    }

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

    final bytes = await response.stream.toBytes().timeout(timeout);
    if (bytes.isEmpty) {
      throw StateError('Speech stream was empty');
    }
    return bytes;
  }

  Future<void> _playClip(Uint8List bytes, int generation) async {
    if (generation != _generation) return;
    final done = Completer<void>();
    _speaking = done;
    final stateSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !done.isCompleted) {
        done.complete();
      }
    });
    try {
      await _player.setAudioSource(GrowingBufferAudioSource.completed(bytes));
      if (generation != _generation) return;
      final playFuture = _player.play();
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
  }

  @override
  Future<void> stop() async {
    _generation++;
    // Wake the speak() latch first so it unwinds promptly.
    final speaking = _speaking;
    if (speaking != null && !speaking.isCompleted) speaking.complete();
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
