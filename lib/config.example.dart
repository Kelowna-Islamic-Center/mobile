import "package:flutter_local_notifications/flutter_local_notifications.dart";

class Config {
  // Prayer API link from cloud function
  static String apiLink = "yourapilink";
  static String apiLinkForNextDay = "yourapilink?day=tomorrow";

  // Cloud messaging topics and firestore collections for announcements
  static String announcementTopic = "announcements";
  static String localeTopicPrefix = "lang-";
  static String announcementCollection = "announcements";


  /* Below this are pre-configured settings, don't change these from thier defaults unless absolutely required */

  // Default settings values
  static final Map<String, dynamic> defaultSettings = {
    // Default Values
    "calculationMethod": "hanafi",
    "launchDefaultIndex": 0,
    "iqamahTimeAlert": true,
    "iqamahTimeAlertTime": 15,
    "athanTimeAlert": true,
    "athanAudio": "athan_default",
    "announcementAlert": true,
  };

  // Ordered list of raw resource names selectable for Athan audio tracks.
  // Add matching files under android/app/src/main/res/raw/ and within the iOS projectas you expand this list.
  // Android files have these exact names in .ogg format.
  // iOS files have the same name but with _short.caf extension that gets appended to the string passed within the notification payload.
  static const List<String> androidAthanAudioOptions = <String>[
    // Android .ogg audio files do not have size or duration limits
    // iOS .caf audio files must be less than 30 seconds (hence why they are _short.caf)
    "athan_default",
    "athan_hafiz_mustafa",
    "athan_medina",
    "athan_makkah",
    "athan_mishary",
    "athan_alsharqawe",
    "athan_mansour"
  ];

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
  );
}