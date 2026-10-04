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

// ─── H1 — verdict/object binding (pre-launch audit 2026-09-15) ───────────────

import { parseStakePhotoObject, verdictBindsTo } from './screen_verdict';

describe('parseStakePhotoObject', () => {
  it('parses the pinned layout', () => {
    assert.deepEqual(parseStakePhotoObject('stake_photos/stk_1/userA.jpg'), {
      challengeId: 'stk_1',
      uid: 'userA',
    });
  });
  it('rejects other prefixes, depths, and extensions', () => {
    assert.equal(parseStakePhotoObject('stake_evidence/stk_1/userA/x.jpg'), null);
    assert.equal(parseStakePhotoObject('stake_photos/stk_1/userA/extra.jpg'), null);
    assert.equal(parseStakePhotoObject('stake_photos/stk_1/userA.png'), null);
    assert.equal(parseStakePhotoObject('stake_photos/stk_1/.jpg'), null);
    assert.equal(parseStakePhotoObject('stake_photos//userA.jpg'), null);
  });
});

describe('verdictBindsTo', () => {
  const participant = { uid: 'A', photoPath: 'stake_photos/stk_1/A.jpg' };
  it("accepts only the participant's own object", () => {
    assert.equal(
      verdictBindsTo({ uid: 'A', path: 'stake_photos/stk_1/A.jpg' }, participant),
      true,
    );
  });
  it("rejects another uploader's verdict on the same challenge id", () => {
    assert.equal(
      verdictBindsTo({ uid: 'B', path: 'stake_photos/stk_1/B.jpg' }, participant),
      false,
    );
  });
  it('rejects a path mismatch even with the right uid', () => {
    assert.equal(
      verdictBindsTo({ uid: 'A', path: 'stake_photos/stk_2/A.jpg' }, participant),
      false,
    );
  });
  it('rejects unbound (legacy) verdicts and photo-less participants', () => {
    assert.equal(verdictBindsTo(undefined, participant), false);
    assert.equal(
      verdictBindsTo({ uid: 'A', path: 'stake_photos/stk_1/A.jpg' }, { uid: 'A', photoPath: undefined }),
      false,
    );
    assert.equal(verdictBindsTo({ uid: 'A', path: 'x' }, undefined), false);
  });
});
