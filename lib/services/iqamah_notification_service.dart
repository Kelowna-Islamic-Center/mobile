import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:kelowna_islamic_center/structs/prayer_item.dart';

class IqamahNotificationService {

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const taskUniqueName = "iqamahAlertServiceTask";

  static const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
        "iqamah_alert_service", "Iqamah Reminders",
        channelDescription: "Receive a reminder a set amount of minutes before Iqamah to go to the Masjid.",
        importance: Importance.max,
        priority: Priority.max),
    iOS: IOSNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
    ),
  );

  static Future<void> initBackgroundService() async {
    // Periodic Task that keeps checking for next Iqamah to schedule notification for
    await Workmanager().registerPeriodicTask(
        "1",
        taskUniqueName,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        initialDelay: const Duration(seconds: 30) // Required otherwise fails on first time setup due to empty sharedPreferences
    );
  }

  static Future<void> scheduleNextNotification() async {
    // Init SharedPreferences
    if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
    if (Platform.isIOS) SharedPreferencesIOS.registerWith();
    final prefs = await SharedPreferences.getInstance();

    // If user disabled alerts, then return
    bool? isEnabled = prefs.getBool('iqamahTimeAlert');
    if (isEnabled != null && !isEnabled) return;

    List<dynamic>? rawJSON = prefs.getStringList('prayerTimes');
    List<dynamic> parsedList = [];
    for (int i = 0; i < rawJSON!.length; i++) {
      parsedList.add(jsonDecode(rawJSON[i]));
    }

    // Get minutes before iqamaah to send alert
    int? minutes = prefs.getInt('iqamahTimeAlertTime');
    minutes ??= 15; // If is null then set to 15 mins (default)

    List<PrayerItem> data = PrayerItem.listFromFetchedJson(parsedList)!;
    // Set Timezone for time calculation
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("America/Vancouver"));

    await scheduleNotification(data, minutes);
  }

  // Check which prayer to schedule it for
  static Future<void> scheduleNotification(List<PrayerItem> data, int minutes) async {
    for (int i = 0; i < data.length; i++) {
      String iqamahTime = data[i].iqamahTime;

      // Skip over Shurooq or any unset times due to no internet
      if (iqamahTime == "No Internet" || i==1) continue;

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      // Subtract the set minutes from iqamah time to set as notification time
      DateTime parsedTime = DateFormat.jm().parse(iqamahTime);
      tz.TZDateTime iqamahDateTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      iqamahDateTime = iqamahDateTime.subtract(Duration(minutes: minutes));

      if (now.isAfter(iqamahDateTime)) {
        continue;
      } else {
        // Prevent Duplicate notifications
        final List<PendingNotificationRequest> pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
        for (var map in pendingNotificationRequests) {
          if (map.id == 50) return;
        }

        // If no duplicates, schedule next notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
            50, // Iqamah Alert notifications id
            '$minutes minutes left before ${data[i].name} Iqamah at the Masjid',
            '${data[i].name} Iqamah is at ${data[i].iqamahTime} today. Only $minutes minutes remaining.',
            iqamahDateTime,
            platformChannelSpecifics,
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
        break;
      }
    }
  }
}
