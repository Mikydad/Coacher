import { defineSecret } from "firebase-functions/params";

// Shared across aiChat (index.ts) and aiSpeech (speech.ts). A param may only
// be registered once per process, so the single definition lives here.
export const openAiApiKey = defineSecret("OPENAI_API_KEY");
