import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_android/shared_preferences_android.dart";
import "package:shared_preferences_ios/shared_preferences_ios.dart";

import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class CloudMessagingService {

  // Android notification Channels
  static AndroidNotificationChannel? announcementsChannel;
  static AndroidNotificationChannel? iqamahAlertChannel;
  static AndroidNotificationChannel? athanAlertChannel;


  static Future<void> init() async {

    await Firebase.initializeApp();
    // Setup Background and Foreground workers
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(foregroundMessageHandler);

    // Set Android Notification Settings
    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings("@mipmap/ic_launcher");
      await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));

      announcementsChannel = const AndroidNotificationChannel(
        "announcements_channel",
        "New Announcement Notifications",
        description: "Receive a notification whenever there is a new Masjid announcement.",
        importance: Importance.high,
      );
      
      iqamahAlertChannel = const AndroidNotificationChannel(
        "iqamah_alert_channel",
        "Iqamah Alerts",
        description: "Receive notification reminders a set amount of minutes before Iqamah happens at the Masjid.",
        importance: Importance.high,
      );

      athanAlertChannel = const AndroidNotificationChannel(
        "athan_alert_channel",
        "Athan Alerts",
        description: "Receive an alert when it is prayer time in Kelowna. Sound can be configured in settings.",
        importance: Importance.high,
        playSound: true
      );

      await _createAndroidNotificationChannel(announcementsChannel!);
      await _createAndroidNotificationChannel(iqamahAlertChannel!);
      await _createAndroidNotificationChannel(athanAlertChannel!);
    }

    // Request iOS Permissions
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(sound: true, badge: true, alert: true);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: false);
    }

    _initDefaultSubscriptions();
  }


  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    String? notificationType = message.data["notificationType"];

    // Update cached announcements data to data from Firestore when a new announcement is received
    if (notificationType == "announcements") {
      await Firebase.initializeApp();
      
      // Init SharedPreferences
      if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
      if (Platform.isIOS) SharedPreferencesIOS.registerWith();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      QuerySnapshot<Map<String, dynamic>> fsSnapshot = await FirebaseFirestore.instance.collection(Config.announcementCollection).get();
      
      await prefs.setStringList(Config.announcementCollection, Announcement.toJsonStringFromList(Announcement.listFromJSON(fsSnapshot.docs)));
    }
  }

  static void foregroundMessageHandler(RemoteMessage message) async {
    if (Platform.isAndroid) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null && android != null) {

        String? notificationType = message.data["notificationType"];
        AndroidNotificationChannel channel;

        switch (notificationType) {
          case "announcements":
            channel = announcementsChannel!;
            break;
          case "athan":
            channel = athanAlertChannel!;
            break;
          case "iqamah":
            channel = iqamahAlertChannel!;
            break;
          default: 
            return;
        }

        await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name,
                  channelDescription: channel.description,
                  icon: android.smallIcon,
                  importance: Importance.high),
            ));
      }
    }

    await backgroundMessageHandler(message);
  }

  static Future<void> subscribeToTopic(String topic) {
    return FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) {
    return FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  static Future<void>? _createAndroidNotificationChannel(AndroidNotificationChannel channel) {
    return flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  // Subscribtions if the user has never set any settings (first time launch)
  static void _initDefaultSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      if (prefs.getBool("announcementAlert") == null) {
        await subscribeToTopic(Config.announcementTopic);
      }
    } catch (_) {}
  }
}
