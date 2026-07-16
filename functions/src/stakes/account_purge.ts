/**
 * P-8 — account deletion purges stakes. The app's in-app "Delete account"
 * (Apple requirement, already shipped) deletes the Firebase Auth user;
 * this v1 trigger then:
 *   1. cancels every non-terminal challenge the user participates in,
 *   2. deletes their stake photos and evidence photos from Storage,
 *   3. deletes their enforcement doc and photo-screen docs.
 * Terminal challenges keep their event history (auditability — spec CC-3),
 * but the photos are gone.
 *
 * v1 because Auth onDelete has no v2 equivalent (identity blocking
 * functions are a different product); v1 and v2 coexist fine.
 */

import * as functionsV1 from 'firebase-functions/v1';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { CHALLENGES, eventDoc } from './firestore_layout';
import { PHOTO_SCREENS } from './nsfw_screen';

/** Statuses that may still move to cancelled (CC-2's non-terminal set). */
const CANCELLABLE = new Set([
  'draft',
  'pending_accept',
  'active',
  'pending_verification',
]);

export const stakeAccountPurge = functionsV1
  .region('us-central1')
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const now = Date.now();

    const challenges = await db
      .collection(CHALLENGES)
      .where('participantUids', 'array-contains', uid)
      .get();

    let cancelled = 0;
    for (const doc of challenges.docs) {
      const status = doc.data().status as string;

      // Non-terminal → cancelled (Phase 4 adds refunds here).
      if (CANCELLABLE.has(status)) {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          const s = fresh.data()?.status as string;
          if (!CANCELLABLE.has(s)) return;
          tx.update(doc.ref, {
            status: 'cancelled',
            photoState: 'deleted',
            updatedAtMs: now,
          });
          tx.create(
            doc.ref.collection('events').doc(),
            eventDoc({ type: 'cancelled', uid, atMs: now, data: { accountDeleted: true } }),
          );
        });
        cancelled += 1;
      }

      // Photos are purged regardless of challenge state.
      await bucket
        .deleteFiles({ prefix: `stake_photos/${doc.id}/` })
        .catch((e) => logger.warn('purge stake_photos failed', { id: doc.id, e: `${e}` }));
      await bucket
        .deleteFiles({ prefix: `stake_evidence/${doc.id}/${uid}/` })
        .catch((e) => logger.warn('purge stake_evidence failed', { id: doc.id, e: `${e}` }));
      await db
        .collection(PHOTO_SCREENS)
        .doc(doc.id)
        .delete()
        .catch(() => undefined);
    }

    await db.collection('enforcement').doc(uid).delete().catch(() => undefined);

    logger.info('stakeAccountPurge done', {
      uid,
      challenges: challenges.size,
      cancelled,
    });
  });
