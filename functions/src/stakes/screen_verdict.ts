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
 * H1 (pre-launch audit 2026-09-15) — a verdict is only meaningful for ONE
 * object: the uploader's own photo at the exact path the challenge pins.
 * Before this, the verdict doc was keyed by challengeId alone, so a
 * stranger's upload to `stake_photos/{victimId}/{stranger}.jpg` could
 * activate (unscreened) or cancel the victim's draft.
 */
export interface ScreenBinding {
  uid: string;
  path: string;
  /** Storage object generation, when known (trigger path only). */
  generation?: string;
}

export const STAKE_PHOTOS_PREFIX = 'stake_photos/';

/** `stake_photos/{challengeId}/{uid}.jpg` → its parts; anything else → null. */
export function parseStakePhotoObject(
  name: string,
): { challengeId: string; uid: string } | null {
  if (!name.startsWith(STAKE_PHOTOS_PREFIX)) return null;
  const parts = name.split('/');
  if (parts.length !== 3) return null;
  const [, challengeId, fileName] = parts;
  if (!challengeId || !fileName.endsWith('.jpg')) return null;
  const uid = fileName.slice(0, -'.jpg'.length);
  if (!uid) return null;
  return { challengeId, uid };
}

/** The verdict may touch the challenge only if it screened THIS participant's photo. */
export function verdictBindsTo(
  binding: ScreenBinding | undefined,
  participant: { uid: string; photoPath: string | undefined } | undefined,
): boolean {
  if (!binding || !participant || !participant.photoPath) return false;
  return binding.uid === participant.uid && binding.path === participant.photoPath;
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
