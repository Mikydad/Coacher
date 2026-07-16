import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  isBackfillSuspicious,
  loggedPerUnit,
  measureParticipant,
  requiredUnits,
  unitPasses,
} from './measurement';
import { EvidenceRecord, FrozenGoal } from './types';

const goal: FrozenGoal = {
  title: 'Read',
  unitKind: 'minutes',
  unitTarget: 60,
  totalUnits: 7,
};

function ev(partial: Partial<EvidenceRecord>): EvidenceRecord {
  return {
    uid: 'u1',
    unitIndex: 0,
    amount: 60,
    source: 'timer',
    recordedAtMs: 1_000,
    arrivedAtMs: 2_000,
    ...partial,
  };
}

describe('unitPasses (M-1: ≥75% of target)', () => {
  const table: Array<[logged: number, target: number, pass: boolean]> = [
    [45, 60, true], // the canonical mercy case: 45 of 60 passes
    [44, 60, false],
    [46, 60, true],
    [60, 60, true],
    [0, 60, false],
    [38, 50, true], // 37.5 threshold
    [37, 50, false],
    [3, 4, true], // 3.0 threshold exactly
    [2, 4, false],
    [75, 100, true],
    [74, 100, false],
  ];
  for (const [logged, target, pass] of table) {
    it(`${logged}/${target} → ${pass ? 'pass' : 'fail'}`, () => {
      assert.equal(unitPasses(logged, target), pass);
    });
  }

  it('rejects non-positive targets', () => {
    assert.throws(() => unitPasses(10, 0), RangeError);
    assert.throws(() => unitPasses(10, -5), RangeError);
  });
});

describe('requiredUnits (M-2/M-3 mode thresholds)', () => {
  const table: Array<
    [total: number, mode: Parameters<typeof requiredUnits>[1], required: number]
  > = [
    [7, 'flexible', 5], // ceil(4.9)
    [7, 'disciplined', 6], // ceil(5.95)
    [7, 'extreme', 7],
    [30, 'flexible', 21], // IEEE trap: 30×0.7 = 21.000000000000004 → must NOT ceil to 22
    [30, 'disciplined', 26], // ceil(25.5)
    [30, 'extreme', 30],
    [20, 'disciplined', 17], // exact integer product
    [1, 'flexible', 1],
    [1, 'extreme', 1],
    [10, undefined, 10], // no mode = unanimous (team member rule)
  ];
  for (const [total, mode, required] of table) {
    it(`${total} units, ${mode ?? 'unanimous'} → ${required}`, () => {
      assert.equal(requiredUnits(total, mode), required);
    });
  }

  it('rejects invalid totals', () => {
    assert.throws(() => requiredUnits(0, 'flexible'), RangeError);
    assert.throws(() => requiredUnits(2.5, 'flexible'), RangeError);
  });
});

describe('loggedPerUnit (evidence aggregation + CC-5 cutoff)', () => {
  it('sums multiple records per unit', () => {
    const sums = loggedPerUnit(
      [
        ev({ unitIndex: 2, amount: 20 }),
        ev({ unitIndex: 2, amount: 30 }),
        ev({ unitIndex: 4, amount: 60 }),
      ],
      'u1',
      7,
      10_000,
    );
    assert.deepEqual(sums, [0, 0, 50, 0, 60, 0, 0]);
  });

  it('excludes records that arrived after the cutoff', () => {
    const sums = loggedPerUnit(
      [ev({ amount: 60, arrivedAtMs: 5_001 })],
      'u1',
      7,
      5_000,
    );
    assert.equal(sums[0], 0);
  });

  it('includes a record arriving exactly at the cutoff', () => {
    const sums = loggedPerUnit(
      [ev({ amount: 60, arrivedAtMs: 5_000 })],
      'u1',
      7,
      5_000,
    );
    assert.equal(sums[0], 60);
  });

  it('ignores other uids, out-of-range units, non-positive amounts', () => {
    const sums = loggedPerUnit(
      [
        ev({ uid: 'other', amount: 60 }),
        ev({ unitIndex: 7, amount: 60 }), // out of range (0-based, 7 units)
        ev({ unitIndex: -1, amount: 60 }),
        ev({ amount: 0 }),
        ev({ amount: -10 }),
      ],
      'u1',
      7,
      10_000,
    );
    assert.deepEqual(sums, [0, 0, 0, 0, 0, 0, 0]);
  });
});

describe('measureParticipant', () => {
  it('disciplined 7-day: 6 mercy-passing days pass the challenge', () => {
    // 45 min on six days (each passes via mercy), nothing on day 6.
    const evidence = [0, 1, 2, 3, 4, 5].map((unitIndex) =>
      ev({ unitIndex, amount: 45 }),
    );
    const r = measureParticipant(goal, 'disciplined', evidence, 'u1', 10_000);
    assert.equal(r.unitsPassed, 6);
    assert.equal(r.unitsRequired, 6);
    assert.equal(r.passed, true);
    assert.deepEqual(r.unitResults, [true, true, true, true, true, true, false]);
  });

  it('disciplined 7-day: 5 passing days fail the challenge', () => {
    const evidence = [0, 1, 2, 3, 4].map((unitIndex) =>
      ev({ unitIndex, amount: 60 }),
    );
    const r = measureParticipant(goal, 'disciplined', evidence, 'u1', 10_000);
    assert.equal(r.passed, false);
  });

  it('unanimous (team member): one missed day of 7 fails even with mercy elsewhere', () => {
    const evidence = [0, 1, 2, 3, 4, 5].map((unitIndex) =>
      ev({ unitIndex, amount: 60 }),
    );
    const r = measureParticipant(goal, undefined, evidence, 'u1', 10_000);
    assert.equal(r.unitsRequired, 7);
    assert.equal(r.passed, false);
  });
});

describe('isBackfillSuspicious (CC-5 flag)', () => {
  const decisionAt = 100 * 3_600_000; // t = 100h

  it('3 units first-arriving within the final hour → flagged', () => {
    const evidence = [0, 1, 2].map((unitIndex) =>
      ev({ unitIndex, arrivedAtMs: decisionAt - 10 * 60_000 }),
    );
    assert.equal(isBackfillSuspicious(evidence, 'u1', decisionAt), true);
  });

  it('2 late units → not flagged', () => {
    const evidence = [0, 1].map((unitIndex) =>
      ev({ unitIndex, arrivedAtMs: decisionAt - 10 * 60_000 }),
    );
    assert.equal(isBackfillSuspicious(evidence, 'u1', decisionAt), false);
  });

  it('a unit whose FIRST record arrived early is not late, even with a late top-up', () => {
    const evidence = [
      ev({ unitIndex: 0, arrivedAtMs: decisionAt - 50 * 3_600_000 }),
      ev({ unitIndex: 0, arrivedAtMs: decisionAt - 5 * 60_000 }), // late top-up
      ev({ unitIndex: 1, arrivedAtMs: decisionAt - 10 * 60_000 }),
      ev({ unitIndex: 2, arrivedAtMs: decisionAt - 10 * 60_000 }),
    ];
    assert.equal(isBackfillSuspicious(evidence, 'u1', decisionAt), false);
  });

  it('records arriving after the decision are ignored', () => {
    const evidence = [0, 1, 2].map((unitIndex) =>
      ev({ unitIndex, arrivedAtMs: decisionAt + 1 }),
    );
    assert.equal(isBackfillSuspicious(evidence, 'u1', decisionAt), false);
  });
});
