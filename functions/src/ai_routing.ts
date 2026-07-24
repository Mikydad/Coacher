// Purpose routing for the aiChat proxy (humanizing PRD §7, settled: Q3).
//
// Every call declares a `purpose`; a Remote-Config-driven table maps purpose
// → model / temperature / max-tokens / quota class / kill switch. Only
// user-facing purposes charge the user's hourly chat quota; system purposes
// (extraction, parsing, nudge phrasing) draw from a separate per-user daily
// budget with silent-skip semantics — the user must never see a quota error
// for a call they didn't make.
//
// Pure logic, no IO — unit-tested in ai_routing.test.ts.

export type QuotaClass = "user" | "system";

export interface PurposeRoute {
  model: string;
  /** Hard cap for this purpose; the client may ask for less, never more. */
  maxTokens: number;
  quotaClass: QuotaClass;
  /** Per-purpose kill switch (beside the client-side `ai_enabled`). */
  enabled: boolean;
  /** When set, pins the temperature server-side (client value ignored). */
  temperature?: number;
}

/** Applied to any purpose missing from the table — matches the pre-Phase-2
 *  behavior exactly (user quota, default model), so unknown/legacy callers
 *  never regress. */
export const FALLBACK_ROUTE: PurposeRoute = {
  model: "gpt-4o-mini",
  maxTokens: 800,
  quotaClass: "user",
  enabled: true,
};

/** Compile-time defaults; Remote Config (`ai_purpose_routes`) overrides
 *  per-field. Chat stays gpt-4o-mini — upgradeable per-purpose by config
 *  flip, no client release. */
export const DEFAULT_ROUTES: Record<string, PurposeRoute> = {
  // User-facing (charge the 40/hr chat quota).
  coach_agent: { model: "gpt-4o-mini", maxTokens: 800, quotaClass: "user", enabled: true },
  chat: { model: "gpt-4o-mini", maxTokens: 800, quotaClass: "user", enabled: true },
  coaching_summary: { model: "gpt-4o-mini", maxTokens: 800, quotaClass: "user", enabled: true },
  circle_pulse: { model: "gpt-4o-mini", maxTokens: 800, quotaClass: "user", enabled: true },
  // System purposes (separate daily budget, silent-skip on exhaustion).
  parse_intention: {
    model: "gpt-4o-mini", maxTokens: 300, quotaClass: "system", enabled: true, temperature: 0,
  },
  extract_memory: {
    model: "gpt-4o-mini", maxTokens: 900, quotaClass: "system", enabled: true, temperature: 0,
  },
  phrase_nudge: {
    model: "gpt-4o-mini", maxTokens: 200, quotaClass: "system", enabled: true, temperature: 0.4,
  },
  summarize: {
    model: "gpt-4o-mini", maxTokens: 600, quotaClass: "system", enabled: true, temperature: 0.2,
  },
  // Thinking Loop (humanizing Phase 7): ≤1 budgeted reflection pass per
  // device-day over the user's full local picture. `enabled: false` here or
  // via Remote Config is the kill switch — the client silent-skips.
  reflect: {
    model: "gpt-4o-mini", maxTokens: 700, quotaClass: "system", enabled: true, temperature: 0.2,
  },
};

/** Models the routing table may select. A config typo must not let a
 *  request escape to an arbitrary (expensive) model. */
const ALLOWED_MODELS = new Set([
  "gpt-4o-mini",
  "gpt-4o",
  "gpt-4.1-mini",
  "gpt-4.1",
]);

/** Parses the `ai_purpose_routes` Remote Config JSON (partial per-purpose
 *  overrides). Malformed input yields no overrides — config can degrade
 *  the table, never break the proxy. */
export function parseRouteOverrides(
  json: string | undefined,
): Record<string, Partial<PurposeRoute>> {
  if (json === undefined || json.length === 0) return {};
  let decoded: unknown;
  try {
    decoded = JSON.parse(json);
  } catch {
    return {};
  }
  if (typeof decoded !== "object" || decoded === null || Array.isArray(decoded)) {
    return {};
  }
  const overrides: Record<string, Partial<PurposeRoute>> = {};
  for (const [purpose, raw] of Object.entries(decoded)) {
    if (typeof raw !== "object" || raw === null || Array.isArray(raw)) continue;
    const entry = raw as Record<string, unknown>;
    const override: Partial<PurposeRoute> = {};
    if (typeof entry.model === "string" && ALLOWED_MODELS.has(entry.model)) {
      override.model = entry.model;
    }
    if (
      typeof entry.maxTokens === "number" &&
      Number.isFinite(entry.maxTokens) &&
      entry.maxTokens >= 1
    ) {
      override.maxTokens = Math.floor(entry.maxTokens);
    }
    if (entry.quotaClass === "user" || entry.quotaClass === "system") {
      override.quotaClass = entry.quotaClass;
    }
    if (typeof entry.enabled === "boolean") {
      override.enabled = entry.enabled;
    }
    if (
      typeof entry.temperature === "number" &&
      Number.isFinite(entry.temperature) &&
      entry.temperature >= 0 &&
      entry.temperature <= 1
    ) {
      override.temperature = entry.temperature;
    }
    overrides[purpose] = override;
  }
  return overrides;
}

/** Resolves the effective route for a purpose: defaults, overridden
 *  per-field by config; unknown purposes get [FALLBACK_ROUTE]. */
export function resolveRoute(
  purpose: string,
  overrides: Record<string, Partial<PurposeRoute>>,
): PurposeRoute {
  const base = DEFAULT_ROUTES[purpose] ?? FALLBACK_ROUTE;
  const override = overrides[purpose];
  if (override === undefined) return base;
  return {
    model: override.model ?? base.model,
    maxTokens: override.maxTokens ?? base.maxTokens,
    quotaClass: override.quotaClass ?? base.quotaClass,
    enabled: override.enabled ?? base.enabled,
    temperature: override.temperature ?? base.temperature,
  };
}

/** UTC day key for the system-budget window ("2026-07-23"). */
export function utcDayKey(nowMs: number): string {
  return new Date(nowMs).toISOString().slice(0, 10);
}
