/// Money stakes are parked (Miko, 2026-09-18): the server rail stays the
/// SIMULATED provider and nothing on the server changes, but no build —
/// debug, TestFlight or store — offers a money stake until this flips.
/// Existing money challenges, if any, still render in the hub and detail.
/// Supersedes the debug-only gate from the Phase 3 runbook.
const bool kMoneyStakesEnabled = false;
