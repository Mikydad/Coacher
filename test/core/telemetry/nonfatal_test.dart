import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/telemetry/nonfatal.dart';

void main() {
  late List<(Object, String)> sent;
  late DateTime now;

  NonfatalReporter build({int max = 20}) {
    sent = [];
    now = DateTime(2026, 9, 15, 12);
    return NonfatalReporter(
      sink: (e, st, reason) async => sent.add((e, reason)),
      maxPerSession: max,
      dedupeWindow: const Duration(seconds: 60),
      now: () => now,
    );
  }

  test('sends a sanitized error: tag + type + code, never the message', () async {
    final r = build();
    await r.report(
      'sync.remotePull',
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'Alice: secret task title'),
    );
    expect(sent, hasLength(1));
    final (e, reason) = sent.single;
    expect(reason, 'sync.remotePull');
    expect(e, isA<SanitizedNonfatal>());
    expect(e.toString(), contains('FirebaseException/unavailable'));
    expect(e.toString(), isNot(contains('secret')));
  });

  test('dedupes the same site + type within the window, then reports again', () async {
    final r = build();
    await r.report('a', StateError('x'));
    await r.report('a', StateError('y'));
    expect(sent, hasLength(1));
    now = now.add(const Duration(seconds: 61));
    await r.report('a', StateError('z'));
    expect(sent, hasLength(2));
  });

  test('different sites or types are separate keys', () async {
    final r = build();
    await r.report('a', StateError('x'));
    await r.report('b', StateError('x'));
    await r.report('a', ArgumentError('x'));
    expect(sent, hasLength(3));
  });

  test('caps reports per session', () async {
    final r = build(max: 2);
    await r.report('a', StateError('x'));
    await r.report('b', StateError('x'));
    await r.report('c', StateError('x'));
    expect(sent, hasLength(2));
    expect(r.sentCount, 2);
  });

  test('a throwing sink never propagates', () async {
    final r = NonfatalReporter(sink: (_, __, ___) async => throw StateError('boom'));
    await r.report('a', StateError('x'));
  });
}
