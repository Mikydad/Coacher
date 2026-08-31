import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  CHECKED_IN_WINDOW_MS,
  MAX_TAIL_PUSHES,
  ReminderOccurrenceSnapshot,
  TAIL_INTERVAL_MS,
  reminderRescueAction,
} from './rescue_rules';

const twoPm = Date.UTC(2026, 7, 31, 14, 0);
const windowEnd = twoPm + 60 * 60 * 1000; // extreme's 60-min window

function occ(over: Partial<ReminderOccurrenceSnapshot> = {}): ReminderOccurrenceSnapshot {
  return {
    id: 'o1',
    entityId: 't1',
    entityTitle: 'Study',
    state: 'overdue',
    scheduledAtMs: twoPm,
    windowMinutes: 60,
    criticality: 1,
    modeRefId: 'extreme',
    ...over,
  };
}

describe('reminderRescueAction — coverage gates', () => {
  it('resolved occurrences are never rescued', () => {
    const a = reminderRescueAction({
      occ: occ({ state: 'resolved' }),
      lastSeenMs: 0, state: null, nowMs: windowEnd + TAIL_INTERVAL_MS,
    });
    assert.equal(a.kind, 'skip');
  });

  it('only extreme mode or criticality 3 qualify', () => {
    const a = reminderRescueAction({
      occ: occ({ modeRefId: 'disciplined', criticality: 2 }),
      lastSeenMs: 0, state: null, nowMs: windowEnd + TAIL_INTERVAL_MS,
    });
    assert.equal(a.kind, 'skip');
    assert.equal((a as { reason: string }).reason, 'not_covered');
  });

  it('a fresh heartbeat means the local ladder owns it (13.3)', () => {
    const now = windowEnd + TAIL_INTERVAL_MS;
    const a = reminderRescueAction({
      occ: occ(),
      lastSeenMs: now - CHECKED_IN_WINDOW_MS + 1000,
      state: null, nowMs: now,
    });
    assert.equal((a as { reason: string }).reason, 'device_fresh');
  });
});

describe('the Extreme tail (hourly x3 past windowEnd)', () => {
  const dark = twoPm - 24 * 60 * 60 * 1000;

  it('nothing while the window is still open', () => {
    const a = reminderRescueAction({
      occ: occ(), lastSeenMs: dark, state: null, nowMs: windowEnd - 1000,
    });
    assert.equal((a as { reason: string }).reason, 'window_open');
  });

  it('the first tail lands an hour past the window, blunt not loud', () => {
    const a = reminderRescueAction({
      occ: occ(), lastSeenMs: dark, state: null,
      nowMs: windowEnd + TAIL_INTERVAL_MS,
    });
    assert.equal(a.kind, 'tail');
    assert.equal((a as { tailIndex: number }).tailIndex, 1);
    assert.match((a as { body: string }).body, /still open/);
  });

  it('tails pace hourly — the second is not due at +90min', () => {
    const a = reminderRescueAction({
      occ: occ(), lastSeenMs: dark,
      state: { tailCount: 1, lastPushAtMs: 0 },
      nowMs: windowEnd + TAIL_INTERVAL_MS * 1.5,
    });
    assert.equal((a as { reason: string }).reason, 'tail_not_due');
  });

  it('the third tail is the final call, and the fourth never comes', () => {
    const third = reminderRescueAction({
      occ: occ(), lastSeenMs: dark,
      state: { tailCount: 2, lastPushAtMs: 0 },
      nowMs: windowEnd + TAIL_INTERVAL_MS * 3,
    });
    assert.equal(third.kind, 'tail');
    assert.match((third as { body: string }).body, /Final call/);

    const fourth = reminderRescueAction({
      occ: occ(), lastSeenMs: dark,
      state: { tailCount: MAX_TAIL_PUSHES, lastPushAtMs: 0 },
      nowMs: windowEnd + TAIL_INTERVAL_MS * 10,
    });
    assert.equal((fourth as { reason: string }).reason, 'tail_exhausted');
  });
});

describe('the criticality-3 in-window net', () => {
  it('rescues a device dark since before the due moment', () => {
    const a = reminderRescueAction({
      occ: occ({ modeRefId: 'flexible', criticality: 3, state: 'due' }),
      lastSeenMs: twoPm - 2 * 60 * 60 * 1000,
      state: null, nowMs: twoPm + 10 * 60 * 1000,
    });
    assert.equal(a.kind, 'critWindow');
  });

  it('a heartbeat after scheduling means the ladder is armed — no double', () => {
    const a = reminderRescueAction({
      occ: occ({ modeRefId: 'flexible', criticality: 3, state: 'due' }),
      // Seen a minute AFTER scheduling (ladder compiled), stale by now.
      lastSeenMs: twoPm + 60 * 1000,
      state: null, nowMs: twoPm + 40 * 60 * 1000,
    });
    assert.equal((a as { reason: string }).reason, 'ladder_assumed_armed');
  });

  it('once per occurrence', () => {
    const a = reminderRescueAction({
      occ: occ({ modeRefId: 'flexible', criticality: 3, state: 'due' }),
      lastSeenMs: twoPm - 2 * 60 * 60 * 1000,
      state: { tailCount: 0, lastPushAtMs: 0, critRescued: true },
      nowMs: twoPm + 10 * 60 * 1000,
    });
    assert.equal((a as { reason: string }).reason, 'already_rescued');
  });

  it('D5 binds the server too: no crit-3 push past windowEnd', () => {
    const a = reminderRescueAction({
      occ: occ({ modeRefId: 'flexible', criticality: 3 }),
      lastSeenMs: twoPm - 2 * 60 * 60 * 1000,
      state: null, nowMs: windowEnd + 5 * 60 * 1000,
    });
    assert.equal((a as { reason: string }).reason, 'crit_window_closed');
  });
});
