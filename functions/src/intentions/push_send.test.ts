import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { Message } from 'firebase-admin/messaging';

import { sendToTokens } from './push_send';

const build = (token: string): Message => ({ token, data: { type: 'test' } });

function tokens(...names: string[]) {
  return names.map((n) => ({ docId: `doc_${n}`, token: n }));
}

describe('sendToTokens (P2-02 honest bookkeeping)', () => {
  it('counts every accepted send as delivered', async () => {
    const sent: string[] = [];
    const result = await sendToTokens('u1', tokens('a', 'b'), build, {
      send: async (m) => sent.push((m as { token: string }).token),
    });
    assert.deepEqual(result, { delivered: 2, pruned: 0 });
    assert.deepEqual(sent, ['a', 'b']);
  });

  it('returns delivered 0 on transient failure so callers do not stamp state', async () => {
    const result = await sendToTokens('u1', tokens('a'), build, {
      send: async () => {
        throw Object.assign(new Error('unavailable'), {
          code: 'messaging/internal-error',
        });
      },
      removeToken: async () => assert.fail('transient error must not prune'),
    });
    assert.deepEqual(result, { delivered: 0, pruned: 0 });
  });

  it('prunes dead tokens without counting them as delivered', async () => {
    const removed: string[] = [];
    const result = await sendToTokens('u1', tokens('dead', 'alive'), build, {
      send: async (m) => {
        if ((m as { token: string }).token === 'dead') {
          throw Object.assign(new Error('gone'), {
            code: 'messaging/registration-token-not-registered',
          });
        }
      },
      removeToken: async (docId) => removed.push(docId),
    });
    assert.deepEqual(result, { delivered: 1, pruned: 1 });
    assert.deepEqual(removed, ['doc_dead']);
  });

  it('empty token list delivers nothing', async () => {
    const result = await sendToTokens('u1', [], build, {
      send: async () => assert.fail('nothing to send'),
    });
    assert.deepEqual(result, { delivered: 0, pruned: 0 });
  });
});
