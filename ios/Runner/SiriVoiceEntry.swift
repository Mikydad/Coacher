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
      ],
      shortTitle: "Talk to SidePal",
      systemImageName: "waveform"
    )
  }
}
#endif
