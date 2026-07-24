/**
 * The morning-brief push cron (humanizing Phase 5c, PRD §8). Every 15
 * minutes it finds devices that opted in (`morningBriefEnabled` mirrored
 * onto their deviceTokens doc — the preference is device-local by
 * design, so the flag lives per-device, not per-user), and for users
 * whose local clock is inside the 08:00–10:00 window, who have NOT
 * opened the app today, and who have at least one open promise, sends
 * one deterministic brief per local day. The existing Home snackbar
 * remains the in-app fallback: any check-in today silences the push.
 *
 * Index note (errors.md discipline): the collection-group query is a
 * single equality on morningBriefEnabled — one declared fieldOverride,
 * no composite. Open promises are counted with a plain single-field
 * equality query on the user's own intentions collection (automatic
 * index), active/window filtered in memory.
 *
 * Bookkeeping is server-owned (`users/{uid}/briefState/morning`) —
 * client outbox upserts can never clobber it.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { Message } from 'firebase-admin/messaging';

import { briefAction, localDayKey } from './brief_rules';
import { DeviceToken, sendToTokens } from './push_send';

const BATCH_LIMIT = 500;

/** One full brief pass — extracted so tests/dev tools can run it on demand. */
export async function runMorningBriefOnce(
  now: number,
): Promise<Record<string, number>> {
  const db = getFirestore();
  const counts = { users: 0, sent: 0, skipped: 0, tokensPruned: 0 };

  const optedIn = await db
    .collectionGroup('deviceTokens')
    .where('morningBriefEnabled', '==', true)
    .limit(BATCH_LIMIT)
    .get();

  // Group opted-in device docs by user.
  const byUid = new Map<string, FirebaseFirestore.QueryDocumentSnapshot[]>();
  for (const doc of optedIn.docs) {
    const uid = doc.ref.parent.parent?.id;
    if (!uid) continue;
    const list = byUid.get(uid) ?? [];
    list.push(doc);
    byUid.set(uid, list);
  }

  for (const [uid, briefDocs] of byUid) {
    counts.users += 1;

    // Freshness looks at ALL of the user's devices — an app open on the
    // non-opted-in phone still means "seen today" and hands the morning
    // to the in-app snackbar.
    const allDevices = await db.collection(`users/${uid}/deviceTokens`).get();
    let lastSeenMs: number | null = null;
    for (const doc of allDevices.docs) {
      const seen = doc.data().lastSeenMs as number | undefined;
      if (typeof seen === 'number' && (lastSeenMs === null || seen > lastSeenMs)) {
        lastSeenMs = seen;
      }
    }

    // Local clock follows the most recently seen OPTED-IN device.
    let tzOffsetMinutes = 0;
    let bestSeen = -1;
    const tokens: DeviceToken[] = [];
    for (const doc of briefDocs) {
      const data = doc.data();
      const token = data.token as string | undefined;
      if (token) tokens.push({ docId: doc.id, token });
      const seen = (data.lastSeenMs as number | undefined) ?? 0;
      const tz = data.tzOffsetMinutes as number | undefined;
      if (typeof tz === 'number' && seen > bestSeen) {
        bestSeen = seen;
        tzOffsetMinutes = tz;
      }
    }
    if (tokens.length === 0) {
      counts.skipped += 1;
      continue;
    }

    const stateRef = db.doc(`users/${uid}/briefState/morning`);
    const state = (await stateRef.get()).data();
    const lastBriefDayKey =
      (state?.lastBriefDayKey as string | undefined) ?? null;

    // Cheap gates first; the promise count read only happens when the
    // window/day/freshness checks could actually lead to a send.
    const preCheck = briefAction({
      enabled: true,
      lastSeenMs,
      tzOffsetMinutes,
      lastBriefDayKey,
      openPromises: 1, // placeholder — real count fetched below if needed
      nowMs: now,
    });
    if (preCheck.kind === 'skip') {
      counts.skipped += 1;
      continue;
    }

    const openPromises = await countOpenPromises(uid, now);
    const action = briefAction({
      enabled: true,
      lastSeenMs,
      tzOffsetMinutes,
      lastBriefDayKey,
      openPromises,
      nowMs: now,
    });
    if (action.kind === 'skip') {
      counts.skipped += 1;
      continue;
    }

    counts.tokensPruned += await sendToTokens(uid, tokens, (token) =>
      briefMessage(token, action.title, action.body),
    );
    counts.sent += 1;
    await stateRef.set(
      { lastBriefDayKey: localDayKey(now, tzOffsetMinutes), updatedAtMs: now },
      { merge: true },
    );
  }

  logger.info('morningBrief done', counts);
  return counts;
}

export const morningBrief = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
    maxInstances: 1,
  },
  async () => {
    await runMorningBriefOnce(Date.now());
  },
);

async function countOpenPromises(uid: string, now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(`users/${uid}/intentions`)
    .where('status', '==', 'open')
    .get();
  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.active === false) continue;
    const windowEndMs = data.windowEndMs as number | undefined;
    // A window that already passed is the client's to mark expired, not
    // the brief's to count.
    if (typeof windowEndMs === 'number' && windowEndMs <= now) continue;
    count += 1;
  }
  return count;
}

function briefMessage(token: string, title: string, body: string): Message {
  return {
    token,
    notification: { title, body },
    data: { type: 'morning_brief' },
    apns: {
      // At most one brief lives in Notification Center.
      headers: { 'apns-collapse-id': 'morning_brief' },
    },
  };
}
