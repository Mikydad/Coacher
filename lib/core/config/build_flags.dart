/// Build-time switches (pre-launch audit M11, decision log 2026-09-15 D5).
///
/// `--dart-define=SIDEPAL_TESTER_BUILD=true` compiles the development
/// surfaces IN: the forced-crash smoke test behind the About & Support
/// long-press and the Reminder Debug screen. The App Store submission is
/// built WITHOUT it, so no customer or reviewer can reach a "crash the
/// app" control — TestFlight builds for the internal testers carry it.
/// Tester mode itself (bug bubble, AI recompute button) stays a per-account
/// privilege granted server-side (`tester_allowlist/{uid}`).
const bool kTesterBuild = bool.fromEnvironment(
  'SIDEPAL_TESTER_BUILD',
  defaultValue: false,
);
