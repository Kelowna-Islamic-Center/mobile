import "package:flutter_local_notifications/flutter_local_notifications.dart";

class Config {
  // Prayer API link from cloud function
  static String apiLink = "yourapilink";
  static String apiLinkForNextDay = "yourapilink?day=tomorrow";

  // Cloud messaging topics and firestore collections for announcements
  static String announcementTopic = "announcements";
  static String announcementCollection = "announcements";
  static String localeTopicPrefix = "lang-";

  // Android notification channels (don't change unless you know what you are doing)
  static const AndroidNotificationChannel announcementsChannel = AndroidNotificationChannel(
    "announcements_channel",
    "New Announcement Notifications",
    description: "Receive a notification whenever there is a new Masjid announcement.",
    importance: Importance.high,
  );
  
  static const AndroidNotificationChannel iqamahAlertChannel = AndroidNotificationChannel(
    "iqamah_alert_channel",
    "Iqamah Alerts",
    description: "Receive notification reminders a set amount of minutes before Iqamah happens at the Masjid.",
    importance: Importance.high,
  );

  static const AndroidNotificationChannel athanAlertChannel = AndroidNotificationChannel(
    "athan_alert_channel",
    "Athan Alerts",
    description: "Receive an alert when it is prayer time in Kelowna. Sound can be configured in settings.",
    importance: Importance.high,
    playSound: true
  );
}