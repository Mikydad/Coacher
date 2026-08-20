import CoreLocation
import Foundation
import UIKit
import UserNotifications

// Home-exit geofence (humanizing Phase 6b, PRD §9 Tier 3).
//
// Privacy contract, by construction:
// - ONE region only ("home", explicit one-time setup) — no POI regions,
//   no tracking, no location history. The only coordinates this file
//   ever stores are the home anchor, device-local in UserDefaults.
// - Raw coordinates never cross the bridge except home setup's one-shot
//   read, and never leave the device.
//
// Platform reality: a region exit can arrive with the app force-quit —
// iOS relaunches us into the background with NO Flutter engine. So the
// armed intents (id + prerendered copy + window + polite hours, written
// by Dart at arm time) live in UserDefaults, and the notification is
// presented natively. Each armed intent fires at most once per arming;
// Dart re-syncs the list on every app open, pruning done/expired ones.
class GeofenceSignalBridge: NSObject, CLLocationManagerDelegate {
  static let shared = GeofenceSignalBridge()

  static let homeRegionId = "sidepal_home"
  static let homeDefaultsKey = "geofence_home_v1"
  static let armedDefaultsKey = "geofence_armed_v1"
  static let homeRadiusMeters: CLLocationDistance = 150

  private let manager = CLLocationManager()
  private var authCompletions: [(String) -> Void] = []
  private var locationCompletions: [([String: Any]?) -> Void] = []

  // Always-upgrade watch (Tier-1 review fix). The whenInUse→always upgrade
  // may (a) show a dialog the user reads slowly, (b) resolve silently, or
  // (c) show nothing at all (the one-time prompt was already consumed) —
  // and answering "Keep Only While Using" fires NO authorization callback.
  // A blind short timer both hangs case (c)…and mis-records a slow grant
  // as declined. Instead: a system alert makes the app resign active, so
  // we watch for that. Dialog detected → flush on didBecomeActive (the
  // choice is committed by then). No dialog within 2s → nothing is coming;
  // flush with the current status.
  private var alwaysUpgradeRequested = false
  private var upgradePromptDetected = false
  private var upgradeNoPromptTimer: DispatchWorkItem?
  private var upgradeResignObserver: NSObjectProtocol?
  private var upgradeActiveObserver: NSObjectProtocol?

  override private init() {
    super.init()
    manager.delegate = self
  }

  /// Called from AppDelegate at launch: recreating the manager + delegate
  /// is what lets iOS deliver the exit event after a background relaunch.
  func activateAtLaunch() {
    // Touching `shared` created the manager; nothing else needed.
  }

  // MARK: - Authorization

