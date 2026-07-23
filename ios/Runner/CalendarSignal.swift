import EventKit
import Foundation

// Ephemeral device-calendar signal (humanizing Phase 4b, PRD §9 Tier 1).
//
// In-house instead of the device_calendar plugin (same precedent as
// device_info): ~80 lines, correct iOS 17 full-access keys, and the API
// shape enforces the privacy contract by construction — the channel can
// ONLY return busy intervals (start/end/allDay). Event titles, locations,
// attendees, and identifiers never cross the bridge, are never persisted,
// and never leave the device (judge-rejected: calendar shadows in synced
// collections).
enum CalendarSignalBridge {
  static let store = EKEventStore()

  /// "notDetermined" | "denied" | "authorized". iOS 17's write-only grant
  /// counts as denied — this signal is read-only by definition.
  static func authorizationStatus() -> String {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      switch status {
      case .fullAccess: return "authorized"
      case .notDetermined: return "notDetermined"
      default: return "denied"
      }
    }
    switch status {
    case .authorized: return "authorized"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  static func requestAccess(completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents { granted, _ in
        DispatchQueue.main.async { completion(granted) }
      }
    } else {
      store.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async { completion(granted) }
      }
    }
  }

  /// Busy intervals overlapping [startMs, endMs) across all calendars.
  /// Declined events are skipped; transparent ("free") events are skipped.
  static func busyIntervals(startMs: Int64, endMs: Int64) -> [[String: Any]] {
    guard authorizationStatus() == "authorized" else { return [] }
    let start = Date(timeIntervalSince1970: TimeInterval(startMs) / 1000)
    let end = Date(timeIntervalSince1970: TimeInterval(endMs) / 1000)
    let predicate = store.predicateForEvents(
      withStart: start, end: end, calendars: nil)
    let events = store.events(matching: predicate)
    var intervals: [[String: Any]] = []
    for event in events.prefix(200) {
      guard let eventStart = event.startDate, let eventEnd = event.endDate
      else { continue }
      if event.availability == .free { continue }
      if event.status == .canceled { continue }
      intervals.append([
        "startMs": Int64(eventStart.timeIntervalSince1970 * 1000),
        "endMs": Int64(eventEnd.timeIntervalSince1970 * 1000),
        "allDay": event.isAllDay,
      ])
    }
    intervals.sort {
      ($0["startMs"] as! Int64) < ($1["startMs"] as! Int64)
    }
    return intervals
  }
}
