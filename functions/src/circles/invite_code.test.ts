import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { normalizeCode } from './callables';

describe('invite key normalization', () => {
  it('accepts the canonical form', () => {
    assert.equal(normalizeCode('ABCD-2345'), 'ABCD-2345');
  });

  it('uppercases, strips separators and whitespace', () => {
    assert.equal(normalizeCode(' abcd 2345 '), 'ABCD-2345');
    assert.equal(normalizeCode('abcd-2345'), 'ABCD-2345');
    assert.equal(normalizeCode('AB.CD_23:45'), 'ABCD-2345');
  });

  it('rejects wrong lengths and empties', () => {
    assert.equal(normalizeCode(''), null);
    assert.equal(normalizeCode('ABC'), null);
    assert.equal(normalizeCode('ABCD-23456'), null);
  });
});
