/**
 * P-7 / D11 — screenshot strike ladder and challenge-join bans.
 * Pure module; the enforcement doc IO lives in callables.ts.
 *
 * Bans block JOINING (create/accept) only — active challenges continue.
 */

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;

/** Ban duration for the Nth strike (1-based): 12h, 3d, then 7d forever. */
export function banDurationMsForStrike(strikeNumber: number): number {
  if (!Number.isInteger(strikeNumber) || strikeNumber < 1) {
    throw new RangeError('strikeNumber must be a positive integer');
  }
  if (strikeNumber === 1) return 12 * HOUR_MS;
  if (strikeNumber === 2) return 3 * DAY_MS;
  return 7 * DAY_MS;
}

export function isChallengeBanned(
  banUntilMs: number | undefined,
  nowMs: number,
): boolean {
  return banUntilMs !== undefined && banUntilMs > nowMs;
}

/** Shape of `enforcement/{uid}` (server-written only; client reads own). */
export interface EnforcementDoc {
  screenshotStrikeCount?: number;
  challengeBanUntilMs?: number;
  lastVetoAtMs?: number;
  updatedAtMs?: number;
}

export interface StrikeResult {
  strikeNumber: number;
  banUntilMs: number;
}

export function applyStrike(
  doc: EnforcementDoc | undefined,
  nowMs: number,
): StrikeResult {
  const strikeNumber = (doc?.screenshotStrikeCount ?? 0) + 1;
  return {
    strikeNumber,
    banUntilMs: nowMs + banDurationMsForStrike(strikeNumber),
  };
}
