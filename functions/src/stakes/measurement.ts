/**
 * M-1/M-2/M-3 — mercy math and evidence aggregation.
 *
 * Pure functions; all threshold comparisons use integer arithmetic so IEEE
 * float artifacts can never flip a pass/fail (30 × 0.7 → 21.000000000000004
 * would ceil to 22 and forfeit an innocent user).
 */

import {
  BACKFILL_FLAG_MIN_UNITS,
  BACKFILL_FLAG_WINDOW_MS,
  EvidenceRecord,
  FrozenGoal,
  MODE_REQUIRED_PERCENT,
  SoloMode,
  UNIT_MERCY_PERCENT,
} from './types';

/** M-1 — a unit passes at ≥75% of target. Integer-safe: logged×100 ≥ target×75. */
export function unitPasses(logged: number, unitTarget: number): boolean {
  if (unitTarget <= 0) throw new RangeError('unitTarget must be > 0');
  return logged * 100 >= unitTarget * UNIT_MERCY_PERCENT;
}

/**
 * M-2 — units required for a solo/h2h pass under a mode.
 * `mode === undefined` means unanimous (team member rule, M-3).
 */
export function requiredUnits(
  totalUnits: number,
  mode: SoloMode | undefined,
): number {
  if (!Number.isInteger(totalUnits) || totalUnits <= 0) {
    throw new RangeError('totalUnits must be a positive integer');
  }
  if (mode === undefined) return totalUnits;
  const pct = MODE_REQUIRED_PERCENT[mode];
  return Math.ceil((totalUnits * pct) / 100);
}

/**
 * Sums evidence per unit for one participant, counting only records the
 * server received by `arrivalCutoffMs` (CC-5 — the decision moment; evidence
 * syncing later changes nothing).
 */
export function loggedPerUnit(
  evidence: readonly EvidenceRecord[],
  uid: string,
  totalUnits: number,
  arrivalCutoffMs: number,
): number[] {
  const sums = new Array<number>(totalUnits).fill(0);
  for (const record of evidence) {
    if (record.uid !== uid) continue;
    if (record.arrivedAtMs > arrivalCutoffMs) continue;
    if (record.unitIndex < 0 || record.unitIndex >= totalUnits) continue;
    if (record.amount <= 0) continue;
    sums[record.unitIndex] += record.amount;
  }
  return sums;
}

export interface MeasurementResult {
  unitsPassed: number;
  unitsRequired: number;
  passed: boolean;
  /** Per-unit pass flags, for the detail-screen unit grid. */
  unitResults: boolean[];
}

/** Evidence-only verdict for one participant (before disputes/votes). */
export function measureParticipant(
  goal: FrozenGoal,
  mode: SoloMode | undefined,
  evidence: readonly EvidenceRecord[],
  uid: string,
  arrivalCutoffMs: number,
): MeasurementResult {
  const sums = loggedPerUnit(evidence, uid, goal.totalUnits, arrivalCutoffMs);
  const unitResults = sums.map((logged) => unitPasses(logged, goal.unitTarget));
  const unitsPassed = unitResults.filter(Boolean).length;
  const unitsRequired = requiredUnits(goal.totalUnits, mode);
  return {
    unitsPassed,
    unitsRequired,
    passed: unitsPassed >= unitsRequired,
    unitResults,
  };
}

/**
 * CC-5 — flag (never auto-fail) when ≥3 distinct units' evidence FIRST
 * arrived within the final hour before the decision: the signature of a
 * bulk backfill racing the cutoff. A single offline device syncing days of
 * honest timer sessions right after reconnect looks identical — which is
 * exactly why this only surfaces to the circle for a human look (V-1).
 */
export function isBackfillSuspicious(
  evidence: readonly EvidenceRecord[],
  uid: string,
  decisionAtMs: number,
): boolean {
  const earliestArrival = new Map<number, number>();
  for (const record of evidence) {
    if (record.uid !== uid) continue;
    if (record.arrivedAtMs > decisionAtMs) continue;
    const prior = earliestArrival.get(record.unitIndex);
    if (prior === undefined || record.arrivedAtMs < prior) {
      earliestArrival.set(record.unitIndex, record.arrivedAtMs);
    }
  }
  let lateUnits = 0;
  const windowStart = decisionAtMs - BACKFILL_FLAG_WINDOW_MS;
  for (const arrivedAtMs of earliestArrival.values()) {
    if (arrivedAtMs >= windowStart) lateUnits += 1;
  }
  return lateUnits >= BACKFILL_FLAG_MIN_UNITS;
}
