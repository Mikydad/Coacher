import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  buildChatBody,
  modelFamily,
  reasoningEffortFor,
  supportsChatToolCalling,
} from './ai_request';

describe('modelFamily / reasoningEffortFor', () => {
  it('classifies gpt-4o and gpt-4.1 as legacy with no reasoning parameter', () => {
    for (const m of ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1', 'gpt-4.1-mini', 'gpt-4.1-nano']) {
      assert.equal(modelFamily(m), 'legacy', m);
      assert.equal(reasoningEffortFor(m), null, m);
    }
  });
  it('gives the original gpt-5 family "minimal" and everything newer "none"', () => {
    assert.equal(reasoningEffortFor('gpt-5'), 'minimal');
    assert.equal(reasoningEffortFor('gpt-5-mini'), 'minimal');
    assert.equal(reasoningEffortFor('gpt-5-nano'), 'minimal');
    for (const m of ['gpt-5.1', 'gpt-5.4-mini', 'gpt-5.6-luna', 'gpt-6-luna', 'gpt-6-sol']) {
      assert.equal(reasoningEffortFor(m), 'none', m);
    }
  });
  it('rules out models that cannot call tools on Chat Completions', () => {
    assert.equal(supportsChatToolCalling('gpt-6-astra'), false);
    assert.equal(supportsChatToolCalling('o3-mini'), false);
    assert.equal(supportsChatToolCalling('gpt-6-luna'), true);
    assert.equal(supportsChatToolCalling('gpt-4o-mini'), true);
  });
});

describe('buildChatBody', () => {
  const messages = [{ role: 'user', content: 'hi' }];
  const tools = [{ type: 'function', function: { name: 'propose_changes' } }];

  it('keeps the classic shape for gpt-4o-mini (byte-for-byte what shipped)', () => {
    const body = buildChatBody({
      model: 'gpt-4o-mini', messages, maxTokens: 800, temperature: 0.6, tools,
    });
    assert.deepEqual(body, {
      model: 'gpt-4o-mini',
      messages,
      max_tokens: 800,
      temperature: 0.6,
      tools,
      tool_choice: 'auto',
    });
  });

  it('uses max_completion_tokens, reasoning_effort none and keeps temperature for gpt-6-luna', () => {
    const body = buildChatBody({
      model: 'gpt-6-luna', messages, maxTokens: 800, temperature: 0.6, tools,
    });
    assert.equal(body.max_tokens, undefined);
    assert.equal(body.max_completion_tokens, 800);
    assert.equal(body.reasoning_effort, 'none');
    assert.equal(body.temperature, 0.6);
    assert.equal(body.tool_choice, 'auto');
  });

  it('drops temperature where only "minimal" exists (gpt-5-mini)', () => {
    const body = buildChatBody({
      model: 'gpt-5-mini', messages, maxTokens: 500, temperature: 0.7,
    });
    assert.equal(body.reasoning_effort, 'minimal');
    assert.equal(body.temperature, undefined);
    assert.equal(body.max_completion_tokens, 500);
  });

  it('adds json mode for tool-less callers and stream options when streaming', () => {
    const json = buildChatBody({ model: 'gpt-4o-mini', messages, maxTokens: 300, jsonMode: true });
    assert.deepEqual(json.response_format, { type: 'json_object' });
    const stream = buildChatBody({ model: 'gpt-4o-mini', messages, maxTokens: 300, stream: true });
    assert.equal(stream.stream, true);
    assert.deepEqual(stream.stream_options, { include_usage: true });
  });
});
