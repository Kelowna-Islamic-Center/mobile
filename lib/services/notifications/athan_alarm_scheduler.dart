
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kelowna_islamic_center/structs/prayer_item.dart';


class AthanAlarmScheduler {

  static const int _notificationId = 50;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const NotificationDetails _platformChannelSpecifics =
      NotificationDetails(
    android: AndroidNotificationDetails(
        "iqamah_alert_service", "Iqamah Reminders",
        channelDescription:
            "Receive a reminder a set amount of minutes before Iqamah to go to the Masjid.",
        importance: Importance.max,
        priority: Priority.max),
  );



  // Check which prayer to schedule it for
  static Future<void> scheduleAlarm(tz.TZDateTime dateTime, PrayerItem prayer, int minutesUntil) async {
      // Prevent Duplicate notifications
      // final List<PendingNotificationRequest> pendingNotificationRequests =
      //     await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      // for (var map in pendingNotificationRequests) {
      //   if (map.id == _notificationId) return;
      // }

      // // If no duplicates, schedule next notification
      // await _flutterLocalNotificationsPlugin.zonedSchedule(
      //     _notificationId, // Iqamah Alert notifications id
      //     '$minutesUntil minutes left before ${prayer.name} Iqamah at the Masjid',
      //     '${prayer.name} Iqamah is at ${prayer.iqamahTime} today. Only $minutesUntil minutes remaining.',
      //     dateTime,
      //     _platformChannelSpecifics,
      //     androidScheduleMode: AndroidScheduleMode.exact,
      //     uiLocalNotificationDateInterpretation:
      //         UILocalNotificationDateInterpretation.absoluteTime);
  }
}
