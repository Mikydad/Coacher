/**
 * P-2 — NSFW screening of stake photos at upload time.
 *
 * Vision SafeSearch via REST (no new npm deps — google-auth-library ships
 * with firebase-admin). Deploy prerequisite: enable the Cloud Vision API on
 * the project (`gcloud services enable vision.googleapis.com`).
 *
 * ## The upload/create handshake
 * The client uploads the photo BEFORE calling stakeCreateChallenge, so the
 * screening trigger and the challenge doc race. Both orders work:
 *   - Trigger finishes first → verdict stored in `stake_photo_screens/{id}`;
 *     stakeCreateChallenge reads it inside its transaction and creates the
 *     challenge already `active` (approve) or refuses creation (reject).
 *   - Create finishes first → challenge sits `draft`/`pending_screen`; the
 *     trigger applies the verdict transactionally when done.
 * Screening failures leave `pending_screen` + an error event — visible, not
 * silently approved. A stake photo NEVER goes live unscreened.
 */

import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { GoogleAuth } from 'google-auth-library';

import { CHALLENGES, eventDoc } from './firestore_layout';
import {
  parseStakePhotoObject,
  SafeSearchAnnotation,
  ScreenBinding,
  ScreenVerdict,
  screeningVerdict,
  verdictBindsTo,
} from './screen_verdict';
import { assertTransition } from './state_machine';

export const PHOTO_SCREENS = 'stake_photo_screens';

/**
 * M12 — upload reservations. `stakeReservePhotoUpload` writes
 * `stake_photo_reservations/{challengeId}` = {uid, atMs, expiresAtMs}
 * before the client uploads; storage.rules requires it for the create, and
 * this trigger refuses to spend a Vision call on an object without one.
 */
export const PHOTO_RESERVATIONS = 'stake_photo_reservations';
export const PHOTO_RESERVATION_TTL_MS = 6 * 3_600_000;

function participantPhoto(
  data: FirebaseFirestore.DocumentData,
): { uid: string; photoPath: string | undefined } | undefined {
  const participants = data.participants as
    | Array<{ uid?: string; photo?: { storagePath?: string } }>
    | undefined;
  const p = participants?.find((x) => typeof x.photo?.storagePath === 'string');
  if (!p || typeof p.uid !== 'string') return undefined;
  return { uid: p.uid, photoPath: p.photo?.storagePath };
}

// ─── Vision REST call ────────────────────────────────────────────────────────

async function safeSearch(gsUri: string): Promise<SafeSearchAnnotation> {
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const token = await auth.getAccessToken();
  const response = await fetch(
    'https://vision.googleapis.com/v1/images:annotate',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        requests: [
          {
            image: { source: { imageUri: gsUri } },
            features: [{ type: 'SAFE_SEARCH_DETECTION' }],
          },
        ],
      }),
      signal: AbortSignal.timeout(30_000),
    },
  );
  if (!response.ok) {
    const body = await response.text().catch(() => '');
    throw new Error(`Vision ${response.status}: ${body.slice(0, 300)}`);
  }
  const json = (await response.json()) as {
    responses?: Array<{
      safeSearchAnnotation?: SafeSearchAnnotation;
      error?: { message?: string };
    }>;
  };
  const first = json.responses?.[0];
  if (first?.error) throw new Error(`Vision error: ${first.error.message}`);
  if (!first?.safeSearchAnnotation) {
    throw new Error('Vision returned no SafeSearch annotation');
  }
  return first.safeSearchAnnotation;
}

// ─── Applying a verdict to the challenge (both handshake orders) ─────────────

/**
 * Transactionally applies a stored verdict to a draft challenge. No-op when
 * the challenge doesn't exist yet (create side will consume the screen doc)
 * or already left `pending_screen` (idempotence).
 */
