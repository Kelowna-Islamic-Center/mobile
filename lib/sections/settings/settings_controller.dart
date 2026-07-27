import "dart:async";
import "dart:io";

import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/services/cloud_messaging_service.dart";
import "package:kelowna_islamic_center/services/prayer_alert_scheduler_service.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";

class SettingsController {
  final Map<String, dynamic> settings = {};
  final Function(Map<String, dynamic>) onSettingsChanged;
  late SharedPreferences prefs;

  SettingsController({required this.onSettingsChanged});

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await _setToStoredValues();
  }

  // Set settings values to data stored in SharedPreferences
  Future<void> _setToStoredValues() async {

    for (MapEntry<String, dynamic> entry in Config.defaultSettings.entries) {
      String key = entry.key;
      dynamic defaultValue = entry.value;
      dynamic value;

      if (defaultValue is int) {
        value = prefs.getInt(key);
      } else if (defaultValue is String) {
        value = prefs.getString(key);
      } else if (defaultValue is bool) {
        value = prefs.getBool(key);
      }

      if (value == null) {
        // Value not set by user, save the default
        await updateValue(key, defaultValue);
      } else {
        // Value exists, use it
        settings[key] = value;
      }
    }

    onSettingsChanged(settings);
  }

  Future<bool> updateValue(String key, dynamic value) async {
    if (key == "athanTimeAlert" && value is bool && value && Platform.isAndroid) {
      PermissionStatus status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        status = await Permission.scheduleExactAlarm.request();
      }

      if (!status.isGranted) {
        return false;
      }
    }

    await subscriptionHandler(key, value);

    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Update internal map and notify the widget
    settings[key] = value;
    onSettingsChanged(settings);
    
    return true;
  }

  // Individual handlers for each settings change
  static Future<void> subscriptionHandler(String key, dynamic value) async {

    if (key == "announcementAlert" && value is bool) {
      if (value) {
        unawaited(CloudMessagingService.subscribeToTopic(Config.announcementTopic));
      } else {
        unawaited(CloudMessagingService.unsubscribeFromTopic(Config.announcementTopic));
      }
    }

    if (key == "athanTimeAlert" && value is bool) {
      unawaited(PrayerAlertSchedulerService.reconcileSchedules(force: true));
    }

    if (key == "iqamahTimeAlert" && value is bool) {
      unawaited(PrayerAlertSchedulerService.reconcileSchedules(force: true));
    }

    if (key == "iqamahTimeAlertTime" && value is int) {
      unawaited(PrayerAlertSchedulerService.reconcileSchedules(force: true));
    }
  }
}
