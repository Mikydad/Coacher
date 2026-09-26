import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  countsAsInstruction,
  instructionCapFor,
  proEntitlementActive,
  tierFromEntitlement,
} from './ai_instruction_cap';

describe('proEntitlementActive', () => {
  it('is false for a missing doc', () => {
    assert.equal(proEntitlementActive(undefined, 1_000), false);
  });
  it('is true for active with no expiry', () => {
    assert.equal(proEntitlementActive({ active: true }, 1_000), true);
  });
  it('honours expiry', () => {
    assert.equal(proEntitlementActive({ active: true, expiresAtMs: 2_000 }, 1_000), true);
    assert.equal(proEntitlementActive({ active: true, expiresAtMs: 1_000 }, 1_000), false);
  });
  it('ignores non-boolean active', () => {
    assert.equal(proEntitlementActive({ active: 'yes' }, 1_000), false);
  });
});

describe('tierFromEntitlement', () => {
  it('maps a failed read to unknown', () => {
    assert.equal(tierFromEntitlement({ ok: false }), 'unknown');
  });
  it('maps a missing doc to free and an active doc to pro', () => {
    assert.equal(tierFromEntitlement({ ok: true, data: undefined }), 'free');
    assert.equal(tierFromEntitlement({ ok: true, data: { active: true } }), 'pro');
  });
});

describe('instructionCapFor', () => {
  it('caps only accounts known to be free', () => {
    assert.equal(instructionCapFor({ configuredCap: 5, tier: 'free' }), 5);
    assert.equal(instructionCapFor({ configuredCap: 5, tier: 'pro' }), undefined);
    assert.equal(instructionCapFor({ configuredCap: 5, tier: 'unknown' }), undefined);
  });
  it('treats a non-positive or malformed cap as no cap', () => {
    assert.equal(instructionCapFor({ configuredCap: 0, tier: 'free' }), undefined);
    assert.equal(instructionCapFor({ configuredCap: -1, tier: 'free' }), undefined);
    assert.equal(instructionCapFor({ configuredCap: Number.NaN, tier: 'free' }), undefined);
    assert.equal(instructionCapFor({ configuredCap: 5.9, tier: 'free' }), 5);
  });
});

describe('countsAsInstruction', () => {
  it('counts only tool-bearing first rounds', () => {
    assert.equal(countsAsInstruction({ hasTools: true, loopIndex: 0 }), true);
    assert.equal(countsAsInstruction({ hasTools: false, loopIndex: 0 }), false);
    assert.equal(countsAsInstruction({ hasTools: true, loopIndex: 1 }), false);
    assert.equal(countsAsInstruction({ hasTools: false, loopIndex: 2 }), false);
  });
});
