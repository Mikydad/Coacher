#!/usr/bin/env node
/**
 * DEV TOOL — grant points to a test account by writing a real ledger txn
 * + balance update, exactly the shape the server writes (ledger.ts).
 * Clients can never write the ledger (rules deny), so this Admin-SDK
 * script is the only way to hand test points out-of-band.
 *
 * Source is 'dev_grant' — clearly distinguishable from every legitimate
 * earn source in the append-only history. Each run creates a new txn
 * (timestamped id), so repeated grants accumulate.
 *
 * Dry-run by default; --yes writes.
 *
 * Run from functions/ with GOOGLE_APPLICATION_CREDENTIALS set:
 *   node scripts/grant-points.js --email you@example.com [--amount 500] [--yes]
 *   node scripts/grant-points.js --uid <uid> [--amount 500] [--yes]
 */

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : undefined;
}
const COMMIT = process.argv.includes('--yes');

async function main() {
  const amount = Number(arg('amount') ?? 500);
  if (!Number.isInteger(amount) || amount === 0) {
    throw new Error('--amount must be a non-zero integer');
  }

  initializeApp();

  let uid = arg('uid');
  const email = arg('email');
  if (!uid && email) {
    uid = (await getAuth().getUserByEmail(email)).uid;
    console.log(`Resolved ${email} → uid ${uid}`);
  }
  if (!uid) throw new Error('Pass --uid <uid> or --email <email>');

  const db = getFirestore();
  const balanceRef = db.collection('points_ledger').doc(uid);
  const now = Date.now();
  const txnRef = balanceRef.collection('txns').doc(`dev_grant_${now}`);

  const before = (await balanceRef.get()).data()?.balance ?? 0;
  console.log(`Current balance: ${before}`);
  if (!COMMIT) {
    console.log(
      `Dry run — would grant ${amount} (new balance ${before + amount}). ` +
        'Re-run with --yes.',
    );
    return;
  }

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(balanceRef);
    const current = snap.data() ?? {};
    tx.set(txnRef, {
      source: 'dev_grant',
      amount,
      refId: 'dev',
      atMs: now,
      updatedAtMs: now,
    });
    tx.set(
      balanceRef,
      { ...current, balance: (current.balance ?? 0) + amount, updatedAtMs: now },
      { merge: true },
    );
  });
  const after = (await balanceRef.get()).data()?.balance;
  console.log(`Granted ${amount}. New balance: ${after}`);
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
