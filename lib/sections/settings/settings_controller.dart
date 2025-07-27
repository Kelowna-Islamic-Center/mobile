import "dart:async";

import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/services/cloud_messaging_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class SettingsController {
  final Map<String, dynamic> settings = {};
  final Function(Map<String, dynamic>) onSettingsChanged;

  SettingsController({required this.onSettingsChanged});

  Future<void> init() async {
    await _setToStoredValues();
  }

  Future<void> _setToStoredValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

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
        await updateValue(key, defaultValue);
      } else {
        settings[key] = value;
      }
    }

    onSettingsChanged(settings);
  }

  Future<void> updateValue(String key, dynamic value) async {
    await _customHandler(key, value);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    settings[key] = value;
    onSettingsChanged(settings);
  }

  Future<void> _customHandler(String key, dynamic value) async {
    if (key == "announcementAlert" && value is bool) {
      if (value) {
        unawaited(CloudMessagingService.subscribeToTopic(Config.announcementTopic));
      } else {
        unawaited(CloudMessagingService.unsubscribeFromTopic(Config.announcementTopic));
      }
    }

    if (key == "athanTimeAlert" && value is bool) {
      if (value) {
        unawaited(CloudMessagingService.subscribeToTopic(Config.athanAlertTopic));
      } else {
        unawaited(CloudMessagingService.unsubscribeFromTopic(Config.athanAlertTopic));
      }
    }

    if (key == "iqamahTimeAlert" && value is bool) {
      if (value) {
        unawaited(CloudMessagingService.subscribeToTopic(Config.iqamahAlertTopic));
      } else {
        unawaited(CloudMessagingService.unsubscribeFromTopic(Config.iqamahAlertTopic));
      }
    }
  }
}
