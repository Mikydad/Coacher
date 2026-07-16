import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  assertTransition,
  canTransition,
  IllegalTransitionError,
  isTerminal,
} from './state_machine';
import { ChallengeStatus } from './types';

const ALL: ChallengeStatus[] = [
  'draft',
  'pending_accept',
  'active',
  'pending_verification',
  'completed_success',
  'completed_forfeit',
  'cancelled',
  'vetoed',
];

/** The complete legal-transition table (CC-2). Everything else is illegal. */
const EXPECTED: Record<ChallengeStatus, ChallengeStatus[]> = {
  draft: ['pending_accept', 'active', 'cancelled'],
  pending_accept: ['active', 'cancelled'],
  active: ['pending_verification', 'cancelled'],
  pending_verification: [
    'completed_success',
    'completed_forfeit',
    'vetoed',
    'cancelled',
  ],
  completed_success: [],
  completed_forfeit: [],
  cancelled: [],
  vetoed: [],
};

describe('state machine (CC-2) — exhaustive matrix', () => {
  for (const from of ALL) {
    for (const to of ALL) {
      const legal = EXPECTED[from].includes(to);
      it(`${from} -> ${to}: ${legal ? 'legal' : 'ILLEGAL'}`, () => {
        assert.equal(canTransition(from, to), legal);
        if (legal) {
          assert.doesNotThrow(() => assertTransition(from, to));
        } else {
          assert.throws(
            () => assertTransition(from, to),
            IllegalTransitionError,
          );
        }
      });
    }
  }

  it('terminal statuses have no exits', () => {
    for (const s of ALL) {
      assert.equal(isTerminal(s), EXPECTED[s].length === 0, s);
    }
  });
});
