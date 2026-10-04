/**
 * Legacy circle-challenge vote tally (pre-launch audit M1).
 *
 * `circles/{id}/challenges/{cid}/votes/{uid}` stays client-written (rules:
 * own uid, active member). The STATUS flip used to be written by whichever
 * client counted a majority — any member could flip it without a vote.
 * Now rules deny every client `status` change on the challenge and this
 * trigger is the only writer: it recounts from the votes subcollection and
 * the ACTIVE member count inside a transaction, so a forged tally is not
 * expressible and a lost trigger event is repaired by the next vote.
 */

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';

import { tallyChallengeVotes } from './membership';

export const circleChallengeVoteTally = onDocumentWritten(
  {
    document: 'circles/{circleId}/challenges/{challengeId}/votes/{userId}',
    region: 'us-central1',
    memory: '256MiB',
    maxInstances: 10,
  },
  async (event) => {
    const { circleId, challengeId } = event.params;
    const db = getFirestore();
    const challengeRef = db.doc(`circles/${circleId}/challenges/${challengeId}`);
    const now = Date.now();

    await db.runTransaction(async (tx) => {
      const challenge = await tx.get(challengeRef);
      if (!challenge.exists || challenge.data()?.status !== 'pending') return;
      const [votes, members] = await Promise.all([
        tx.get(challengeRef.collection('votes')),
        tx.get(
          db.collection(`circles/${circleId}/members`).where('status', '==', 'active'),
        ),
      ]);
      const outcome = tallyChallengeVotes(
        votes.docs.map((v) => v.data().approve === true),
        members.size,
      );
      if (outcome === null) return;
      tx.update(challengeRef, { status: outcome, updatedAtMs: now });
      logger.info('circleChallengeVoteTally', {
        circleId,
        challengeId,
        outcome,
        votes: votes.size,
        activeMembers: members.size,
      });
    });
  },
);
