import Flutter
import Foundation

// AlarmKit (iOS 26+) — real system alarms for SidePal's alarm reminders
// (feat/alarm-mode, settled with Miko 2026-10-04).
//
// A notification ring is muted by the silent switch and asks for Face ID
// before Stop works on a locked phone. An AlarmKit alarm is the Clock app's
// alarm: full screen on the lock screen, rings through silent mode and
// Focus until the user acts, and Stop / Snooze work without unlocking.
//
// Shape (Dart side: lib/features/reminders/application/alarm_kit_channel.dart):
//  * Compiled DIRECTLY into the Runner target, like SiriVoiceEntry.swift —
//    no widget extension, no App Group, no new signing surface. That is why
//    Snooze is a `.custom` secondary button running an App Intent that
//    re-schedules the same alarm id, instead of AlarmKit's countdown snooze
//    (a countdown needs a Live Activity widget extension).
//  * Stop is AlarmKit's own system Stop — nothing for the app to do.
//  * The Snooze intent runs in the app process without opening the app; it
//    leaves an event in UserDefaults that Dart drains on its next re-arm and
//    stamps onto the occurrence.
//  * On iOS 15–25 the channel answers "unavailable" and Dart keeps the
//    notification rings.

/// Native-side events Dart has not seen yet (today: Snooze). Plain
/// Foundation, safe on every iOS version.
enum AlarmKitEventStore {
  static let key = "sidepal.alarmKitEvents"

  static func append(_ event: [String: Any]) {
    var events = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
    events.append(event)
    // Bounded: a phone that keeps snoozing without opening the app must not
    // grow this forever. Only the latest snooze per task matters anyway.
    if events.count > 50 { events.removeFirst(events.count - 50) }
    UserDefaults.standard.set(events, forKey: key)
  }

  /// Reads AND clears — idempotent consume.
  static func drain() -> [[String: Any]] {
    let events = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
    UserDefaults.standard.removeObject(forKey: key)
    return events
  }
}

