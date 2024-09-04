import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_android/shared_preferences_android.dart";
import "package:shared_preferences_ios/shared_preferences_ios.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
AndroidNotificationChannel? channel;

class AnnouncementsMessageService {
  
  // Announcements cloud message backgroundHandler
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    
    // Init SharedPreferences
    if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
    if (Platform.isIOS) SharedPreferencesIOS.registerWith();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    QuerySnapshot<Map<String, dynamic>> fsSnapshot = await FirebaseFirestore.instance.collection(Config.announcementCollection).get();
    // Update cached announcements data to data from Firestore
    await prefs.setStringList(Config.announcementCollection, Announcement.toJsonStringFromList(Announcement.listFromJSON(fsSnapshot.docs)));
  }

  // Announcements cloud message foregroundHandler
  static void foregroundMessageHandler(RemoteMessage message) async {
    if (Platform.isAndroid) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null && android != null) {
        await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(channel!.id, channel!.name,
                  channelDescription: channel!.description,
                  icon: android.smallIcon,
                  importance: Importance.high),
            ));
      }
    }

    await backgroundMessageHandler(message);
  }


  static Future<void> init() async {
    
    // Create a high priority channel for Android
    if (Platform.isAndroid) {
      channel = const AndroidNotificationChannel(
        "announcements_channel", // id
        "New Announcement Notifications", // title
        description: "Receive a notification whenever there is a new Masjid announcement.",
        importance: Importance.high,
      );
      
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings("@mipmap/ic_launcher");
      await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel!);
    }

    await Firebase.initializeApp();
    // Setup Background and Foreground workers
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(foregroundMessageHandler);

    // Request iOS Permissions
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(sound: true, badge: true, alert: true);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: false);
    }

    // Subscribe to announcements if the user has never set any settings (first time launch)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("announcementAlert") == null) await FirebaseMessaging.instance.subscribeToTopic(Config.announcementTopic);
  }

  static void toggleSubscription(bool enable) {
    enable ? FirebaseMessaging.instance.subscribeToTopic(Config.announcementTopic) : FirebaseMessaging.instance.unsubscribeFromTopic(Config.announcementTopic);
  }
}