  /// "notDetermined" | "whenInUse" | "always" | "denied" | "unavailable".
  func authorizationStatus() -> String {
    guard CLLocationManager.isMonitoringAvailable(
      for: CLCircularRegion.self)
    else { return "unavailable" }
    // The instance property is iOS 14+; the class method covers 13.
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    switch status {
    case .authorizedAlways: return "always"
    case .authorizedWhenInUse: return "whenInUse"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  /// Requests the strongest grant the ladder allows: whenInUse first,
  /// then the Always upgrade (region exits with the app dead need it —
  /// iOS may grant provisional Always and confirm with the user later).
  func requestAccess(completion: @escaping (String) -> Void) {
    let status = authorizationStatus()
    switch status {
    case "notDetermined":
      authCompletions.append(completion)
      manager.requestWhenInUseAuthorization()
    case "whenInUse":
      authCompletions.append(completion)
      beginUpgradeWatch()
      alwaysUpgradeRequested = true
      manager.requestAlwaysAuthorization()
    default:
      completion(status)
    }
  }

  // iOS 13 delegate spelling; iOS 14+ calls the parameterless variant.
  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    handleAuthorizationChange()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleAuthorizationChange()
  }

  private func handleAuthorizationChange() {
    let status = authorizationStatus()
    guard status != "notDetermined" else { return }
    // Escalate whenInUse → always exactly once per request chain.
    if status == "whenInUse", !authCompletions.isEmpty {
      if alwaysUpgradeRequested {
        // The upgrade watch owns the flush — a whenInUse re-fire while the
        // Always dialog may still be pending must not cut it short.
        return
      }
      beginUpgradeWatch()
      alwaysUpgradeRequested = true
      manager.requestAlwaysAuthorization()
      return
    }
    flushAuthCompletions()
  }

  private func beginUpgradeWatch() {
    cancelUpgradeWatch()
    upgradeResignObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      // A system alert presented — however long the user reads it, do NOT
      // time out; the answer arrives via the delegate or didBecomeActive.
      self?.upgradePromptDetected = true
      self?.upgradeNoPromptTimer?.cancel()
      self?.upgradeNoPromptTimer = nil
    }
    upgradeActiveObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self, self.upgradePromptDetected else { return }
      // Dialog dismissed. "Keep Only While Using" fires no authorization
      // callback, so this is the only signal for that answer. Give a
      // delegate callback (Always granted) a beat to land first — the
      // flush reads the committed status either way.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.flushAuthCompletions()
      }
    }
    // No system alert within 2s means the one-time upgrade prompt was
    // already consumed — nothing further will arrive; report what we have.
    let work = DispatchWorkItem { [weak self] in
      guard let self, !self.upgradePromptDetected else { return }
      self.flushAuthCompletions()
    }
    upgradeNoPromptTimer = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
  }

  private func cancelUpgradeWatch() {
    upgradeNoPromptTimer?.cancel()
    upgradeNoPromptTimer = nil
    if let observer = upgradeResignObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if let observer = upgradeActiveObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    upgradeResignObserver = nil
    upgradeActiveObserver = nil
    upgradePromptDetected = false
    alwaysUpgradeRequested = false
  }

  private func flushAuthCompletions() {
    cancelUpgradeWatch()
    guard !authCompletions.isEmpty else { return }
    let status = authorizationStatus()
    let pending = authCompletions
    authCompletions = []
    for completion in pending { completion(status) }
  }

  // MARK: - One-shot location (home setup only)

  func currentLocation(completion: @escaping ([String: Any]?) -> Void) {
    guard authorizationStatus() == "always"
      || authorizationStatus() == "whenInUse"
    else {
      completion(nil)
      return
    }
    locationCompletions.append(completion)
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.requestLocation()
  }

  func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    let payload: [String: Any]? = locations.last.map {
      [
        "latitude": $0.coordinate.latitude,
        "longitude": $0.coordinate.longitude,
      ]
    }
    let pending = locationCompletions
    locationCompletions = []
    for completion in pending { completion(payload) }
  }

  func locationManager(
    _ manager: CLLocationManager, didFailWithError error: Error
  ) {
    let pending = locationCompletions
    locationCompletions = []
    for completion in pending { completion(nil) }
  }

  // MARK: - Home region

  func setHome(latitude: Double, longitude: Double) {
    UserDefaults.standard.set(
      ["latitude": latitude, "longitude": longitude],
      forKey: Self.homeDefaultsKey)
    startMonitoringHome(latitude: latitude, longitude: longitude)
  }

  func clearHome() {
    UserDefaults.standard.removeObject(forKey: Self.homeDefaultsKey)
    UserDefaults.standard.removeObject(forKey: Self.armedDefaultsKey)
    for region in manager.monitoredRegions
    where region.identifier == Self.homeRegionId {
      manager.stopMonitoring(for: region)
    }
  }

  func hasHome() -> Bool {
    UserDefaults.standard.dictionary(forKey: Self.homeDefaultsKey) != nil
  }

  private func startMonitoringHome(latitude: Double, longitude: Double) {
    for region in manager.monitoredRegions
    where region.identifier == Self.homeRegionId {
      manager.stopMonitoring(for: region)
    }
    let region = CLCircularRegion(
      center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
      radius: Self.homeRadiusMeters,
      identifier: Self.homeRegionId)
    region.notifyOnExit = true
    region.notifyOnEntry = false
    manager.startMonitoring(for: region)
  }

  // MARK: - Armed intents

  /// Dart writes the full armed list at arm/sync time. Each entry:
  /// {intentionId, title, body, windowStartMs, windowEndMs,
  ///  politeStartHour, politeEndHour}.
  func setArmedIntents(_ intents: [[String: Any]]) {
    UserDefaults.standard.set(intents, forKey: Self.armedDefaultsKey)
  }

  // MARK: - Exit handling (may run with no Flutter engine)

  func locationManager(
    _ manager: CLLocationManager, didExitRegion region: CLRegion
  ) {
    guard region.identifier == Self.homeRegionId else { return }
    fireArmedIntents(now: Date())
  }

  func fireArmedIntents(now: Date) {
    let defaults = UserDefaults.standard
    guard
      let armed = defaults.array(forKey: Self.armedDefaultsKey)
        as? [[String: Any]], !armed.isEmpty
    else { return }

    let nowMs = Int64(now.timeIntervalSince1970 * 1000)
    let hour = Calendar.current.component(.hour, from: now)
    var candidates: [[String: Any]] = []
    var remaining: [[String: Any]] = []

    for intent in armed {
      guard intent["intentionId"] is String,
        intent["title"] is String,
        intent["body"] is String
      else { continue }
      let windowStart = (intent["windowStartMs"] as? NSNumber)?.int64Value ?? 0
      let windowEnd =
        (intent["windowEndMs"] as? NSNumber)?.int64Value ?? Int64.max
      let politeStart = (intent["politeStartHour"] as? NSNumber)?.intValue ?? 8
      let politeEnd = (intent["politeEndHour"] as? NSNumber)?.intValue ?? 22

      if nowMs > windowEnd { continue }  // expired — drop silently
      if nowMs < windowStart || hour < politeStart || hour >= politeEnd {
        remaining.append(intent)  // not yet / impolite — stays armed
        continue
      }
      candidates.append(intent)
    }

    // One exit, ONE nudge (P2-06): a departure is a moment, not a slot for
    // a checklist. Fire only the most urgent eligible intent (soonest
    // deadline); the others stay armed for the next departure.
    func deadline(_ intent: [String: Any]) -> Int64 {
      (intent["windowEndMs"] as? NSNumber)?.int64Value ?? Int64.max
    }
    if let best = candidates.min(by: { deadline($0) < deadline($1) }),
      let id = best["intentionId"] as? String,
      let title = best["title"] as? String,
      let body = best["body"] as? String
    {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      // flutter_local_notifications surfaces userInfo["payload"] as
      // response.payload, so a tap on this native notification routes
      // through the same intention flow as a Dart-scheduled nudge, and
      // the category attaches the Done / Later / Wrong time actions
      // (P2-05). Keep the string in sync with NotificationCategoryIds.
      content.userInfo = [
        "sidepal": "geofence",
        "intentionId": id,
        "payload": "intention:\(id)",
      ]
      content.categoryIdentifier = "sidepalIntentionNudge.v1"
      UNUserNotificationCenter.current().add(
        UNNotificationRequest(
          identifier: "geofence_\(id)", content: content, trigger: nil))
      // Fired → disarmed. Dart re-arms on app open if the promise is
      // still open and the user still wants it.
      remaining += candidates.filter {
        ($0["intentionId"] as? String) != id
      }
    }

    defaults.set(remaining, forKey: Self.armedDefaultsKey)
  }
}
