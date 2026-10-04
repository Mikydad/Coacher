import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/bootstrap/first_screen_ready.dart';

void main() {
  setUp(FirstScreenReady.resetForTests);
  tearDown(FirstScreenReady.resetForTests);

  test('mark completes the future once and is idempotent', () async {
    expect(FirstScreenReady.isReady, isFalse);
    FirstScreenReady.mark('test');
    FirstScreenReady.mark('again');
    expect(FirstScreenReady.isReady, isTrue);
    await FirstScreenReady.future;
  });

  test(
    'wait resolves after the timeout when nothing marks readiness',
    () async {
      await FirstScreenReady.wait(timeout: const Duration(milliseconds: 20));
      expect(FirstScreenReady.isReady, isFalse);
    },
  );

  test('wait resolves early once marked', () async {
    final w = FirstScreenReady.wait(timeout: const Duration(seconds: 30));
    FirstScreenReady.mark('early');
    await w;
    expect(FirstScreenReady.isReady, isTrue);
  });
}
