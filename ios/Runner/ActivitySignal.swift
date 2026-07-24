import CoreMotion
import Foundation

// Activity-recognition snapshot (humanizing Phase 6a, PRD §9 Tier 2).
//
// In-house, same precedent as CalendarSignal: the API shape enforces the
// privacy contract by construction — the channel can ONLY return a coarse
// kind (still/walking/running/cycling/driving/unknown), a confidence
// label, and the reading's timestamp. No motion history, no raw samples,
// nothing persisted; snapshots are read at decision time only — there is
// NO background stream.
enum ActivitySignalBridge {
  static let manager = CMMotionActivityManager()

  /// "notDetermined" | "denied" | "authorized" | "unavailable".
  static func authorizationStatus() -> String {
    guard CMMotionActivityManager.isActivityAvailable() else {
      return "unavailable"
    }
    switch CMMotionActivityManager.authorizationStatus() {
    case .authorized: return "authorized"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  /// Core Motion has no standalone request API — the first history query
  /// IS the permission prompt. Requests by querying a tiny window, then
  /// reports whether the grant landed.
  static func requestAccess(completion: @escaping (Bool) -> Void) {
    guard CMMotionActivityManager.isActivityAvailable() else {
      completion(false)
      return
    }
    let now = Date()
    manager.queryActivityStarting(
      from: now.addingTimeInterval(-60), to: now, to: .main
    ) { _, _ in
      completion(authorizationStatus() == "authorized")
    }
  }

  /// The latest activity reading within the last `lookbackMs`, or nil when
  /// unavailable/denied/no data. Coarse kind + confidence + timestamp only.
  static func currentActivity(
    lookbackMs: Int64, completion: @escaping ([String: Any]?) -> Void
  ) {
    guard CMMotionActivityManager.isActivityAvailable(),
      CMMotionActivityManager.authorizationStatus() == .authorized
    else {
      completion(nil)
      return
    }
    let now = Date()
    let from = now.addingTimeInterval(-TimeInterval(lookbackMs) / 1000)
    manager.queryActivityStarting(from: from, to: now, to: .main) {
      activities, error in
      guard error == nil, let latest = activities?.last else {
        completion(nil)
        return
      }
      // capturedAtMs is the QUERY time, not the state's startDate — the
      // last history entry is the state as of now, however long ago the
      // walk/drive began.
      completion([
        "kind": kindLabel(latest),
        "confidence": confidenceLabel(latest.confidence),
        "capturedAtMs": Int64(now.timeIntervalSince1970 * 1000),
      ])
    }
  }

  /// Precedence mirrors how the flags co-occur in practice: a reading can
  /// be simultaneously "automotive + stationary" (stopped at a light) —
  /// the vehicle wins.
  private static func kindLabel(_ activity: CMMotionActivity) -> String {
    if activity.automotive { return "driving" }
    if activity.cycling { return "cycling" }
    if activity.running { return "running" }
    if activity.walking { return "walking" }
    if activity.stationary { return "still" }
    return "unknown"
  }

  private static func confidenceLabel(
    _ confidence: CMMotionActivityConfidence
  ) -> String {
    switch confidence {
    case .high: return "high"
    case .medium: return "medium"
    default: return "low"
    }
  }
}
