import { test } from "node:test";
import assert from "node:assert/strict";

import {
  SPEECH_DEFAULT_VOICE,
  SPEECH_MAX_CHARS,
  bearerTokenFrom,
  resolveSpeechVoice,
  validateSpeechText,
} from "./speech_rules";

test("validateSpeechText accepts and trims a normal reply", () => {
  const result = validateSpeechText("  You promised Sara a call today. \n");
  assert.deepEqual(result, {
    ok: true,
    text: "You promised Sara a call today.",
  });
});

test("validateSpeechText rejects non-strings", () => {
  assert.equal(validateSpeechText(undefined).ok, false);
  assert.equal(validateSpeechText(null).ok, false);
  assert.equal(validateSpeechText(42).ok, false);
  assert.equal(validateSpeechText(["hi"]).ok, false);
});

test("validateSpeechText rejects blank text", () => {
  assert.equal(validateSpeechText("").ok, false);
  assert.equal(validateSpeechText("   \n\t").ok, false);
});

test("validateSpeechText enforces the cost cap", () => {
  assert.equal(validateSpeechText("a".repeat(SPEECH_MAX_CHARS)).ok, true);
  assert.equal(validateSpeechText("a".repeat(SPEECH_MAX_CHARS + 1)).ok, false);
});

test("resolveSpeechVoice accepts allowlisted voices case-insensitively", () => {
  assert.equal(resolveSpeechVoice("coral"), "coral");
  assert.equal(resolveSpeechVoice(" Nova "), "nova");
  assert.equal(resolveSpeechVoice("ONYX"), "onyx");
});

test("resolveSpeechVoice degrades unknown or unset values to the default", () => {
  assert.equal(resolveSpeechVoice("siri"), SPEECH_DEFAULT_VOICE);
  assert.equal(resolveSpeechVoice(""), SPEECH_DEFAULT_VOICE);
  assert.equal(resolveSpeechVoice(undefined), SPEECH_DEFAULT_VOICE);
});

test("bearerTokenFrom extracts the token from a well-formed header", () => {
  assert.equal(bearerTokenFrom("Bearer abc.def.ghi"), "abc.def.ghi");
  assert.equal(bearerTokenFrom("bearer tok123"), "tok123"); // scheme is case-insensitive
  assert.equal(bearerTokenFrom("  Bearer padded  "), "padded");
});

test("bearerTokenFrom rejects missing or malformed headers", () => {
  assert.equal(bearerTokenFrom(undefined), null);
  assert.equal(bearerTokenFrom(""), null);
  assert.equal(bearerTokenFrom("Bearer"), null);
  assert.equal(bearerTokenFrom("Basic dXNlcjpwYXNz"), null);
  assert.equal(bearerTokenFrom("Bearer two tokens"), null);
});