/// The "sidepal/alarm_kit" method channel. Registered from AppDelegate.
enum AlarmKitChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "sidepal/alarm_kit", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          AlarmKitScheduler.handle(call, result: result)
          return
        }
      #endif
      switch call.method {
      case "getAuthorizationStatus", "requestAccess":
        result("unavailable")
      case "schedule":
        result(false)
      case "cancel":
        result(nil)
      case "scheduledIds":
        result([String]())
      case "drainEvents":
        result(AlarmKitEventStore.drain())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

#if canImport(AlarmKit)
  import ActivityKit
  import AlarmKit
  import AppIntents
  import SwiftUI

  @available(iOS 26.0, *)
  struct SidePalAlarmMetadata: AlarmMetadata {
    var taskId: String
  }

  @available(iOS 26.0, *)
  enum AlarmKitScheduler {
    /// SidePal olive (AppColors.accent, light palette). Native chrome
    /// cannot read the Flutter palette, so the one brand tint lives here.
    static let tint = Color(red: 0x54 / 255.0, green: 0x7D / 255.0, blue: 0x0B / 255.0)

    /// The bundled alarm chime (ios/Runner/sidepal_alarm.caf) — the same
    /// sound the notification rings use.
    static let soundName = "sidepal_alarm.caf"

    static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "getAuthorizationStatus":
        result(name(AlarmManager.shared.authorizationState))
      case "requestAccess":
        Task {
          let state =
            (try? await AlarmManager.shared.requestAuthorization())
            ?? AlarmManager.shared.authorizationState
          await MainActor.run { result(name(state)) }
        }
      case "schedule":
        guard let idString = args?["id"] as? String,
          let id = UUID(uuidString: idString),
          let taskId = args?["taskId"] as? String,
          let title = args?["title"] as? String,
          let fireAtMs = (args?["fireAtMs"] as? NSNumber)?.int64Value
        else {
          result(FlutterError(
            code: "bad_args", message: "id/taskId/title/fireAtMs required",
            details: nil))
          return
        }
        let snoozeMinutes = (args?["snoozeMinutes"] as? NSNumber)?.intValue ?? 5
        let fireAt = Date(timeIntervalSince1970: TimeInterval(fireAtMs) / 1000)
        Task {
          var ok = true
          do {
            try await schedule(
              id: id, taskId: taskId, title: title, fireAt: fireAt,
              snoozeMinutes: snoozeMinutes)
          } catch {
            NSLog("[AlarmKit] schedule failed: %@", String(describing: error))
            ok = false
          }
          let scheduled = ok
          await MainActor.run { result(scheduled) }
        }
      case "cancel":
        if let idString = args?["id"] as? String,
          let id = UUID(uuidString: idString)
        {
          try? AlarmManager.shared.cancel(id: id)
        }
        result(nil)
      case "scheduledIds":
        let alarms = (try? AlarmManager.shared.alarms) ?? []
        result(alarms.map { $0.id.uuidString })
      case "drainEvents":
        result(AlarmKitEventStore.drain())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    static func name(_ state: AlarmManager.AuthorizationState) -> String {
      switch state {
      case .authorized: return "authorized"
      case .denied: return "denied"
      case .notDetermined: return "notDetermined"
      @unknown default: return "notDetermined"
      }
    }

    /// Schedules (or replaces) one alarm. The id is the task's, so a re-arm
    /// replaces in place and the Snooze intent re-uses it.
    static func schedule(
      id: UUID, taskId: String, title: String, fireAt: Date, snoozeMinutes: Int
    ) async throws {
      try? AlarmManager.shared.cancel(id: id)
      let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: title),
        stopButton: AlarmButton(
          text: "Stop", textColor: .white, systemImageName: "stop.circle"),
        secondaryButton: AlarmButton(
          text: "Snooze", textColor: .white, systemImageName: "zzz"),
        secondaryButtonBehavior: .custom)
      let attributes = AlarmAttributes<SidePalAlarmMetadata>(
        presentation: AlarmPresentation(alert: alert),
        metadata: SidePalAlarmMetadata(taskId: taskId),
        tintColor: tint)
      let snooze = SnoozeSidePalAlarmIntent(
        alarmID: id.uuidString, taskId: taskId, alarmTitle: title,
        snoozeMinutes: snoozeMinutes)
      let configuration = AlarmManager.AlarmConfiguration<SidePalAlarmMetadata>.alarm(
        schedule: .fixed(fireAt),
        attributes: attributes,
        secondaryIntent: snooze,
        sound: .named(soundName))
      _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }
  }

  /// The alarm's Snooze button: stop the ring, schedule the same alarm
  /// [snoozeMinutes] from now, and tell Dart. Runs in the app process
  /// without bringing the app forward.
  @available(iOS 26.0, *)
  struct SnoozeSidePalAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze alarm"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm") var alarmID: String
    @Parameter(title: "Task") var taskId: String
    @Parameter(title: "Title") var alarmTitle: String
    @Parameter(title: "Minutes") var snoozeMinutes: Int

    init() {}

    init(alarmID: String, taskId: String, alarmTitle: String, snoozeMinutes: Int) {
      self.alarmID = alarmID
      self.taskId = taskId
      self.alarmTitle = alarmTitle
      self.snoozeMinutes = snoozeMinutes
    }

    func perform() async throws -> some IntentResult {
      guard let id = UUID(uuidString: alarmID) else { return .result() }
      try? AlarmManager.shared.stop(id: id)
      let until = Date().addingTimeInterval(TimeInterval(max(1, snoozeMinutes) * 60))
      try await AlarmKitScheduler.schedule(
        id: id, taskId: taskId, title: alarmTitle, fireAt: until,
        snoozeMinutes: snoozeMinutes)
      AlarmKitEventStore.append([
        "kind": "snooze",
        "taskId": taskId,
        "untilMs": Int64(until.timeIntervalSince1970 * 1000),
      ])
      return .result()
    }
  }
#endif
