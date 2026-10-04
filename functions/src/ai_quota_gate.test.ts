import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  ChargedTurnRegistry,
  gateBeforeDispatch,
  OverQuotaRegistry,
  overQuotaUntilFor,
  verifiedAccountRejection,
} from './ai_quota_gate';

describe('OverQuotaRegistry', () => {
  it('remembers a uid until the marked time, then forgets', () => {
    const r = new OverQuotaRegistry();
    r.mark('u', 1_000, 0);
    assert.equal(r.exhaustedUntil('u', 500), 1_000);
    assert.equal(r.exhaustedUntil('u', 1_000), undefined);
    assert.equal(r.exhaustedUntil('u', 2_000), undefined);
  });
  it('prunes expired entries when over capacity', () => {
    const r = new OverQuotaRegistry(2);
    r.mark('a', 10, 0);
    r.mark('b', 10, 0);
    r.mark('c', 10, 0);
    r.mark('d', 100, 50); // triggers prune of a/b/c (expired at 50)
    assert.equal(r.exhaustedUntil('a', 50), undefined);
    assert.equal(r.exhaustedUntil('d', 50), 100);
  });
});

describe('gateBeforeDispatch (H9)', () => {
  it('first turn, not over quota → concurrent fast path', () => {
    assert.equal(
      gateBeforeDispatch({ loopIndex: 0, overQuota: false, turnChargedHere: false }),
      'fast_path',
    );
  });
  it('first turn, over quota → reject, no upstream call', () => {
    assert.equal(
      gateBeforeDispatch({ loopIndex: 0, overQuota: true, turnChargedHere: false }),
      'reject',
    );
  });
  it('follow-up with a junk turnId while over quota → reject (the old escape hatch)', () => {
    assert.equal(
      gateBeforeDispatch({ loopIndex: 1, overQuota: true, turnChargedHere: false }),
      'reject',
    );
  });
  it('follow-up of a turn charged here keeps the fast path even over quota', () => {
    assert.equal(
      gateBeforeDispatch({ loopIndex: 1, overQuota: true, turnChargedHere: true }),
      'fast_path',
    );
  });
  it('follow-up of an unknown turn, not over quota → quota before dispatch', () => {
    assert.equal(
      gateBeforeDispatch({ loopIndex: 2, overQuota: false, turnChargedHere: false }),
      'quota_first',
    );
  });
});

describe('overQuotaUntilFor — every rejection reason sets a marker', () => {
  const now = 10_000;
  it('hourly cap → window end', () => {
    assert.equal(overQuotaUntilFor('user_quota', { now, windowEndMs: 20_000 }), 20_000);
  });
  it('daily cap / token budget → midnight', () => {
    assert.equal(overQuotaUntilFor('daily_cap', { now, midnightMs: 99_000 }), 99_000);
    assert.equal(overQuotaUntilFor('token_budget', { now, midnightMs: 99_000 }), 99_000);
  });
  it('follow-up cap → the turn window', () => {
    assert.equal(overQuotaUntilFor('turn_follow_up_cap', { now, turnWindowMs: 500 }), 10_500);
  });
});

describe('ChargedTurnRegistry', () => {
  it('tracks per uid + turn and bounds its size', () => {
    const r = new ChargedTurnRegistry(4);
    r.add('u', 't1');
    assert.equal(r.has('u', 't1'), true);
    assert.equal(r.has('v', 't1'), false);
    r.add('u', 't2');
    r.add('u', 't3');
    r.add('u', 't4');
    r.add('u', 't5'); // evicts the oldest half
    assert.equal(r.has('u', 't1'), false);
    assert.equal(r.has('u', 't5'), true);
  });
});

describe('verifiedAccountRejection (H10)', () => {
  it('anonymous is always rejected', () => {
    assert.ok(
      verifiedAccountRejection({ signInProvider: 'anonymous', emailVerified: false, require: false }),
    );
  });
  it('unverified password accounts pass while the flag is off', () => {
    assert.equal(
      verifiedAccountRejection({ signInProvider: 'password', emailVerified: false, require: false }),
      null,
    );
  });
  it('unverified password accounts are rejected when required; social passes', () => {
    assert.ok(
      verifiedAccountRejection({ signInProvider: 'password', emailVerified: false, require: true }),
    );
    assert.equal(
      verifiedAccountRejection({ signInProvider: 'password', emailVerified: true, require: true }),
      null,
    );
    assert.equal(
      verifiedAccountRejection({ signInProvider: 'apple.com', emailVerified: undefined, require: true }),
      null,
    );
  });
});
