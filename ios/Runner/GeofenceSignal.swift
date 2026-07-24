import CoreLocation
import Foundation
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
      manager.requestAlwaysAuthorization()
      // The upgrade prompt may resolve silently (provisional always) or
      // not at all; report whenInUse if no further change arrives.
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.flushAuthCompletions()
      }
      return
    }
    flushAuthCompletions()
  }

  private func flushAuthCompletions() {
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
    var remaining: [[String: Any]] = []

    for intent in armed {
      guard let id = intent["intentionId"] as? String,
        let title = intent["title"] as? String,
        let body = intent["body"] as? String
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

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      content.userInfo = ["sidepal": "geofence", "intentionId": id]
      UNUserNotificationCenter.current().add(
        UNNotificationRequest(
          identifier: "geofence_\(id)", content: content, trigger: nil))
      // Fired → disarmed. One exit, one nudge; Dart re-arms on app open
      // if the promise is still open and the user still wants it.
    }

    defaults.set(remaining, forKey: Self.armedDefaultsKey)
  }
}
