import UIKit
import Flutter
import UserNotifications
import alarm
import workmanager

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
      SwiftAlarmPlugin.registerBackgroundTasks()

    // Register a periodic task with 30 minutes frequency. The frequency is in seconds.
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "org.kelownaislamiccenter.workmanager.iOSBackgroundAppRefresh", frequency: NSNumber(value: 30 * 60))
      
    GeneratedPluginRegistrant.register(with: self)
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
