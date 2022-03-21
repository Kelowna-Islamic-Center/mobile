import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kelowna_islamic_center/structs/announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
AndroidNotificationChannel? channel;

class AnnouncementsMessageService {
  
  // Announcements cloud message backgroundHandler
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({}); // No idea why this is needed but it breaks without it
    
    final prefs = await SharedPreferences.getInstance();
    final fsSnapshot = await FirebaseFirestore.instance.collection('announcements').get();
    // Update cached announcements data
    await prefs.setStringList("announcements", Announcement.toJsonStringFromList(Announcement.listFromJSON(fsSnapshot.docs)));
  }

  // Announcements cloud message foregroundHandler
  static void foregroundMessageHandler(RemoteMessage message) async {
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
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

    await backgroundMessageHandler(message);
  }


  static Future<void> init() async {

    // Create a high priority channel for Android
    channel = const AndroidNotificationChannel(
      'announcements_channel', // id
      'New Announcement Notifications', // title
      description: 'Receive a notification whenever there is a new Masjid announcement.',
      importance: Importance.high,
    );
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel!);

    await Firebase.initializeApp();
    // Setup Background and Foreground workers
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(foregroundMessageHandler);

    // iOS Permissions
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(sound: true, badge: true, alert: true);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: false);
    }

    // Subscribe to announcements if the user has never set any settings (first time launch)
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("announcementAlert") == null) FirebaseMessaging.instance.subscribeToTopic("announcements");
  }

  static void toggleSubscription(bool enable) {
    enable ? FirebaseMessaging.instance.subscribeToTopic("announcements") : FirebaseMessaging.instance.unsubscribeFromTopic("announcements");
  }
}
