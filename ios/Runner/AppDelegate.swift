import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Tells Dart to play the full adhan in the app (see `FullAdhanCoordinator` and
  /// `docs/ADHAN_SOUNDS.md`).
  private var fullAdhanChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      // The installed version (`name+build`), for the rating prompt's once-per-version rule.
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
      AdhanNotificationSounds.register(with: controller.binaryMessenger)
      fullAdhanChannel = FlutterMethodChannel(
        name: "hadeeths/full_adhan", binaryMessenger: controller.binaryMessenger)
    }
    // Lets prayer reminders show while the app is open, and the app suppress or hand off a
    // reminder's sound (see userNotificationCenter below).
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// A reminder is about to show while the app is open. A "Full adhan" one (see
  /// `PrayerNotificationInfo`) hands off to the app instead of playing its own short clip, so the
  /// two never overlap; everything else keeps whatever sound/alert it was scheduled with.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let content = notification.request.content
    let info = PrayerNotificationInfo(userInfo: content.userInfo)
    var options: UNNotificationPresentationOptions = [.banner, .list]
    if info?.fullAdhan == true, let adhanId = info?.adhanId {
      fullAdhanChannel?.invokeMethod("playFullAdhan", arguments: ["adhanId": adhanId])
    } else if content.sound != nil {
      options.insert(.sound)
    }
    completionHandler(options)
  }

  /// The user tapped a reminder. A "Full adhan" one asks the app to play the full recording; by
  /// now its own short clip (if the app was not in the foreground to suppress it) has already
  /// played as the notification was delivered, so there is nothing to avoid overlapping with.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let info = PrayerNotificationInfo(userInfo: response.notification.request.content.userInfo)
    if info?.fullAdhan == true, let adhanId = info?.adhanId {
      fullAdhanChannel?.invokeMethod("playFullAdhan", arguments: ["adhanId": adhanId])
    }
    completionHandler()
  }
}

/// What a prayer-time reminder's notification says about playing the full adhan in the app, read
/// from `userInfo["payload"]` — `flutter_local_notifications` stores the Dart `NotificationContent`
/// payload string there verbatim, and `NotificationPayload.encode` (`notification_sync.dart`)
/// includes `adhan`/`full` only for a reminder carrying a chosen adhan.
private struct PrayerNotificationInfo {
  let adhanId: String?
  let fullAdhan: Bool

  init?(userInfo: [AnyHashable: Any]) {
    guard
      let text = userInfo["payload"] as? String,
      let data = text.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      json["k"] as? String == "prayer"
    else {
      return nil
    }
    adhanId = json["adhan"] as? String
    fullAdhan = json["full"] as? Bool ?? false
  }
}