export async function applyVerdictToChallenge(
  challengeId: string,
  verdict: ScreenVerdict,
  nowMs: number,
  binding: ScreenBinding | undefined,
): Promise<void> {
  const db = getFirestore();
  const ref = db.collection(CHALLENGES).doc(challengeId);
  let deletePhotoPath: string | undefined;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const data = snap.data()!;
    if (data.status !== 'draft' || data.photoState !== 'pending_screen') {
      return;
    }
    // H1 — the verdict must be about THIS participant's photo object.
    if (!verdictBindsTo(binding, participantPhoto(data))) {
      logger.warn('stake photo verdict ignored: binding mismatch', {
        challengeId,
        verdictUid: binding?.uid,
        verdictPath: binding?.path,
      });
      return;
    }
    if (verdict.approved) {
      assertTransition('draft', 'active');
      tx.update(ref, {
        status: 'active',
        photoState: 'approved',
        updatedAtMs: nowMs,
      });
      tx.create(
        ref.collection('events').doc(),
        eventDoc({ type: 'activated', atMs: nowMs, data: { screen: 'passed' } }),
      );
    } else {
      assertTransition('draft', 'cancelled');
      tx.update(ref, {
        status: 'cancelled',
        photoState: 'rejected',
        updatedAtMs: nowMs,
      });
      tx.create(
        ref.collection('events').doc(),
        eventDoc({
          type: 'cancelled',
          atMs: nowMs,
          data: { screen: 'rejected', reasons: verdict.reasons.join(',') },
        }),
      );
      // Binding verified above: this is the participant's own object.
      deletePhotoPath = binding?.path;
    }
  });

  if (deletePhotoPath) {
    await getStorage()
      .bucket()
      .file(deletePhotoPath)
      .delete({ ignoreNotFound: true });
  }
}

// ─── The trigger ─────────────────────────────────────────────────────────────

export const stakePhotoUploaded = onObjectFinalized(
  {
    // Storage triggers must live in the BUCKET's region — this project's
    // default bucket is us-east1 (everything else stays us-central1).
    region: 'us-east1',
    memory: '256MiB',
    maxInstances: 5,
    timeoutSeconds: 60,
  },
  async (event) => {
    const name = event.data.name ?? '';
    const parsed = parseStakePhotoObject(name);
    if (!parsed) return;
    const { challengeId, uid } = parsed;

    const now = Date.now();
    const db = getFirestore();
    const screenRef = db.collection(PHOTO_SCREENS).doc(challengeId);
    const binding: ScreenBinding = {
      uid,
      path: name,
      generation: `${event.data.generation ?? ''}`,
    };

    // M12 — no reservation, no paid screening. storage.rules already
    // requires the reservation for the create, so an object without one
    // only exists via a rules gap or a stale deploy; drop it.
    const reservation = (
      await db.collection(PHOTO_RESERVATIONS).doc(challengeId).get()
    ).data();
    let solicited = reservation?.uid === uid;
    if (!solicited) {
      // Re-upload for an existing challenge (support re-run after a Vision
      // error) — the challenge itself pins the object, so it is solicited.
      const ch = await db.collection(CHALLENGES).doc(challengeId).get();
      solicited = ch.exists && verdictBindsTo(binding, participantPhoto(ch.data()!));
    }
    if (!solicited) {
      logger.warn('stake photo without a matching reservation — deleted', {
        challengeId,
        uid,
        reservedBy: reservation?.uid,
      });
      await getStorage()
        .bucket(event.data.bucket)
        .file(name)
        .delete({ ignoreNotFound: true })
        .catch(() => undefined);
      return;
    }

    let verdict: ScreenVerdict;
    try {
      const annotation = await safeSearch(`gs://${event.data.bucket}/${name}`);
      verdict = screeningVerdict(annotation);
    } catch (error) {
      // Visible failure, never a silent approve. The challenge stays draft;
      // support/redeploy can re-run by re-uploading.
      logger.error('stake photo screening failed', {
        challengeId,
        error: `${error}`,
      });
      await screenRef.set({
        status: 'error',
        error: `${error}`.slice(0, 500),
        atMs: now,
        ...binding,
      });
      await db
        .collection(CHALLENGES)
        .doc(challengeId)
        .collection('events')
        .doc()
        .create(
          eventDoc({ type: 'photo_screen_pending', atMs: now, data: { error: true } }),
        )
        .catch(() => undefined); // challenge may not exist yet — fine
      return;
    }

    await screenRef.set({
      status: verdict.approved ? 'approved' : 'rejected',
      reasons: verdict.reasons,
      atMs: now,
      ...binding,
    });
    await applyVerdictToChallenge(challengeId, verdict, now, binding);
    logger.info('stake photo screened', {
      challengeId,
      approved: verdict.approved,
      reasons: verdict.reasons,
    });
  },
);
