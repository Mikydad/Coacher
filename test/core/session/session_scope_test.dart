import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/session/session_scope.dart';

void main() {
  setUp(SessionScope.resetForTests);
  tearDown(SessionScope.resetForTests);

  test('a token captured before teardown is stale afterwards', () {
    final token = SessionScope.capture();
    expect(token.isCurrent, isTrue);
    SessionScope.beginTeardown();
    expect(token.isCurrent, isFalse);
    SessionScope.endTeardown();
    expect(token.isCurrent, isFalse, reason: 'generation moved on');
  });

  test('nothing captured DURING teardown is current (dispose-triggered jobs)', () {
    SessionScope.beginTeardown();
    final duringTeardown = SessionScope.capture();
    expect(duringTeardown.isCurrent, isFalse);
    expect(SessionScope.isTearingDown, isTrue);
    SessionScope.endTeardown();
    // Same generation, teardown over → current again (the next account's
    // first jobs capture after endTeardown, so this is the expected state).
    expect(duringTeardown.isCurrent, isTrue);
  });

  test('whenIdle resolves at once outside a teardown', () async {
    var resolved = false;
    unawaited(SessionScope.whenIdle.then((_) => resolved = true));
    await Future<void>.delayed(Duration.zero);
    expect(resolved, isTrue);
  });

  test('whenIdle waits for endTeardown during a wipe', () async {
    SessionScope.beginTeardown();
    var resolved = false;
    unawaited(SessionScope.whenIdle.then((_) => resolved = true));
    await Future<void>.delayed(Duration.zero);
    expect(resolved, isFalse, reason: 'wipe still running');
    SessionScope.endTeardown();
    await Future<void>.delayed(Duration.zero);
    expect(resolved, isTrue);
  });

  test('ensureCurrent throws a StaleSessionError once the session ended', () {
    final token = SessionScope.capture();
    token.ensureCurrent('job');
    SessionScope.beginTeardown();
    expect(() => token.ensureCurrent('job'), throwsA(isA<StaleSessionError>()));
  });

  test('double begin is harmless: every earlier token stays stale', () {
    final a = SessionScope.capture();
    SessionScope.beginTeardown();
    SessionScope.beginTeardown();
    SessionScope.endTeardown();
    expect(a.isCurrent, isFalse);
    expect(SessionScope.capture().isCurrent, isTrue);
  });
}
