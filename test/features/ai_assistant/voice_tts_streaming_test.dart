import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/voice_tts_streaming.dart';

// GrowingBufferAudioSource is the pure heart of the streaming TTS spike:
// just_audio's proxy reads it while the network is still appending bytes.
// These tests exercise exactly that read-while-writing contract.

Future<List<int>> collect(Stream<List<int>> stream) async {
  final out = <int>[];
  await for (final chunk in stream) {
    out.addAll(chunk);
  }
  return out;
}

void main() {
  group('GrowingBufferAudioSource', () {
    test('serves bytes buffered before the request, then ends on complete',
        () async {
      final source = GrowingBufferAudioSource();
      source.add([1, 2, 3]);
      source.add([4, 5]);
      source.complete();

      final response = await source.request();
      expect(await collect(response.stream), [1, 2, 3, 4, 5]);
      // Complete at request time → honest file-server semantics (batch 4).
      expect(response.rangeRequestsSupported, isTrue);
      expect(response.sourceLength, 5);
      expect(response.contentType, 'audio/mpeg');
    });

    test('live-follows bytes that arrive after the reader started', () async {
      final source = GrowingBufferAudioSource();
      source.add([1]);

      final response = await source.request();
      final reading = collect(response.stream);

      // Let the reader drain what exists and block on the wake stream.
      await Future<void>.delayed(Duration.zero);
      source.add([2, 3]);
      await Future<void>.delayed(Duration.zero);
      source.add([4]);
      source.complete();

      expect(await reading, [1, 2, 3, 4]);
    });

    test('a reader joining an already-complete source gets everything',
        () async {
      final source = GrowingBufferAudioSource();
      source.add(List.generate(10, (i) => i));
      source.complete();

      final response = await source.request();
      expect(await collect(response.stream), List.generate(10, (i) => i));
    });

    test('empty completed source yields an empty stream (no hang)', () async {
      final source = GrowingBufferAudioSource();
      source.complete();

      final response = await source.request();
      expect(await collect(response.stream), isEmpty);
    });

    test('adds after complete are ignored', () async {
      final source = GrowingBufferAudioSource();
      source.add([1]);
      source.complete();
      source.add([9, 9, 9]);

      final response = await source.request();
      expect(await collect(response.stream), [1]);
      expect(source.bufferedBytes, 1);
    });

    test('honors start/end offsets across chunk boundaries', () async {
      final source = GrowingBufferAudioSource();
      source.add([0, 1, 2]);
      source.add([3, 4, 5, 6]);
      source.add([7, 8]);
      source.complete();

      // start mid-first-chunk, end mid-last-chunk.
      final response = await source.request(1, 8);
      expect(await collect(response.stream), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('two concurrent readers each get the full byte sequence', () async {
      final source = GrowingBufferAudioSource();
      source.add([1, 2]);

      final a = collect((await source.request()).stream);
      final b = collect((await source.request()).stream);

      await Future<void>.delayed(Duration.zero);
      source.add([3]);
      source.complete();

      expect(await a, [1, 2, 3]);
      expect(await b, [1, 2, 3]);
    });

    test('completed source answers like a file server (honest lengths)',
        () async {
      final source = GrowingBufferAudioSource.completed(
        Uint8List.fromList([10, 20, 30, 40, 50]),
      );

      final full = await source.request();
      expect(full.rangeRequestsSupported, isTrue);
      expect(full.sourceLength, 5);
      expect(full.contentLength, 5);
      expect(full.offset, 0);
      expect(await collect(full.stream), [10, 20, 30, 40, 50]);
    });

    test('completed source serves range requests with correct metadata',
        () async {
      final source = GrowingBufferAudioSource.completed(
        Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]),
      );

      final range = await source.request(2, 6);
      expect(range.sourceLength, 8);
      expect(range.contentLength, 4);
      expect(range.offset, 2);
      expect(await collect(range.stream), [2, 3, 4, 5]);
    });
  });
}
