/**
 * PT-1/PT-3 — the points economy, pure logic (no firebase imports).
 *
 * Design rules that make cheating boring:
 *  - Amounts are FIXED server-side per source; clients never pass amounts.
 *  - Transaction ids are DETERMINISTIC, so `create()` gives idempotency for
 *    free: replaying a grant (offline retry, double-tap, malicious loop)
 *    hits already-exists and changes nothing.
 *  - Daily caps are enforced on the balance doc's per-day counters.
 *  - The ledger is append-only truth; the balance field is a derived
 *    convenience maintained in the same transaction as every txn.
 *
 * Client-earnable sources ride on client-owned artifacts (tasks, goals),
 * so a determined cheater can inflate their own points — accepted at
 * launch and made EXPLICIT POLICY by the pre-launch audit (H7, decision
 * log 2026-09-15 D1): points never cash out (§1.1), caps bound the rate
 * (110/day with invented ids), and every consequential sink is fenced.
 * The one sink that could hurt someone else's stake — buying an early
 * photo removal — is payable only from TRUSTED points (signup bonus and
 * challenge wins, which the server awards), tracked per balance doc as
 * `trusted`. H2H stakes stay symmetric self-report on both sides.
 */

export type PointsSource =
  | 'signup_bonus'
  | 'earn_checkin'
  | 'earn_task'
  | 'earn_goal'
  | 'earn_streak'
  | 'earn_challenge_win'
  | 'stake_lock'
  | 'stake_release'
  | 'stake_forfeit'
  | 'spend_photo_removal';

/** Fixed amounts (PT-3, RC-tunable later). Sign is the ledger direction. */
export const EARN_AMOUNTS: Partial<Record<PointsSource, number>> = {
  signup_bonus: 50,
  earn_checkin: 5,
  earn_task: 2,
  earn_goal: 5,
  earn_streak: 15,
  earn_challenge_win: 50,
};

/** Per-day txn-count caps for client-initiated sources. */
export const DAILY_CAPS: Partial<Record<PointsSource, number>> = {
  earn_checkin: 1,
  earn_task: 20,
  earn_goal: 10,
  earn_streak: 1,
};

/** The only sources a client may request via grantPoints (PT-2). */
export const CLIENT_GRANTABLE: ReadonlySet<PointsSource> = new Set([
  'earn_checkin',
  'earn_task',
  'earn_goal',
  'earn_streak',
]);

/** D9 — early photo removal price (~1–2 weeks of honest earning). */
export const PHOTO_REMOVAL_PRICE = 300;

/**
 * Sources the SERVER decides (never a client-asserted artifact). Only
 * points from these can pay for a photo removal (audit H7 / D1).
 */
export const TRUSTED_SOURCES: ReadonlySet<PointsSource> = new Set([
  'signup_bonus',
  'earn_challenge_win',
]);

/**
 * Change to the balance doc's `trusted` counter for one txn: trusted
 * earnings add, the removal spend subtracts (it is paid FROM trusted),
 * everything else — self-reported earnings, stake locks/releases — leaves
 * it alone. Never below zero (legacy balances start without the field).
 */
export function trustedDelta(source: PointsSource, amount: number): number {
  if (TRUSTED_SOURCES.has(source)) return Math.max(0, amount);
  if (source === 'spend_photo_removal') return Math.min(0, amount);
  return 0;
}

/** H2H points stake bounds (PT-3 suggests 100–500; hard server bounds). */
export const H2H_STAKE_MIN = 50;
export const H2H_STAKE_MAX = 1000;

/** UTC day key used in deterministic ids and daily counters. */
export function dayKey(nowMs: number): string {
  const d = new Date(nowMs);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
}

/**
 * Deterministic txn id per source. refId is the client's artifact id
 * (taskId, goalId+unit, challengeId); ids embed the day where the grant is
 * per-day so replays collapse naturally.
 */
export function txnId(
  source: PointsSource,
  refId: string,
  nowMs: number,
): string {
  switch (source) {
    case 'signup_bonus':
      return 'signup_bonus';
    case 'earn_checkin':
    case 'earn_streak':
      return `${source}_${dayKey(nowMs)}`;
    case 'earn_task':
    case 'earn_goal':
      return `${source}_${refId}_${dayKey(nowMs)}`;
    case 'earn_challenge_win':
    case 'stake_lock':
    case 'stake_release':
    case 'stake_forfeit':
    case 'spend_photo_removal':
      return `${source}_${refId}`;
  }
}

/** refId sanity: ids from StableId / challenge ids; never paths. */
export function validRefId(refId: string): boolean {
  return /^[A-Za-z0-9_-]{1,80}$/.test(refId);
}

export interface BalanceDoc {
  balance?: number;
  dayKey?: string;
  dayCounts?: Record<string, number>;
  updatedAtMs?: number;
  /** Points from [TRUSTED_SOURCES] still unspent on removals (audit H7). */
  trusted?: number;
}

/**
 * Whether one more `source` grant fits under today's cap, and the updated
 * counters to persist. Counters live on the balance doc and reset when the
 * day changes — nothing unbounded accumulates.
 */
export function applyDailyCap(
  doc: BalanceDoc | undefined,
  source: PointsSource,
  nowMs: number,
): { allowed: boolean; dayKey: string; dayCounts: Record<string, number> } {
  const today = dayKey(nowMs);
  const counts: Record<string, number> =
    doc?.dayKey === today ? { ...(doc.dayCounts ?? {}) } : {};
  const cap = DAILY_CAPS[source];
  const used = counts[source] ?? 0;
  if (cap !== undefined && used >= cap) {
    return { allowed: false, dayKey: today, dayCounts: counts };
  }
  counts[source] = used + 1;
  return { allowed: true, dayKey: today, dayCounts: counts };
}
