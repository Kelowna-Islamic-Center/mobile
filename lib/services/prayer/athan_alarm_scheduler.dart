
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kelowna_islamic_center/structs/prayer_item.dart';

class AthanAlarmScheduler {

  static const String athanPath = "assets/audio/athan.mp3";

  // Check which prayer to schedule it for
  static Future<void> scheduleAlarm(tz.TZDateTime dateTime, PrayerItem prayer) async {
    
    final name = prayer.name;
    final time = prayer.startTime;

    final alarmSettings = AlarmSettings(
        id: 30,
        dateTime: dateTime,
        assetAudioPath: athanPath,
        loopAudio: false,
        vibrate: false,
        notificationTitle: 'It is time for $name athan.',
        notificationBody: '$name is at $time today in Kelowna.',
        enableNotificationOnKill: Platform.isIOS,
      );

      try {
        await Alarm.set(alarmSettings: alarmSettings);
      } catch (e) {
        print(e);
      }
  }
}
