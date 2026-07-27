import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_android/shared_preferences_android.dart";
import "package:shared_preferences_foundation/shared_preferences_foundation.dart";

import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/structs/announcement.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class CloudMessagingService {

  static Future<void> init() async {

    await Firebase.initializeApp();
    // Setup Background and Foreground workers
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(foregroundMessageHandler);

    // Set Android Notification Settings
    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings("@mipmap/ic_launcher");
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        ),
      );

      await _createAndroidNotificationChannel(Config.announcementsChannel);
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
      if (Platform.isIOS) SharedPreferencesFoundation.registerWith();
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

        Map<String, AndroidNotificationChannel> channels = {
          Config.iqamahAlertChannel.id: Config.iqamahAlertChannel,
          Config.athanAlertChannel.id: Config.athanAlertChannel,
          Config.announcementsChannel.id: Config.announcementsChannel,
        };

        AndroidNotificationChannel? channel = channels[android.channelId];

        if (channel != null) {
          await flutterLocalNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
                importance: Importance.high,
              ),
            ),
          );
        }
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
