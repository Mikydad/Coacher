import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ensure iOS notification tap callbacks are routed through AppDelegate.
    UNUserNotificationCenter.current().delegate = self
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
