/**
 * P-2 — pure SafeSearch verdict logic (no firebase imports; unit-tested).
 * The Vision call + trigger IO live in nsfw_screen.ts.
 */

const LIKELIHOOD_ORDER = [
  'UNKNOWN',
  'VERY_UNLIKELY',
  'UNLIKELY',
  'POSSIBLE',
  'LIKELY',
  'VERY_LIKELY',
] as const;

export type Likelihood = (typeof LIKELIHOOD_ORDER)[number];

export interface SafeSearchAnnotation {
  adult?: string;
  violence?: string;
  racy?: string;
}

function atLeast(value: string | undefined, bar: Likelihood): boolean {
  const idx = LIKELIHOOD_ORDER.indexOf((value ?? 'UNKNOWN') as Likelihood);
  return idx >= LIKELIHOOD_ORDER.indexOf(bar);
}

export interface ScreenVerdict {
  approved: boolean;
  reasons: string[];
}

/**
 * Reject: adult ≥ LIKELY, violence ≥ LIKELY, racy ≥ VERY_LIKELY.
 * (SafeSearch has no minor-age detection — the in-flow "this is a photo of
 * me" attestation plus report/review covers that class, per PRD P-2/P-8.)
 */
export function screeningVerdict(a: SafeSearchAnnotation): ScreenVerdict {
  const reasons: string[] = [];
  if (atLeast(a.adult, 'LIKELY')) reasons.push('adult');
  if (atLeast(a.violence, 'LIKELY')) reasons.push('violence');
  if (atLeast(a.racy, 'VERY_LIKELY')) reasons.push('racy');
  return { approved: reasons.length === 0, reasons };
}
