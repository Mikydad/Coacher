import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  DEFAULT_ROUTES,
  FALLBACK_ROUTE,
  parseRouteOverrides,
  resolveRoute,
  utcDayKey,
} from './ai_routing';

describe('resolveRoute', () => {
  it('unknown purposes get the fallback (user quota — pre-Phase-2 behavior)', () => {
    const route = resolveRoute('unknown', {});
    assert.deepEqual(route, FALLBACK_ROUTE);
    assert.equal(route.quotaClass, 'user');
  });

  it('coach_agent stays on the user quota with the pinned model', () => {
    const route = resolveRoute('coach_agent', {});
    assert.equal(route.quotaClass, 'user');
    assert.equal(route.model, 'gpt-4o-mini');
  });

  it('extract_memory is a system purpose with temperature pinned to 0', () => {
    const route = resolveRoute('extract_memory', {});
    assert.equal(route.quotaClass, 'system');
    assert.equal(route.temperature, 0);
  });

  it('overrides replace only the provided fields', () => {
    const route = resolveRoute('extract_memory', {
      extract_memory: { model: 'gpt-4o', enabled: false },
    });
    assert.equal(route.model, 'gpt-4o');
    assert.equal(route.enabled, false);
    // Untouched fields keep their defaults.
    assert.equal(route.quotaClass, 'system');
    assert.equal(route.maxTokens, DEFAULT_ROUTES.extract_memory.maxTokens);
  });
});

describe('parseRouteOverrides', () => {
  it('malformed JSON yields no overrides (config degrades, never breaks)', () => {
    assert.deepEqual(parseRouteOverrides('not json {{{'), {});
    assert.deepEqual(parseRouteOverrides('[1,2]'), {});
    assert.deepEqual(parseRouteOverrides(undefined), {});
    assert.deepEqual(parseRouteOverrides(''), {});
  });

  it('accepts valid partial overrides', () => {
    const overrides = parseRouteOverrides(
      '{"phrase_nudge":{"enabled":false},"chat":{"model":"gpt-4o","maxTokens":600}}',
    );
    assert.deepEqual(overrides.phrase_nudge, { enabled: false });
    assert.deepEqual(overrides.chat, { model: 'gpt-4o', maxTokens: 600 });
  });

  it('rejects models outside the allow-list (typo cannot pick an expensive model)', () => {
    const overrides = parseRouteOverrides('{"chat":{"model":"gpt-5-ultra"}}');
    assert.equal(overrides.chat.model, undefined);
  });

  it('rejects out-of-range temperatures and token counts', () => {
    const overrides = parseRouteOverrides(
      '{"chat":{"temperature":3,"maxTokens":-5}}',
    );
    assert.equal(overrides.chat.temperature, undefined);
    assert.equal(overrides.chat.maxTokens, undefined);
  });

  it('ignores non-object purpose entries', () => {
    const overrides = parseRouteOverrides('{"chat":"off","summarize":{"enabled":true}}');
    assert.equal(overrides.chat, undefined);
    assert.deepEqual(overrides.summarize, { enabled: true });
  });
});

describe('utcDayKey', () => {
  it('formats as yyyy-mm-dd in UTC', () => {
    assert.equal(utcDayKey(Date.UTC(2026, 6, 23, 23, 59)), '2026-07-23');
    assert.equal(utcDayKey(Date.UTC(2026, 6, 24, 0, 1)), '2026-07-24');
  });
});
