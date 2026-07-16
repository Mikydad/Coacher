import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  applyStrike,
  banDurationMsForStrike,
  isChallengeBanned,
} from './enforcement';

const HOUR = 3_600_000;
const DAY = 24 * HOUR;

describe('screenshot strike ladder (P-7/D11)', () => {
  it('12h, 3d, 7d, 7d…', () => {
    assert.equal(banDurationMsForStrike(1), 12 * HOUR);
    assert.equal(banDurationMsForStrike(2), 3 * DAY);
    assert.equal(banDurationMsForStrike(3), 7 * DAY);
    assert.equal(banDurationMsForStrike(9), 7 * DAY);
  });

  it('rejects invalid strike numbers', () => {
    assert.throws(() => banDurationMsForStrike(0), RangeError);
    assert.throws(() => banDurationMsForStrike(1.5), RangeError);
  });

  it('applyStrike increments from the existing doc', () => {
    const now = 1_000_000;
    assert.deepEqual(applyStrike(undefined, now), {
      strikeNumber: 1,
      banUntilMs: now + 12 * HOUR,
    });
    assert.deepEqual(applyStrike({ screenshotStrikeCount: 2 }, now), {
      strikeNumber: 3,
      banUntilMs: now + 7 * DAY,
    });
  });

  it('isChallengeBanned respects the boundary', () => {
    assert.equal(isChallengeBanned(undefined, 100), false);
    assert.equal(isChallengeBanned(100, 100), false); // expired exactly now
    assert.equal(isChallengeBanned(101, 100), true);
  });
});
