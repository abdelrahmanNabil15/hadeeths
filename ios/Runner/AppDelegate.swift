import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // The installed version (`name+build`), for the rating prompt's once-per-version rule.
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "hadeeths/app_info", binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { call, result in
          guard call.method == "version" else {
            result(FlutterMethodNotImplemented)
            return
          }
          let info = Bundle.main.infoDictionary
          let name = info?["CFBundleShortVersionString"] as? String
          let build = info?["CFBundleVersion"] as? String
          if let name = name, let build = build {
            result("\(name)+\(build)")
          } else {
            result(nil)
          }
        }
    }
    // Lets prayer reminders show while the app is open (flutter_local_notifications).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
