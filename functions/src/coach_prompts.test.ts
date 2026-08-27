import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  DEFAULT_SYSTEM_PROMPTS,
  SERVER_PROMPT_PURPOSES,
  resolveSystemPrompt,
} from './coach_prompts';

describe('server-owned system prompts (fix-wave Phase 5, §8 S1)', () => {
  it('every chat-class purpose carries a substantial prompt', () => {
    for (const purpose of [
      'coach_agent',
      'chat',
      'coach_agent_voice',
      'coach_agent_voice_stream',
    ]) {
      const prompt = DEFAULT_SYSTEM_PROMPTS[purpose];
      assert.ok(prompt !== undefined, purpose);
      assert.ok(prompt.length > 1000, `${purpose} prompt looks truncated`);
      assert.ok(SERVER_PROMPT_PURPOSES.has(purpose));
    }
  });

  it('voice variants extend the base with their addenda', () => {
    const base = DEFAULT_SYSTEM_PROMPTS.coach_agent;
    assert.ok(DEFAULT_SYSTEM_PROMPTS.coach_agent_voice.startsWith(base));
    assert.ok(
      DEFAULT_SYSTEM_PROMPTS.coach_agent_voice.includes('VOICE MODE'),
    );
    // The tool-less stream variant must forbid claiming changes.
    assert.ok(
      DEFAULT_SYSTEM_PROMPTS.coach_agent_voice_stream.includes('answer-only'),
    );
  });

  it('the confirm-gate language survives verbatim', () => {
    // The load-bearing safety sentence — a prompt migration that lost it
    // would let the model claim direct writes.
    assert.ok(
      DEFAULT_SYSTEM_PROMPTS.coach_agent.includes(
        'you can NEVER change anything directly',
      ),
    );
  });

  it('system-class purposes are NOT server-owned', () => {
    for (const purpose of ['extract_memory', 'reflect', 'parse_intention']) {
      assert.equal(SERVER_PROMPT_PURPOSES.has(purpose), false);
      assert.equal(resolveSystemPrompt(purpose, '{}'), undefined);
    }
  });

  it('RC overrides win; malformed or blank overrides degrade to defaults', () => {
    assert.equal(
      resolveSystemPrompt('coach_agent', '{"coach_agent": "Be terse."}'),
      'Be terse.',
    );
    assert.equal(
      resolveSystemPrompt('coach_agent', 'not json {'),
      DEFAULT_SYSTEM_PROMPTS.coach_agent,
    );
    assert.equal(
      resolveSystemPrompt('coach_agent', '{"coach_agent": "   "}'),
      DEFAULT_SYSTEM_PROMPTS.coach_agent,
    );
    // An override for one purpose never bleeds into another.
    assert.equal(
      resolveSystemPrompt('chat', '{"coach_agent": "Be terse."}'),
      DEFAULT_SYSTEM_PROMPTS.chat,
    );
  });
});
