import Flutter
import UIKit
import UserNotifications

/// sidepal:// custom-scheme links (2026-08-26; first use: circle invite
/// keys, sidepal://join/XXXX-XXXX). Same shape as SiriVoiceEntryBridge:
/// cold-start links wait as a pending value Dart consumes idempotently on
/// launch/resume; warm links post an in-process event forwarded over the
/// method channel. Lives in this file so no pbxproj surgery is needed.
final class DeepLinkBridge {
  static let notificationName = Notification.Name("SidePalDeepLink")
  private static var pending: String?

  static func handle(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "sidepal" else { return false }
    pending = url.absoluteString
    NotificationCenter.default.post(
      name: notificationName, object: url.absoluteString)
    return true
  }

  static func consumePending() -> String? {
    let value = pending
    pending = nil
    return value
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if DeepLinkBridge.handle(url) { return true }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      _ = DeepLinkBridge.handle(url)
    }
    // Ensure iOS notification tap callbacks are routed through AppDelegate.
    UNUserNotificationCenter.current().delegate = self
    // Home-exit geofence (humanizing Phase 6b): recreate the location
    // manager + delegate at every launch — iOS relaunches a force-quit app
    // into the background on a region crossing, and only a live delegate
    // receives the event.
    GeofenceSignalBridge.shared.activateAtLaunch()
    NSLog("[NotifTap][iOS] didFinishLaunching launchOptions=%@", String(describing: launchOptions))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let action = response.actionIdentifier
    NSLog("[NotifTap][iOS] didReceive response action=%@ userInfo=%@", action, String(describing: userInfo))
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Siri voice entry (humanizing Phase 4): "Hey Siri, talk to SidePal".
    // The AppIntent stamps a UserDefaults flag + posts a NotificationCenter
    // event (SiriVoiceEntry.swift); Dart consumes the flag idempotently on
    // launch/resume, and this observer covers the warm in-app case.
    let siriRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalSiriVoiceEntry")
    let siriChannel = FlutterMethodChannel(
      name: "sidepal/siri_voice_entry",
      binaryMessenger: siriRegistrar!.messenger())
    siriChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePendingVoiceEntry":
        result(SiriVoiceEntryBridge.consumePending())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: SiriVoiceEntryBridge.notificationName,
      object: nil, queue: .main
    ) { _ in
      siriChannel.invokeMethod("voiceEntryRequested", arguments: nil)
    }

    // sidepal:// deep links (2026-08-26) — pending flag + warm event, the
    // Siri-bridge pattern.
    let deepLinkRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalDeepLinks")
    let deepLinkChannel = FlutterMethodChannel(
      name: "sidepal/deep_links",
      binaryMessenger: deepLinkRegistrar!.messenger())
    deepLinkChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePendingLink":
        result(DeepLinkBridge.consumePending())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: DeepLinkBridge.notificationName,
      object: nil, queue: .main
    ) { note in
      deepLinkChannel.invokeMethod("linkReceived", arguments: note.object as? String)
    }

    // Ephemeral calendar signal (humanizing Phase 4b): busy intervals only,
    // never titles — see CalendarSignal.swift for the privacy contract.
    let calendarRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalCalendarSignal")
    let calendarChannel = FlutterMethodChannel(
      name: "sidepal/calendar_signal",
      binaryMessenger: calendarRegistrar!.messenger())
    calendarChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getAuthorizationStatus":
        result(CalendarSignalBridge.authorizationStatus())
      case "requestAccess":
        CalendarSignalBridge.requestAccess { granted in
          result(granted)
        }
      case "getBusyIntervals":
        guard let args = call.arguments as? [String: Any],
              let startMs = (args["startMs"] as? NSNumber)?.int64Value,
              let endMs = (args["endMs"] as? NSNumber)?.int64Value
        else {
          result(FlutterError(
            code: "bad_args", message: "startMs/endMs required", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let intervals = CalendarSignalBridge.busyIntervals(
            startMs: startMs, endMs: endMs)
          DispatchQueue.main.async { result(intervals) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Activity-recognition snapshot (humanizing Phase 6a): coarse kind
    // only, decision-time reads, no background stream — see
    // ActivitySignal.swift for the privacy contract.
    let activityRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalActivitySignal")
    let activityChannel = FlutterMethodChannel(
      name: "sidepal/activity_signal",
      binaryMessenger: activityRegistrar!.messenger())
    activityChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getAuthorizationStatus":
        result(ActivitySignalBridge.authorizationStatus())
      case "requestAccess":
        ActivitySignalBridge.requestAccess { granted in
          result(granted)
        }
      case "getCurrentActivity":
        let args = call.arguments as? [String: Any]
        let lookbackMs = (args?["lookbackMs"] as? NSNumber)?.int64Value ?? 600_000
        ActivitySignalBridge.currentActivity(lookbackMs: lookbackMs) { reading in
          result(reading)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Home-exit geofence (humanizing Phase 6b): one region, explicit home,
    // native-fired notifications — see GeofenceSignal.swift.
    let geofenceRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalGeofenceSignal")
    let geofenceChannel = FlutterMethodChannel(
      name: "sidepal/geofence_signal",
      binaryMessenger: geofenceRegistrar!.messenger())
    geofenceChannel.setMethodCallHandler { call, result in
      let bridge = GeofenceSignalBridge.shared
      switch call.method {
      case "getAuthorizationStatus":
        result(bridge.authorizationStatus())
      case "requestAccess":
        bridge.requestAccess { status in
          result(status)
        }
      case "getCurrentLocation":
        bridge.currentLocation { location in
          result(location)
        }
      case "setHome":
        guard let args = call.arguments as? [String: Any],
              let latitude = (args["latitude"] as? NSNumber)?.doubleValue,
              let longitude = (args["longitude"] as? NSNumber)?.doubleValue
        else {
          result(FlutterError(
            code: "bad_args", message: "latitude/longitude required",
            details: nil))
          return
        }
        bridge.setHome(latitude: latitude, longitude: longitude)
        result(true)
      case "clearHome":
        bridge.clearHome()
        result(true)
      case "hasHome":
        result(bridge.hasHome())
      case "setArmedIntents":
        let intents =
          (call.arguments as? [String: Any])?["intents"] as? [[String: Any]]
        bridge.setArmedIntents(intents ?? [])
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Device model + OS version for feedback reports. In-house instead of
    // device_info_plus: its 13.2.0 iOS code fails to compile against this
    // SDK (unknown NSProcessInfo selector 'isiOSAppOnVision').
    // Stake reveal viewer (accountability PRD P-6). iOS cannot BLOCK
    // screenshots; it can only detect them. While the reveal route has
    // secure mode enabled, a screenshot fires "screenshotTaken" back to
    // Dart (which self-reports the strike), and screen recording flips
    // "captureChanged" so Dart hides the photo behind a blur.
    let secureRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalSecureScreen")
    let secureChannel = FlutterMethodChannel(
      name: "sidepal/secure_screen",
      binaryMessenger: secureRegistrar!.messenger())
    var secureObservers: [NSObjectProtocol] = []
    secureChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "enableSecure":
        if secureObservers.isEmpty {
          secureObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil, queue: .main
          ) { _ in
            secureChannel.invokeMethod("screenshotTaken", arguments: nil)
          })
          secureObservers.append(NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil, queue: .main
          ) { _ in
            secureChannel.invokeMethod(
              "captureChanged", arguments: UIScreen.main.isCaptured)
          })
        }
        result(UIScreen.main.isCaptured)
      case "disableSecure":
        for observer in secureObservers {
          NotificationCenter.default.removeObserver(observer)
        }
        secureObservers.removeAll()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SidePalDeviceInfo")
    let channel = FlutterMethodChannel(
      name: "sidepal/device_info",
      binaryMessenger: registrar!.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "getDeviceInfo" else {
        result(FlutterMethodNotImplemented)
        return
      }
      var systemInfo = utsname()
      uname(&systemInfo)
      let machine = withUnsafeBytes(of: &systemInfo.machine) { raw -> String in
        let data = Data(raw.prefix(while: { $0 != 0 }))
        return String(data: data, encoding: .utf8) ?? "unknown"
      }
      result([
        "model": machine,
        "osVersion": UIDevice.current.systemVersion,
      ])
    }
  }
}
