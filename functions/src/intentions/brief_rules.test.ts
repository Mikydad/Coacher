import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  BRIEF_HOUR_START,
  briefAction,
  composeBrief,
  localDayKey,
  localDayStartMs,
} from './brief_rules';

// Fri 2026-07-24 08:30 UTC — inside the send window for a UTC device.
const NOW = Date.UTC(2026, 6, 24, 8, 30);

function base(overrides: Record<string, unknown> = {}) {
  return {
    enabled: true,
    lastSeenMs: NOW - 2 * 24 * 3_600_000, // last open: two days ago
    tzOffsetMinutes: 0,
    lastBriefDayKey: null,
    openPromises: 3,
    nowMs: NOW,
    ...overrides,
  } as Parameters<typeof briefAction>[0];
}

describe('briefAction', () => {
  it('opted-in, absent, in-window, with promises → send', () => {
    const action = briefAction(base());
    assert.equal(action.kind, 'send');
    if (action.kind === 'send') {
      assert.equal(action.title, 'Good morning');
      assert.match(action.body, /3 open promises/);
    }
  });

  it('disabled devices are never briefed', () => {
    assert.deepEqual(briefAction(base({ enabled: false })), {
      kind: 'skip',
      reason: 'disabled',
    });
  });

  it('respects the local send window [08, 10)', () => {
    const sevenLocal = Date.UTC(2026, 6, 24, 7, 59);
    assert.equal(
      briefAction(base({ nowMs: sevenLocal })).kind === 'skip',
      true,
    );
    const tenLocal = Date.UTC(2026, 6, 24, 10);
    assert.deepEqual(briefAction(base({ nowMs: tenLocal })), {
      kind: 'skip',
      reason: 'outside_window',
    });
    // 08:30 UTC is 08:30+offset local — an offset of -120 puts the
    // device at 06:30, before its morning.
    assert.deepEqual(briefAction(base({ tzOffsetMinutes: -120 })), {
      kind: 'skip',
      reason: 'outside_window',
    });
  });

  it('sends at most once per local day', () => {
    const action = briefAction(base({ lastBriefDayKey: '2026-07-24' }));
    assert.deepEqual(action, { kind: 'skip', reason: 'already_briefed' });
    // Yesterday's brief does not block today's.
    assert.equal(
      briefAction(base({ lastBriefDayKey: '2026-07-23' })).kind,
      'send',
    );
  });

  it('an app open today hands the morning to the in-app snackbar', () => {
    const openedAtSeven = Date.UTC(2026, 6, 24, 7);
    assert.deepEqual(briefAction(base({ lastSeenMs: openedAtSeven })), {
      kind: 'skip',
      reason: 'seen_today',
    });
    // Opened yesterday 23:59 → still absent today → send.
    const lastNight = Date.UTC(2026, 6, 23, 23, 59);
    assert.equal(briefAction(base({ lastSeenMs: lastNight })).kind, 'send');
  });

  it('a quiet app stays quiet: zero promises → no push', () => {
    assert.deepEqual(briefAction(base({ openPromises: 0 })), {
      kind: 'skip',
      reason: 'nothing_to_say',
    });
  });

  it('never-seen devices (null lastSeenMs) can still be briefed', () => {
    assert.equal(briefAction(base({ lastSeenMs: null })).kind, 'send');
  });
});

describe('local day helpers', () => {
  it('localDayKey shifts with the tz offset', () => {
    // 23:30 UTC on the 24th is already the 25th at UTC+2.
    const lateUtc = Date.UTC(2026, 6, 24, 23, 30);
    assert.equal(localDayKey(lateUtc, 0), '2026-07-24');
    assert.equal(localDayKey(lateUtc, 120), '2026-07-25');
    assert.equal(localDayKey(Date.UTC(2026, 6, 24, 0, 30), -60), '2026-07-23');
  });

  it('localDayStartMs is the device-local midnight in UTC ms', () => {
    const tz = 180; // UTC+3
    const start = localDayStartMs(NOW, tz);
    // Local midnight at UTC+3 on the 24th is 21:00 UTC on the 23rd.
    assert.equal(start, Date.UTC(2026, 6, 23, 21));
    assert.equal(localDayKey(start, tz), localDayKey(NOW, tz));
    assert.notEqual(localDayKey(start - 1, tz), localDayKey(NOW, tz));
  });

  it('send window constant sanity', () => {
    assert.equal(BRIEF_HOUR_START, 8);
  });
});

describe('composeBrief', () => {
  it('singular and plural read naturally', () => {
    assert.equal(
      composeBrief(1).body,
      'One open promise today — want a quick plan?',
    );
    assert.equal(
      composeBrief(4).body,
      '4 open promises today — want a quick plan?',
    );
  });
});
