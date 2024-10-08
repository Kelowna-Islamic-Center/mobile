import "dart:convert";
import "dart:io";
import "package:alarm/alarm.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:intl/intl.dart";

import "package:shared_preferences/shared_preferences.dart";
import "package:shared_preferences_android/shared_preferences_android.dart";
import "package:shared_preferences_ios/shared_preferences_ios.dart";
import "package:timezone/data/latest.dart" as tz;
import "package:timezone/timezone.dart" as tz;
import "package:workmanager/workmanager.dart";
import "package:kelowna_islamic_center/structs/prayer_item.dart";

class PrayerNotificationService {
  
  static const String taskUniqueName = "prayerNotificationsServiceTask";
  static const String iOSBackgroundAppRefreshName = "org.kelownaislamiccenter.workmanager.iOSBackgroundAppRefresh";
  static const String athanPath = "assets/audio/athan.mp3";
  
  static const int iqamahNotificationId = 50;
  static const int athanNotificationId = 30;

  static const NotificationDetails iqamahPlatformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
        "iqamah_alert_service", 
        "Iqamah Reminders",
        channelDescription:
            "Receive a reminder a set amount of minutes before Iqamah to go to the Masjid.",
        importance: Importance.max,
        priority: Priority.max),
  );


  // Initialize the background service used for scheduling prayer notifications and alarms
  static Future<void> initBackgroundService() async {
    // Periodic Task that keeps checking for next Prayer to schedule a notification for
    if (Platform.isIOS) {
      await Workmanager().registerPeriodicTask(
        iOSBackgroundAppRefreshName,
        iOSBackgroundAppRefreshName,
        initialDelay: const Duration(seconds: 30),
        frequency: const Duration(hours: 1), // Ignored on iOS, rather set in AppDelegate.swift
      );

      return;
    }
    
    await Workmanager().registerPeriodicTask(
        taskUniqueName, 
        taskUniqueName,
        existingWorkPolicy: ExistingWorkPolicy.keep,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(seconds: 30) // Required otherwise fails on first time setup due to empty sharedPreferences
        );
  }

  // This method is called when Workmanager runs the periodic task
  // This method schedules the notifications for athan and iqamah.
  static Future<void> scheduleNextNotifications() async {
    List<PrayerItem> prayerItems = await getLocallyStoredPrayerTimes();

    await scheduleNextIqamahNotification(prayerItems);
    await scheduleNextAthanAlarm(prayerItems);
  }

  // Schedule Iqamaah Notification for the next prayer
  static Future<void> scheduleNextIqamahNotification(
      List<PrayerItem> prayerItems) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // If user disabled iqamah alerts, then return
    bool? isEnabled = prefs.getBool("iqamahTimeAlert");
    if (isEnabled != null && !isEnabled) return;

    // Get minutes before iqamah to send alert
    int? minutesBefore = prefs.getInt("iqamahTimeAlertTime");
    minutesBefore ??= 15; // If is null then set to 15 mins (default)

    for (int i = 0; i < prayerItems.length; i++) {
      String iqamahTimeString = prayerItems[i].iqamahTime;

      // Skip Shurooq or if value of iqamahTimeString is "No Internet"
      if (prayerItems[i].id.toLowerCase() == "shurooq" || iqamahTimeString == "No Internet") continue;

      // Set Timezone for time calculation
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation("America/Vancouver"));

      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime iqamahDateTime =
          stringTimeToDateTime(iqamahTimeString, minutesBefore);

      // Schedule a notification only if prayer time is in the future
      if (iqamahDateTime.isAfter(now)) {

        PrayerItem prayer = prayerItems[i];

        // Prevent Duplicate notifications
        List<PendingNotificationRequest> pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
        for (var map in pendingNotificationRequests) {
          if (map.id == iqamahNotificationId) return;
        }

        // If no duplicates, schedule next notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
            iqamahNotificationId, // Iqamah Alert notifications id
            "$minutesBefore minutes left before ${prayer.name} Iqamah at the Masjid",
            "${prayer.name} Iqamah is at ${prayer.iqamahTime} today. Only $minutesBefore minutes remaining.",
            iqamahDateTime,
            iqamahPlatformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);

        return;
      }
    }
  }

  // Schedule Athan Alarm for the next prayer
  static Future<void> scheduleNextAthanAlarm(
      List<PrayerItem> prayerItems) async {
      
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Alarm.init();

    // If user disabled athan alerts, then return
    bool? isEnabled = prefs.getBool("athanTimeAlert");
    if (isEnabled != null && !isEnabled) return;

    for (int i = 0; i < prayerItems.length; i++) {
      String athanTimeString = prayerItems[i].startTime;

      // Skip Shurooq or if value of iqamahTimeString is "No Internet"
      if (prayerItems[i].id.toLowerCase() == "shurooq" || athanTimeString == "No Internet") continue;

      // Set Timezone for time calculation
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation("America/Vancouver"));

      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime athanDateTime =
          stringTimeToDateTime(athanTimeString, 0);

      // Schedule a notification only if prayer time is in the future
      if (athanDateTime.isAfter(now)) {
        await Alarm.set(alarmSettings: AlarmSettings(
          id: athanNotificationId,
          dateTime: athanDateTime,
          assetAudioPath: athanPath,
          loopAudio: false,
          vibrate: false,
          notificationTitle: "It is time for ${prayerItems[i].name} in Kelowna.",
          notificationBody: "Do not dismiss! To stop athan audio, you must tap this notification.",
          enableNotificationOnKill: false,
          notificationActionSettings: const NotificationActionSettings(hasStopButton: true, stopButtonText: "Stop Athan")
        ));

        break;
      }
    }
  }

  // Checks if a prayer time has already passed
  static tz.TZDateTime stringTimeToDateTime(String prayerTimeString, int subtractMinutes) {

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Set Timezone for time calculation
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("America/Vancouver"));

    // Subtract the set minutes from prayer time to set as notification time
    DateTime parsedTime = DateFormat("h:m a").parse(prayerTimeString);
    tz.TZDateTime prayerDateTime = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, parsedTime.hour, parsedTime.minute);
    prayerDateTime =
        prayerDateTime.subtract(Duration(minutes: subtractMinutes));

    return prayerDateTime;
  }

  // Get locally stored values of prayer times so api fetches aren't required in this service
  static Future<List<PrayerItem>> getLocallyStoredPrayerTimes() async {
      // Init SharedPreferences
      if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
      if (Platform.isIOS) SharedPreferencesIOS.registerWith();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get Prayer times to schedule notifications on
      List<dynamic>? rawJSON = prefs.getStringList("prayerTimes");
      rawJSON ??= [];
      List<dynamic> parsedList = [];

      for (int i = 0; i < rawJSON.length; i++) {
        parsedList.add(jsonDecode(rawJSON[i]));
      }

      return await PrayerItem.listFromFetchedJson(parsedList);
  }
}
