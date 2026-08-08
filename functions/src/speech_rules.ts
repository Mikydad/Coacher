// Request validation + voice resolution for the aiSpeech TTS proxy
// (humanizing voice upgrade — OpenAI TTS for Voice Mode).
//
// Pure logic, no IO — unit-tested in speech_rules.test.ts. The callable
// shell (speech.ts) maps failures onto HttpsError codes.

/// One Coach reply is ≤800 tokens (~3k chars) BEFORE speech sanitization
/// strips markdown and [mem:…] markers, so a healthy client never comes
/// near this. It exists to bound abuse cost, not to trim real replies.
export const SPEECH_MAX_CHARS = 2000;

/// One synthesis call per Coach reply; a dense hour of conversation is
/// ~40 replies (the chat quota), so 90 leaves comfortable headroom while
/// still bounding a runaway client.
export const SPEECH_RATE_LIMIT_PER_HOUR = 90;

export const SPEECH_MODEL = "gpt-4o-mini-tts";
export const SPEECH_DEFAULT_VOICE = "coral";

/// The voices /v1/audio/speech accepts today. An unknown Remote Config
/// value degrades to the default instead of failing every call.
const ALLOWED_VOICES = new Set([
  "alloy",
  "ash",
  "ballad",
  "coral",
  "echo",
  "fable",
  "nova",
  "onyx",
  "sage",
  "shimmer",
  "verse",
]);

export type SpeechTextResult =
  | { ok: true; text: string }
  | { ok: false; reason: string };

/// Validates the client-supplied text: must be a non-blank string within
/// the cost cap. Returns the trimmed text — trailing whitespace is not
/// worth synthesis tokens.
export function validateSpeechText(raw: unknown): SpeechTextResult {
  if (typeof raw !== "string") {
    return { ok: false, reason: "text must be a string." };
  }
  const text = raw.trim();
  if (text.length === 0) {
    return { ok: false, reason: "text must not be empty." };
  }
  if (text.length > SPEECH_MAX_CHARS) {
    return { ok: false, reason: "text too long." };
  }
  return { ok: true, text };
}

/// Resolves the voice from a Remote Config value; anything outside the
/// allowlist (including empty / unset) falls back to the default voice.
export function resolveSpeechVoice(rawConfigValue: string | undefined): string {
  const voice = (rawConfigValue ?? "").trim().toLowerCase();
  return ALLOWED_VOICES.has(voice) ? voice : SPEECH_DEFAULT_VOICE;
}

/// Extracts the ID token from an `Authorization: Bearer <token>` header.
/// The streaming endpoint (speech_stream.ts) is an onRequest function, so
/// unlike the callable it parses auth itself.
export function bearerTokenFrom(header: string | undefined): string | null {
  if (typeof header !== "string") return null;
  const match = /^Bearer\s+(\S+)$/i.exec(header.trim());
  return match ? match[1] : null;
}
