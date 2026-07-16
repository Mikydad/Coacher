import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { screeningVerdict } from './screen_verdict';

describe('screeningVerdict (P-2 thresholds)', () => {
  const table: Array<
    [adult: string, violence: string, racy: string, approved: boolean, why: string]
  > = [
    ['VERY_UNLIKELY', 'VERY_UNLIKELY', 'UNLIKELY', true, 'clean photo'],
    ['POSSIBLE', 'POSSIBLE', 'LIKELY', true, 'possible/racy-likely still passes'],
    ['LIKELY', 'VERY_UNLIKELY', 'UNLIKELY', false, 'adult LIKELY rejects'],
    ['VERY_LIKELY', 'VERY_UNLIKELY', 'UNLIKELY', false, 'adult VERY_LIKELY rejects'],
    ['VERY_UNLIKELY', 'LIKELY', 'UNLIKELY', false, 'violence LIKELY rejects'],
    ['VERY_UNLIKELY', 'VERY_UNLIKELY', 'VERY_LIKELY', false, 'racy VERY_LIKELY rejects'],
    ['UNKNOWN', 'UNKNOWN', 'UNKNOWN', true, 'unknown likelihoods pass (fail open on ambiguity, reject on signal)'],
  ];
  for (const [adult, violence, racy, approved, why] of table) {
    it(why, () => {
      const v = screeningVerdict({ adult, violence, racy });
      assert.equal(v.approved, approved);
      if (!approved) assert.ok(v.reasons.length > 0);
    });
  }

  it('missing annotation fields behave as UNKNOWN', () => {
    assert.equal(screeningVerdict({}).approved, true);
  });

  it('collects every reason', () => {
    const v = screeningVerdict({
      adult: 'VERY_LIKELY',
      violence: 'LIKELY',
      racy: 'VERY_LIKELY',
    });
    assert.deepEqual(v.reasons, ['adult', 'violence', 'racy']);
  });
});
