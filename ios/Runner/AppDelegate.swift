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

    // Device model + OS version for feedback reports. In-house instead of
    // device_info_plus: its 13.2.0 iOS code fails to compile against this
    // SDK (unknown NSProcessInfo selector 'isiOSAppOnVision').
    // Stake reveal viewer (accountability PRD P-6). iOS cannot BLOCK
    // screenshots; it can only detect them. While the reveal route has
    // secure mode enabled, a screenshot fires "screenshotTaken" back to
    // Dart (which self-reports the strike), and screen recording flips
    // "captureChanged" so Dart hides the photo behind a blur.
    let secureRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathPalSecureScreen")
    let secureChannel = FlutterMethodChannel(
      name: "pathpal/secure_screen",
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

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathPalDeviceInfo")
    let channel = FlutterMethodChannel(
      name: "pathpal/device_info",
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
