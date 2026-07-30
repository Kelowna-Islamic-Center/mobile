import UIKit
import Flutter
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Register a periodic task with 15 minutes frequency. The frequency is in seconds.
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "org.kelownaislamiccenter.workmanager.iOSBackgroundAppRefresh", frequency: NSNumber(value: 15 * 60))
      
    GeneratedPluginRegistrant.register(with: self)
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
