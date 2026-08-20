import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  asAction,
  CHECKED_IN_WINDOW_MS,
  CLOSING_HORIZON_MS,
  composeRescue,
  DATA_PUSH_MIN_INTERVAL_MS,
  isPoliteHour,
  localHour,
  rescueAction,
  IntentionSnapshot,
} from './rescue_rules';

const NOW = Date.UTC(2026, 6, 24, 12); // Fri 2026-07-24 12:00 UTC

function intention(overrides: Partial<IntentionSnapshot> = {}): IntentionSnapshot {
  return {
    id: 'i1',
    title: 'Call cousin Sara',
    status: 'open',
    active: true,
    windowEndMs: NOW + 6 * 3_600_000, // closes in 6h
    ...overrides,
  };
}

/** Days-absent baseline: last seen 3 days ago, UTC device, no state. */
function base(overrides: Record<string, unknown> = {}) {
  return {
    intention: intention(),
    projection: null,
    lastSeenMs: NOW - 3 * 24 * 3_600_000,
    tzOffsetMinutes: 0,
    state: null,
    nowMs: NOW,
    ...overrides,
  } as Parameters<typeof rescueAction>[0];
}

describe('rescueAction — the four-condition gate', () => {
  it('days-absent + closing + uncovered → the one polite notification', () => {
    const action = rescueAction(base());
    assert.equal(action.kind, 'notification');
    if (action.kind === 'notification') {
      assert.equal(action.title, 'A promise is closing');
      assert.match(action.body, /call cousin Sara/);
      assert.match(action.body, /\?$/); // suggestion-as-question
    }
  });

  it('non-live or tombstoned intentions are never rescued', () => {
    assert.equal(
      rescueAction(base({ intention: intention({ status: 'completed' }) })).kind,
      'skip',
    );
    assert.equal(
      rescueAction(base({ intention: intention({ active: false }) })).kind,
      'skip',
    );
  });

  it('nudged intentions stay live and keep the safety net (P1-05)', () => {
    const action = rescueAction(
      base({ intention: intention({ status: 'nudged' }) }),
    );
    assert.equal(action.kind, 'notification');
  });

  it('windows not yet closing (or already past) are skipped', () => {
    const far = intention({ windowEndMs: NOW + CLOSING_HORIZON_MS + 1 });
    assert.equal(rescueAction(base({ intention: far })).kind, 'skip');
    const past = intention({ windowEndMs: NOW - 1 });
    assert.equal(rescueAction(base({ intention: past })).kind, 'skip');
  });

  it('a covering client slot silences the server entirely', () => {
    const action = rescueAction(
      base({ projection: { covered: true, nextSlotMs: NOW + 3_600_000 } }),
    );
    assert.deepEqual(action, { kind: 'skip', reason: 'covered' });
  });

  it('a fired primary with a still-armed later slot stays covered (Tier-1 fix)', () => {
    const action = rescueAction(
      base({
        projection: {
          covered: true,
          nextSlotMs: NOW - 3_600_000, // primary fired; mirror froze before it
          lastSlotMs: NOW + 2 * 3_600_000, // deadline-eve safety still armed
        },
      }),
    );
    assert.deepEqual(action, { kind: 'skip', reason: 'covered' });
  });

  it('a stale projection (slot already past) does NOT count as covered', () => {
    const action = rescueAction(
      base({ projection: { covered: true, nextSlotMs: NOW - 1 } }),
    );
    assert.equal(action.kind, 'notification');
  });

  it('no registered devices → nothing to push to', () => {
    assert.deepEqual(rescueAction(base({ lastSeenMs: null })), {
      kind: 'skip',
      reason: 'no_devices',
    });
  });
});

describe('rescueAction — transport choice (platform honesty)', () => {
  it('checked-in-today devices get the silent data push', () => {
    const action = rescueAction(
      base({ lastSeenMs: NOW - CHECKED_IN_WINDOW_MS + 1 }),
    );
    assert.deepEqual(action, { kind: 'data' });
  });

  it('data pushes are throttled per intention', () => {
    const action = rescueAction(
      base({
        lastSeenMs: NOW - 3_600_000,
        state: { lastDataPushAtMs: NOW - DATA_PUSH_MIN_INTERVAL_MS + 1 },
      }),
    );
    assert.deepEqual(action, { kind: 'skip', reason: 'data_throttled' });
  });

  it('notification rescue fires ONCE per window', () => {
    const action = rescueAction(
      base({
        state: {
          lastRescueAtMs: NOW - 3_600_000,
          rescuedWindowEndMs: NOW + 6 * 3_600_000,
        },
      }),
    );
    assert.deepEqual(action, { kind: 'skip', reason: 'already_rescued' });
  });

  it('a NEW window re-arms the rescue', () => {
    const action = rescueAction(
      base({
        state: {
          lastRescueAtMs: NOW - 3 * 24 * 3_600_000,
          rescuedWindowEndMs: NOW - 2 * 24 * 3_600_000, // previous window
        },
      }),
    );
    assert.equal(action.kind, 'notification');
  });

  it('notifications wait for polite local hours (data pushes do not)', () => {
    // 12:00 UTC is 03:00 at UTC+15... use offset that lands at 03:00 local.
    const nightOffset = -9 * 60; // 12:00 UTC → 03:00 local
    const notif = rescueAction(base({ tzOffsetMinutes: nightOffset }));
    assert.deepEqual(notif, { kind: 'skip', reason: 'impolite_hour' });

    const data = rescueAction(
      base({ tzOffsetMinutes: nightOffset, lastSeenMs: NOW - 3_600_000 }),
    );
    assert.deepEqual(data, { kind: 'data' });
  });
});

describe('polite hours + copy helpers', () => {
  it('localHour applies tz offsets across midnight', () => {
    assert.equal(localHour(NOW, 0), 12);
    assert.equal(localHour(NOW, 8 * 60), 20);
    assert.equal(localHour(NOW, 13 * 60), 1); // wraps past midnight
    assert.equal(localHour(NOW, -13 * 60), 23); // wraps backwards
  });

  it('polite window is [09, 21) local', () => {
    const nineAm = Date.UTC(2026, 6, 24, 9);
    const ninePm = Date.UTC(2026, 6, 24, 21);
    assert.equal(isPoliteHour(nineAm, 0), true);
    assert.equal(isPoliteHour(nineAm - 1, 0), false);
    assert.equal(isPoliteHour(ninePm, 0), false);
  });

  it('asAction mirrors the client lowercasing rule', () => {
    assert.equal(asAction('Call cousin Sara'), 'call cousin Sara');
    assert.equal(asAction('NASA application'), 'NASA application');
    assert.equal(asAction('x'), 'x');
  });

  it('composeRescue is deterministic question-form copy', () => {
    const copy = composeRescue('Send the photos');
    assert.equal(
      copy.body,
      'Your window to send the photos is closing — is now a good moment?',
    );
  });
});
