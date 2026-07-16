import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  canTransitionEscrow,
  escrowDocId,
  EscrowStatus,
  getPaymentProvider,
  SimulatedPaymentProvider,
  validMoneyAmount,
} from './payments';

describe('escrow status machine ($-1/$-4)', () => {
  const ALL: EscrowStatus[] = [
    'held',
    'refund_pending',
    'refunded',
    'disbursement_pending',
    'disbursed',
    'failed',
  ];
  const EXPECTED: Record<EscrowStatus, EscrowStatus[]> = {
    held: ['refund_pending', 'disbursement_pending'],
    refund_pending: ['refunded'],
    disbursement_pending: ['disbursed'],
    refunded: [],
    disbursed: [],
    failed: [],
  };

  it('exhaustive matrix — held money only ever goes back or to charity', () => {
    for (const from of ALL) {
      for (const to of ALL) {
        assert.equal(
          canTransitionEscrow(from, to),
          EXPECTED[from].includes(to),
          `${from} -> ${to}`,
        );
      }
    }
  });

  it('a disbursement can never become a refund (and vice versa)', () => {
    assert.equal(canTransitionEscrow('disbursement_pending', 'refunded'), false);
    assert.equal(canTransitionEscrow('disbursement_pending', 'refund_pending'), false);
    assert.equal(canTransitionEscrow('refunded', 'disbursement_pending'), false);
    assert.equal(canTransitionEscrow('refund_pending', 'disbursement_pending'), false);
  });
});

describe('money amounts', () => {
  it('bounds: $1–$100, integers only', () => {
    assert.equal(validMoneyAmount(100), true);
    assert.equal(validMoneyAmount(10_000), true);
    assert.equal(validMoneyAmount(99), false);
    assert.equal(validMoneyAmount(10_001), false);
    assert.equal(validMoneyAmount(500.5), false);
  });
});

describe('SimulatedPaymentProvider', () => {
  const provider = new SimulatedPaymentProvider();

  it('charges succeed and are deterministic per (challenge, uid)', async () => {
    const a = await provider.charge({ challengeId: 'c1', uid: 'u1', amountCents: 2000 });
    const b = await provider.charge({ challengeId: 'c1', uid: 'u1', amountCents: 2000 });
    assert.equal(a.ok, true);
    assert.equal(a.providerRef, b.providerRef); // idempotent replays
  });

  it('the failure drill: amounts ending in 99 decline', async () => {
    const r = await provider.charge({ challengeId: 'c1', uid: 'u1', amountCents: 499 });
    assert.equal(r.ok, false);
    assert.ok(r.failureReason);
  });

  it('refunds succeed', async () => {
    const r = await provider.refund({
      challengeId: 'c1',
      uid: 'u1',
      amountCents: 2000,
      currency: 'usd',
      status: 'held',
      provider: 'simulated',
      providerRef: 'sim_c1_u1',
      createdAtMs: 1,
      updatedAtMs: 1,
    });
    assert.equal(r.ok, true);
  });
});

describe('provider selection safety', () => {
  it('defaults to simulated; unknown providers throw instead of pretending', () => {
    delete process.env.PAYMENTS_PROVIDER;
    assert.equal(getPaymentProvider().name, 'simulated');
    process.env.PAYMENTS_PROVIDER = 'stripe';
    assert.throws(() => getPaymentProvider(), /no adapter yet/);
    delete process.env.PAYMENTS_PROVIDER;
  });
});

describe('escrow doc ids', () => {
  it('one escrow per participant stake', () => {
    assert.equal(escrowDocId('stk_1', 'u1'), 'stk_1_u1');
  });
});
