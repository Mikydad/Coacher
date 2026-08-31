/**
 * The Reminder V2 rescue-net cron (PRD §5 [L-PUSH], task 13.0) — cloned
 * from intentionSweep's shape: every 15 minutes, maxInstances 1, a testable
 * `runReminderSweepOnce(now)`, pure rules (rescue_rules.ts), no LLM.
 *
 * Reads two client-written surfaces: the synced reminderOccurrences (the
 * state machine's own rows, replicated LWW by the outbox) and the
 * deviceTokens heartbeats (freshness). Writes ONE server-owned surface:
 * `users/{uid}/reminderRescue/{occurrenceId}` — bookkeeping the client
 * never touches.
 *
 * Index note (errors.md #10/#16/#18): the collection-group query uses a
 * SINGLE range field (scheduledAtMs) with a declared field override in
 * firestore.indexes.json — state/mode/criticality filter in memory. No
 * composite.
 *
 * This layer is an ENHANCEMENT, never a dependency (PRD §5): local
 * notifications fire with the app closed, so everything here covers only
 * what a compiled ladder cannot — the Extreme tail past windowEnd, and the
 * crit-3 net for a device dark since before its due moment.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { Message } from 'firebase-admin/messaging';

import { DeviceToken, sendToTokens } from '../intentions/push_send';
import {
  ReminderOccurrenceSnapshot,
  ReminderRescueState,
  reminderRescueAction,
} from './rescue_rules';

const BATCH_LIMIT = 200;
const MAX_PAGES = 10;

/** How far back an unresolved occurrence stays rescueable: the deepest tail
 * push lands at windowEnd + 3h, so 12h comfortably covers every live case
 * while keeping the scan bounded. */
const LOOKBACK_MS = 12 * 60 * 60 * 1000;

interface UserDevices {
  tokens: DeviceToken[];
  lastSeenMs: number | null;
}

/** One full sweep pass — extracted so tests/dev tools can run it on demand. */
export async function runReminderSweepOnce(
  now: number,
): Promise<Record<string, number>> {
  const db = getFirestore();
  const counts = {
    scanned: 0,
    tails: 0,
    critRescues: 0,
    skipped: 0,
    sendFailures: 0,
    tokensPruned: 0,
  };

  const deviceCache = new Map<string, UserDevices>();

  let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (let page = 0; page < MAX_PAGES; page += 1) {
    let query = db
      .collectionGroup('reminderOccurrences')
      .where('scheduledAtMs', '>', now - LOOKBACK_MS)
      .where('scheduledAtMs', '<=', now)
      .orderBy('scheduledAtMs')
      .limit(BATCH_LIMIT);
    if (cursor) query = query.startAfter(cursor);
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      counts.scanned += 1;
      const uid = doc.ref.parent.parent?.id;
      if (!uid) continue;

      const data = doc.data();
      const occ: ReminderOccurrenceSnapshot = {
        id: doc.id,
        entityId: (data.entityId as string | undefined) ?? '',
        entityTitle: (data.entityTitle as string | undefined) ?? '',
        state: (data.state as string | undefined) ?? 'upcoming',
        scheduledAtMs: (data.scheduledAtMs as number | undefined) ?? 0,
        windowMinutes: (data.windowMinutes as number | undefined) ?? 30,
        criticality: (data.criticality as number | undefined) ?? 1,
        modeRefId: (data.modeRefId as string | undefined) ?? null,
      };

      // Cheap pre-filter before any extra reads; the pure rules re-check.
      const covered =
        occ.state !== 'resolved' &&
        ((occ.modeRefId ?? '').toLowerCase() === 'extreme' ||
          occ.criticality >= 3);
      if (!covered) {
        counts.skipped += 1;
        continue;
      }

      const devices = await devicesFor(uid, deviceCache);
      const stateRef = db.doc(`users/${uid}/reminderRescue/${doc.id}`);
      const state = ((await stateRef.get()).data() ??
        null) as ReminderRescueState | null;

      const action = reminderRescueAction({
        occ,
        lastSeenMs: devices.lastSeenMs,
        state,
        nowMs: now,
      });

      if (action.kind === 'skip') {
        counts.skipped += 1;
        continue;
      }

      const result = await sendToTokens(uid, devices.tokens, (token) =>
        rescueMessage(token, occ, action),
      );
      counts.tokensPruned += result.pruned;
      if (result.delivered === 0) {
        // Honest bookkeeping: nothing reached FCM, so the state stays
        // untouched and the next run retries.
        counts.sendFailures += 1;
        continue;
      }

      if (action.kind === 'tail') {
        counts.tails += 1;
        await stateRef.set(
          {
            tailCount: action.tailIndex,
            lastPushAtMs: now,
            updatedAtMs: now,
          },
          { merge: true },
        );
      } else {
        counts.critRescues += 1;
        await stateRef.set(
          { critRescued: true, lastPushAtMs: now, updatedAtMs: now },
          { merge: true },
        );
      }
    }

    cursor = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < BATCH_LIMIT) break;
  }

  logger.info('reminderSweep done', counts);
  return counts;
}

export const reminderSweep = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
    maxInstances: 1,
  },
  async () => {
    await runReminderSweepOnce(Date.now());
  },
);

async function devicesFor(
  uid: string,
  cache: Map<string, UserDevices>,
): Promise<UserDevices> {
  const cached = cache.get(uid);
  if (cached) return cached;
  const db = getFirestore();
  const snap = await db.collection(`users/${uid}/deviceTokens`).get();
  let lastSeenMs: number | null = null;
  const tokens: DeviceToken[] = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const token = data.token as string | undefined;
    if (token) tokens.push({ docId: doc.id, token });
    const seen = data.lastSeenMs as number | undefined;
    if (typeof seen === 'number' && (lastSeenMs === null || seen > lastSeenMs)) {
      lastSeenMs = seen;
    }
  }
  const devices: UserDevices = {
    tokens,
    lastSeenMs: tokens.length === 0 ? null : lastSeenMs,
  };
  cache.set(uid, devices);
  return devices;
}

function rescueMessage(
  token: string,
  occ: ReminderOccurrenceSnapshot,
  action: { kind: 'tail' | 'critWindow'; title: string; body: string },
): Message {
  return {
    token,
    notification: { title: action.title, body: action.body },
    // The tap route the client already speaks: a task payload opens the
    // task; the entityId is what the response handler resolves.
    data: {
      type: 'reminder_rescue',
      entityId: occ.entityId,
      occurrenceId: occ.id,
    },
    apns: {
      // Repeats replace, never stack — one visible rescue per occurrence.
      headers: { 'apns-collapse-id': `rem_rescue_${occ.id}` },
    },
  };
}
