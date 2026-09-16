import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  PURGE_STEPS,
  purgeStatus,
  settlementForCancellation,
} from './purge_plan';

const h2h = (status: string) => ({
  id: 'stk_1',
  status,
  participants: [
    { uid: 'A', stakeKind: 'points', stakeAmount: 200 },
    { uid: 'B', stakeKind: 'points', stakeAmount: 200 },
  ],
});

describe('settlementForCancellation (H17 — deletion refunds both sides)', () => {
  it('releases every locked points stake on an active h2h', () => {
    const s = settlementForCancellation(h2h('active'), 'A');
    assert.deepEqual(s.releases, [
      { uid: 'A', amount: 200 },
      { uid: 'B', amount: 200 },
    ]);
    assert.deepEqual(s.escrowRefundUids, []);
  });

  it('also settles pending_verification (locks still held)', () => {
    assert.equal(settlementForCancellation(h2h('pending_verification'), 'B').releases.length, 2);
  });

  it('nothing to release before acceptance (draft / pending_accept)', () => {
    assert.deepEqual(settlementForCancellation(h2h('pending_accept'), 'A').releases, []);
    assert.deepEqual(settlementForCancellation(h2h('draft'), 'A').releases, []);
  });

  it('money participants go to escrow refund, photo participants to nothing', () => {
    const s = settlementForCancellation(
      {
        id: 'stk_2',
        status: 'active',
        participants: [
          { uid: 'A', stakeKind: 'money', stakeAmount: 2000 },
          { uid: 'B', stakeKind: 'money', stakeAmount: 2000 },
          { uid: 'C', stakeKind: 'photo' },
        ],
      },
      'A',
    );
    assert.deepEqual(s.releases, []);
    assert.deepEqual(s.escrowRefundUids, ['A', 'B']);
  });

  it('ignores zero / missing point amounts', () => {
    const s = settlementForCancellation(
      { id: 'x', status: 'active', participants: [{ uid: 'A', stakeKind: 'points' }] },
      'A',
    );
    assert.deepEqual(s.releases, []);
  });
});

describe('purgeStatus (H12 — durable job)', () => {
  it('is done only when every inventory step is done', () => {
    const steps = Object.fromEntries(PURGE_STEPS.map((s) => [s, { status: 'done' }]));
    assert.equal(purgeStatus({ steps }), 'done');
    assert.equal(
      purgeStatus({ steps: { ...steps, feedback: { status: 'failed', error: 'x' } } }),
      'partial',
    );
    assert.equal(purgeStatus({ steps: {} }), 'partial');
  });
});
