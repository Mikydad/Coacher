import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  applyDailyCap,
  CLIENT_GRANTABLE,
  dayKey,
  EARN_AMOUNTS,
  PHOTO_REMOVAL_PRICE,
  TRUSTED_SOURCES,
  trustedDelta,
  txnId,
  validRefId,
} from './points';

const NOW = Date.UTC(2026, 6, 16, 14, 30); // 2026-07-16

describe('points economy invariants (PT-1/PT-3/D9)', () => {
  it('removal price ≈ 1–2 weeks of typical honest earning (D9)', () => {
    // Typical honest day: checkin 5 + ~8 tasks ×2 + 2 goal units ×5 ≈ 31.
    const typicalDay =
      EARN_AMOUNTS.earn_checkin! + 8 * EARN_AMOUNTS.earn_task! + 2 * EARN_AMOUNTS.earn_goal!;
    const daysToRemove = PHOTO_REMOVAL_PRICE / typicalDay;
    assert.ok(daysToRemove >= 7 && daysToRemove <= 14, `${daysToRemove} days`);
  });

  it('server-only sources are never client-grantable (PT-2)', () => {
    for (const source of [
      'signup_bonus',
      'earn_challenge_win',
      'stake_lock',
      'stake_release',
      'stake_forfeit',
      'spend_photo_removal',
    ] as const) {
      assert.equal(CLIENT_GRANTABLE.has(source), false, source);
    }
  });
});

describe('txnId determinism (idempotency backbone)', () => {
  it('per-day sources collapse replays within the same day', () => {
    assert.equal(txnId('earn_checkin', 'anything', NOW), 'earn_checkin_2026-07-16');
    assert.equal(
      txnId('earn_task', 'task_9', NOW),
      txnId('earn_task', 'task_9', NOW + 3_600_000),
    );
    // …but a new day is a new grant.
    assert.notEqual(
      txnId('earn_task', 'task_9', NOW),
      txnId('earn_task', 'task_9', NOW + 24 * 3_600_000),
    );
  });

  it('challenge-scoped sources collapse on the challenge id forever', () => {
    for (const source of ['stake_lock', 'stake_release', 'stake_forfeit', 'earn_challenge_win'] as const) {
      assert.equal(
        txnId(source, 'stk_1', NOW),
        txnId(source, 'stk_1', NOW + 90 * 24 * 3_600_000),
      );
    }
  });

  it('dayKey is UTC', () => {
    assert.equal(dayKey(Date.UTC(2026, 6, 16, 23, 59)), '2026-07-16');
    assert.equal(dayKey(Date.UTC(2026, 6, 17, 0, 1)), '2026-07-17');
  });

  it('refId validation rejects path-like input', () => {
    assert.equal(validRefId('task_abc-123'), true);
    assert.equal(validRefId('a/b'), false);
    assert.equal(validRefId(''), false);
    assert.equal(validRefId('x'.repeat(81)), false);
  });
});

describe('applyDailyCap', () => {
  it('caps earn_checkin at 1/day', () => {
    const first = applyDailyCap(undefined, 'earn_checkin', NOW);
    assert.equal(first.allowed, true);
    const second = applyDailyCap(
      { dayKey: first.dayKey, dayCounts: first.dayCounts },
      'earn_checkin',
      NOW,
    );
    assert.equal(second.allowed, false);
  });

  it('counters reset when the day changes', () => {
    const doc = { dayKey: '2026-07-15', dayCounts: { earn_checkin: 1, earn_task: 20 } };
    const next = applyDailyCap(doc, 'earn_checkin', NOW);
    assert.equal(next.allowed, true);
    assert.deepEqual(next.dayCounts, { earn_checkin: 1 });
  });

  it('earn_task allows 20 then stops', () => {
    let doc: { dayKey?: string; dayCounts?: Record<string, number> } = {};
    for (let i = 0; i < 20; i++) {
      const r = applyDailyCap(doc, 'earn_task', NOW);
      assert.equal(r.allowed, true, `grant ${i + 1}`);
      doc = { dayKey: r.dayKey, dayCounts: r.dayCounts };
    }
    assert.equal(applyDailyCap(doc, 'earn_task', NOW).allowed, false);
  });

  it('uncapped sources always pass and still count', () => {
    const r = applyDailyCap(undefined, 'stake_release', NOW);
    assert.equal(r.allowed, true);
  });
});

describe('trusted points (audit H7 / D1 — the removal sink is fenced)', () => {
  it('only server-awarded sources are trusted', () => {
    assert.deepEqual([...TRUSTED_SOURCES].sort(), ['earn_challenge_win', 'signup_bonus']);
  });

  it('trusted earnings add, self-reported earnings do not', () => {
    assert.equal(trustedDelta('signup_bonus', 50), 50);
    assert.equal(trustedDelta('earn_challenge_win', 50), 50);
    assert.equal(trustedDelta('earn_task', 2), 0);
    assert.equal(trustedDelta('earn_goal', 5), 0);
    assert.equal(trustedDelta('earn_checkin', 5), 0);
    assert.equal(trustedDelta('earn_streak', 15), 0);
  });

  it('stake locks / releases leave the trusted share alone', () => {
    assert.equal(trustedDelta('stake_lock', -200), 0);
    assert.equal(trustedDelta('stake_release', 200), 0);
    assert.equal(trustedDelta('stake_forfeit', 0), 0);
  });

  it('the removal spend is paid from the trusted share', () => {
    assert.equal(trustedDelta('spend_photo_removal', -PHOTO_REMOVAL_PRICE), -PHOTO_REMOVAL_PRICE);
  });

  it('110 self-reported points a day never unlock a removal', () => {
    // 20 tasks + 10 goals + checkin + streak with invented ids (audit H7).
    const day = 20 * trustedDelta('earn_task', 2) + 10 * trustedDelta('earn_goal', 5)
      + trustedDelta('earn_checkin', 5) + trustedDelta('earn_streak', 15);
    assert.equal(day, 0);
  });
});

