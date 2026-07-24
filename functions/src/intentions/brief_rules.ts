/**
 * Pure decision rules for the morning-brief push (humanizing Phase 5c,
 * PRD §8: "Morning brief as push, with the existing local snackbar as
 * the no-push fallback"). Deterministic copy, no LLM, no I/O.
 *
 * Division of labour with the client: the in-app snackbar (Home,
 * 06:00–10:00, once/day) owns users who OPEN the app in the morning;
 * this push owns the ones who don't. Hence the `seen_today` skip — the
 * moment a device checks in, the server goes quiet and the local
 * surface takes over. Nothing to say (zero open promises) also means
 * no push: a quiet app stays quiet.
 *
 * The `morningBriefEnabled` preference is device-local (it never
 * synced between devices), so the flag rides on each deviceTokens doc
 * — mirrored by heartbeats and immediately on toggle — and the brief
 * goes only to devices that opted in.
 */

import { localHour } from './rescue_rules';

/** Send window in device-local hours: [start, end). Narrower than the
 * snackbar's 06:00 start — a push at dawn is ruder than a snackbar. */
export const BRIEF_HOUR_START = 8;
export const BRIEF_HOUR_END = 10;

export type BriefAction =
  | { kind: 'skip'; reason: string }
  | { kind: 'send'; title: string; body: string };

/** yyyy-mm-dd of the device-local day containing `nowMs`. */
export function localDayKey(nowMs: number, tzOffsetMinutes: number): string {
  const d = new Date(nowMs + tzOffsetMinutes * 60_000);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/** UTC ms of the device-local midnight that started the current day. */
export function localDayStartMs(nowMs: number, tzOffsetMinutes: number): number {
  const offsetMs = tzOffsetMinutes * 60_000;
  const shifted = nowMs + offsetMs;
  return Math.floor(shifted / 86_400_000) * 86_400_000 - offsetMs;
}

/** Deterministic brief copy — question-form, count only, no titles. */
export function composeBrief(openPromises: number): {
  title: string;
  body: string;
} {
  const body = openPromises === 1
    ? 'One open promise today — want a quick plan?'
    : `${openPromises} open promises today — want a quick plan?`;
  return { title: 'Good morning', body };
}

export function briefAction(args: {
  /** Any of the user's devices opted in (per-device preference). */
  enabled: boolean;
  /** Max lastSeenMs across ALL devices — an open on any device today
   * hands the morning over to the in-app snackbar. */
  lastSeenMs: number | null;
  tzOffsetMinutes: number;
  /** Server-owned once-per-local-day guard. */
  lastBriefDayKey: string | null;
  openPromises: number;
  nowMs: number;
}): BriefAction {
  const {
    enabled,
    lastSeenMs,
    tzOffsetMinutes,
    lastBriefDayKey,
    openPromises,
    nowMs,
  } = args;

  if (!enabled) return { kind: 'skip', reason: 'disabled' };

  const hour = localHour(nowMs, tzOffsetMinutes);
  if (hour < BRIEF_HOUR_START || hour >= BRIEF_HOUR_END) {
    return { kind: 'skip', reason: 'outside_window' };
  }

  const today = localDayKey(nowMs, tzOffsetMinutes);
  if (lastBriefDayKey === today) {
    return { kind: 'skip', reason: 'already_briefed' };
  }

  if (
    lastSeenMs !== null &&
    lastSeenMs >= localDayStartMs(nowMs, tzOffsetMinutes)
  ) {
    return { kind: 'skip', reason: 'seen_today' };
  }

  if (openPromises <= 0) return { kind: 'skip', reason: 'nothing_to_say' };

  return { kind: 'send', ...composeBrief(openPromises) };
}
