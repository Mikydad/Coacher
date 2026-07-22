import 'package:sidepal/features/context_override/application/sleep_window_util.dart';
import 'package:sidepal/features/context_override/domain/models/context_override.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers
  UserAttentionState makeVacationState({
    required int startMs,
    int? endMs,
    bool stillActive = false,
  }) {
    return UserAttentionState(
      id: kUserAttentionStateId,
      activeOverride:
          stillActive ? ContextOverride.vacation : ContextOverride.none,
      manuallyMuted: false,
      updatedAtMs: 0,
      lastOverrideActivatedAt: startMs,
      lastAttentionResetAt: endMs,
    );
  }

  group('vacationWindowContains', () {
    final vacationStart = DateTime(2026, 5, 10).millisecondsSinceEpoch;
    final vacationEnd = DateTime(2026, 5, 15).millisecondsSinceEpoch;

    test('date inside vacation window returns true', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, '20260512'), isTrue);
    });

    test('date before vacation window returns false', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, '20260509'), isFalse);
    });

    test('date after vacation ends returns false', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, '20260516'), isFalse);
    });

    test('date on vacation start day returns true', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, '20260510'), isTrue);
    });

    test('date on vacation end day returns true', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, '20260515'), isTrue);
    });

    test('vacation still active (no end) — recent date is protected', () {
      final state = makeVacationState(
        startMs: vacationStart,
        stillActive: true,
      );
      // Today should be protected since vacation has no end date.
      final todayKey =
          '${DateTime.now().year.toString().padLeft(4, '0')}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}';
      expect(vacationWindowContains(state, todayKey), isTrue);
    });

    test('no start time set — returns false', () {
      final state = UserAttentionState(
        id: kUserAttentionStateId,
        activeOverride: ContextOverride.vacation,
        manuallyMuted: false,
        updatedAtMs: 0,
      );
      expect(vacationWindowContains(state, '20260512'), isFalse);
    });

    test('invalid dateKey format returns false', () {
      final state = makeVacationState(
        startMs: vacationStart,
        endMs: vacationEnd,
      );
      expect(vacationWindowContains(state, 'invalid'), isFalse);
    });
  });
}
