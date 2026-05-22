import 'package:coach_for_life/features/context_override/application/override_attention_policy.dart';
import 'package:coach_for_life/features/context_override/domain/models/context_override.dart';
import 'package:coach_for_life/features/context_override/domain/models/interruption_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverrideAttentionPolicy.shouldSuppress — all 24 cases', () {
    // Helper to make test names readable.
    String c(ContextOverride o, InterruptionLevel l) => '${o.name} × ${l.name}';

    // ─── none ─────────────────────────────────────────────────────────────
    test(c(ContextOverride.none, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.none), isFalse);
    });
    test(c(ContextOverride.none, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.none), isFalse);
    });
    test(c(ContextOverride.none, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.none), isFalse);
    });
    test(c(ContextOverride.none, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.none), isFalse);
    });

    // ─── meeting ──────────────────────────────────────────────────────────
    test(c(ContextOverride.meeting, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.meeting), isTrue);
    });
    test(c(ContextOverride.meeting, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.meeting), isTrue);
    });
    test(c(ContextOverride.meeting, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.meeting), isFalse);
    });
    test(c(ContextOverride.meeting, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.meeting), isFalse);
    });

    // ─── focus ────────────────────────────────────────────────────────────
    test(c(ContextOverride.focus, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.focus), isTrue);
    });
    test(c(ContextOverride.focus, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.focus), isTrue);
    });
    test(c(ContextOverride.focus, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.focus), isFalse);
    });
    test(c(ContextOverride.focus, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.focus), isFalse);
    });

    // ─── sleep ────────────────────────────────────────────────────────────
    test(c(ContextOverride.sleep, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.sleep), isTrue);
    });
    test(c(ContextOverride.sleep, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.sleep), isTrue);
    });
    test(c(ContextOverride.sleep, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.sleep), isTrue);
    });
    test(c(ContextOverride.sleep, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.sleep), isFalse);
    });

    // ─── vacation ─────────────────────────────────────────────────────────
    test(c(ContextOverride.vacation, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.vacation), isTrue);
    });
    test(c(ContextOverride.vacation, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.vacation), isTrue);
    });
    test(c(ContextOverride.vacation, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.vacation), isTrue);
    });
    test(c(ContextOverride.vacation, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.vacation), isFalse);
    });

    // ─── doNotDisturb ─────────────────────────────────────────────────────
    test(c(ContextOverride.doNotDisturb, InterruptionLevel.low), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.low, ContextOverride.doNotDisturb), isTrue);
    });
    test(c(ContextOverride.doNotDisturb, InterruptionLevel.medium), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.medium, ContextOverride.doNotDisturb), isTrue);
    });
    test(c(ContextOverride.doNotDisturb, InterruptionLevel.high), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.high, ContextOverride.doNotDisturb), isTrue);
    });
    test(c(ContextOverride.doNotDisturb, InterruptionLevel.critical), () {
      expect(OverrideAttentionPolicy.shouldSuppress(
          InterruptionLevel.critical, ContextOverride.doNotDisturb), isTrue);
    });
  });

  group('OverrideAttentionPolicy.suppressesAll', () {
    test('only doNotDisturb returns true', () {
      expect(OverrideAttentionPolicy.suppressesAll(ContextOverride.doNotDisturb), isTrue);
      for (final o in ContextOverride.values) {
        if (o != ContextOverride.doNotDisturb) {
          expect(OverrideAttentionPolicy.suppressesAll(o), isFalse);
        }
      }
    });
  });
}
