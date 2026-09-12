import Foundation

// Siri entry (humanizing Phase 4, PRD §6): "Hey Siri, talk to SidePal".
//
// The AppIntent is compiled DIRECTLY into the Runner target — no extension
// target, no App Groups, no new signing surface (judge-verified platform
// correction). On iOS 15 and below the shortcut simply does not exist
// (@available guards); the bridge enum is plain Foundation and safe
// everywhere.
//
// Cold-start protocol (mirrors the notification pending-intent template):
//  1. perform() stamps a pending flag in UserDefaults (survives the window
//     where the Flutter engine isn't up yet) and posts a NotificationCenter
//     event (instant path when the app is already warm).
//  2. AppDelegate forwards the event over the "sidepal/siri_voice_entry"
//     method channel; Dart consumes the flag idempotently on launch,
//     on resume, and on the event — whoever reads it first clears it.

enum SiriVoiceEntryBridge {
  static let pendingKey = "sidepal.pendingVoiceEntry"
  static let notificationName = Notification.Name("SidePalVoiceEntryRequested")

  static func requestVoiceEntry() {
    UserDefaults.standard.set(true, forKey: pendingKey)
    NotificationCenter.default.post(name: notificationName, object: nil)
  }

  /// Reads AND clears the pending flag — idempotent consume.
  static func consumePending() -> Bool {
    let pending = UserDefaults.standard.bool(forKey: pendingKey)
    if pending {
      UserDefaults.standard.removeObject(forKey: pendingKey)
    }
    return pending
  }
}

#if canImport(AppIntents)
import AppIntents

@available(iOS 16.0, *)
struct TalkToSidePalIntent: AppIntent {
  static var title: LocalizedStringResource = "Talk to SidePal"
  static var description = IntentDescription(
    "Start a voice conversation with your SidePal coach.")

  /// Siri foregrounds the app; perform() then runs in-process.
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    SiriVoiceEntryBridge.requestVoiceEntry()
    return .result()
  }
}

// Zero-setup phrases ("Hey Siri, talk to SidePal") + Action Button support
// come free from the App Shortcut — no user configuration required.
@available(iOS 16.0, *)
struct SidePalAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: TalkToSidePalIntent(),
      phrases: [
        "Talk to \(.applicationName)",
        "Start a conversation with \(.applicationName)",
        "\(.applicationName) voice mode",
        // "Open <app>" itself is OS-owned (plain launch, cannot be
        // intercepted) — these are the closest claimable variants.
        "Open \(.applicationName) voice",
        "Open \(.applicationName) voice mode",
      ],
      shortTitle: "Talk to SidePal",
      systemImageName: "waveform"
    )
    // Time Tracker (V1.1): "Hey Siri, log activity in SidePal" → Siri asks
    // "What are you doing?" (the String parameter's requestValueDialog).
    // Phrases may only embed AppEntity/AppEnum parameters, never a free
    // String, so the activity cannot be spoken inline in the phrase.
    AppShortcut(
      intent: LogActivityIntent(),
      phrases: [
        "Log activity in \(.applicationName)",
        "Track activity in \(.applicationName)",
        "Log what I'm doing in \(.applicationName)",
        "Track my time in \(.applicationName)",
      ],
      shortTitle: "Log activity",
      systemImageName: "clock"
    )
  }
}
#endif

// ─── Siri "Log activity" (Time Tracker V1.1, 2026-09-12) ─────────────────────
//
// "Hey Siri, log Gym in SidePal" → the app opens and Dart creates the
// activity event. Same cold-start protocol as the voice entry above: the
// intent stamps a pending payload (UserDefaults JSON) + posts an in-process
// event; Dart consumes it idempotently on launch, resume, and the warm
// event. Lives in this file on purpose — no new Xcode file references.

enum SiriLogActivityBridge {
  static let pendingKey = "sidepal.pendingLogActivity"
  static let notificationName = Notification.Name("SidePalLogActivityRequested")

  static func stamp(activity: String, minutes: Int?) {
    var payload: [String: Any] = ["text": activity]
    if let m = minutes { payload["minutes"] = m }
    UserDefaults.standard.set(payload, forKey: pendingKey)
    NotificationCenter.default.post(name: notificationName, object: payload)
  }

  /// Reads AND clears the pending payload — idempotent consume.
  static func consumePending() -> [String: Any]? {
    let pending = UserDefaults.standard.dictionary(forKey: pendingKey)
    if pending != nil {
      UserDefaults.standard.removeObject(forKey: pendingKey)
    }
    return pending
  }
}

#if canImport(AppIntents)
@available(iOS 16.0, *)
struct LogActivityIntent: AppIntent {
  static var title: LocalizedStringResource = "Log activity"
  static var description = IntentDescription(
    "Record what you're doing right now in your SidePal timeline.")

  /// Siri foregrounds the app; Dart writes the event (Isar is local).
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Activity", requestValueDialog: "What are you doing?")
  var activity: String

  @Parameter(title: "Minutes")
  var minutes: Int?

  static var parameterSummary: some ParameterSummary {
    Summary("Log \(\.$activity)") {
      \.$minutes
    }
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let trimmed = activity.trimmingCharacters(in: .whitespacesAndNewlines)
    SiriLogActivityBridge.stamp(activity: trimmed, minutes: minutes)
    return .result()
  }
}
#endif
