import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:kelowna_islamic_center/services/notifications/athan_alarm_scheduler.dart';
import 'package:kelowna_islamic_center/services/notifications/iqamah_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:kelowna_islamic_center/structs/prayer_item.dart';

class PrayerNotificationService {

  static const String taskUniqueName = "prayerNotificationsServiceTask";

  // Initialize the background service used for scheduling prayer notifications and alarms
  static Future<void> initBackgroundService() async {
    // Periodic Task that keeps checking for next Prayer to schedule a notification for
    await Workmanager().registerPeriodicTask(
        "1",
        taskUniqueName,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        initialDelay: const Duration(seconds: 30) // Required otherwise fails on first time setup due to empty sharedPreferences
    );
  }


  // This method is called when Workmanager runs the periodic task
  // This method schedules the notifications for athan and iqamah.
  static Future<void> scheduleNextNotifications() async {
    final List<PrayerItem> prayerItems = await getLocallyStoredPrayerTimes();
    await scheduleNextIqamahNotification(prayerItems);
    await scheduleNextAthanAlarm(prayerItems);
  }


  // Schedule Iqamaah Notification for the next prayer
  static Future<void> scheduleNextIqamahNotification(List<PrayerItem> prayerItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // If user disabled iqamah alerts, then return
    bool? isEnabled = prefs.getBool('iqamahTimeAlert');
    if (isEnabled != null && !isEnabled) return;

    // Get minutes before iqamah to send alert
    int? minutesBefore = prefs.getInt('iqamahTimeAlertTime');
    minutesBefore ??= 15; // If is null then set to 15 mins (default)
    
    for (int i = 0; i < prayerItems.length; i++) {

      String iqamahTimeString = prayerItems[i].iqamahTime;

      // Skip Shurooq or if value of iqamahTimeString is "No Internet"
      if (i == 1 || iqamahTimeString == "No Internet") continue;
      
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime iqamahDateTime = stringTimeToDateTime(iqamahTimeString, minutesBefore);

      // Schedule a notification only if prayer time is in the future
      if (iqamahDateTime.isAfter(now)) {
        IqamahNotificationScheduler.scheduleNotification(iqamahDateTime, prayerItems[i], minutesBefore);
        break;
      }
    }
  }


  // Schedule Athan Alarm for the next prayer
  static Future<void> scheduleNextAthanAlarm(List<PrayerItem> prayerItems) async {
   SharedPreferences prefs = await SharedPreferences.getInstance();

    // If user disabled athan alerts, then return
    bool? isEnabled = prefs.getBool('athanTimeAlert');
    if (isEnabled != null && !isEnabled) return;

    for (int i = 0; i < prayerItems.length; i++) {
      String athanTimeString = prayerItems[i].startTime;

      // Skip Shurooq or if value of iqamahTimeString is "No Internet"
      if (i == 1 || athanTimeString == "No Internet") continue;

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime athanDateTime = stringTimeToDateTime(athanTimeString, 0);

      // Schedule a notification only if prayer time is in the future
      if (athanDateTime.isAfter(now)) {
        // AthanAlarmScheduler.scheduleAlarm(athanDateTime, prayerItems[i]);
        break;
      }
    }
  }


  // Checks if a prayer time has already passed
  static tz.TZDateTime stringTimeToDateTime(String prayerTimeString, int subtractMinutes) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    // Set Timezone for time calculation
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("America/Vancouver"));
    
    // Subtract the set minutes from prayer time to set as notification time
    DateTime parsedTime = DateFormat.jm().parse(prayerTimeString);
    tz.TZDateTime prayerDateTime = tz.TZDateTime(tz.local, now.year,
        now.month, now.day, parsedTime.hour, parsedTime.minute);
    prayerDateTime = prayerDateTime.subtract(Duration(minutes: subtractMinutes));
    
    return prayerDateTime;
  }


  // Get locally stored values of prayer times so api fetches aren't required in this service
  static Future<List<PrayerItem>> getLocallyStoredPrayerTimes() async {
    // Init SharedPreferences
    if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
    if (Platform.isIOS) SharedPreferencesIOS.registerWith();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get Prayer times to schedule notifications on
    List<dynamic>? rawJSON = prefs.getStringList('prayerTimes');
    List<dynamic> parsedList = [];
    for (int i = 0; i < rawJSON!.length; i++) {
      parsedList.add(jsonDecode(rawJSON[i]));
    }
    
    return PrayerItem.listFromFetchedJson(parsedList)!;
  }

}
