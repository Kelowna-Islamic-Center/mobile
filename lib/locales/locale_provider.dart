import "dart:ui";
import "package:flutter/material.dart";
import "package:kelowna_islamic_center/config.dart";
import "package:kelowna_islamic_center/locales/global_localization_service.dart";
import "package:kelowna_islamic_center/services/cloud_messaging_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocaleProvider with ChangeNotifier {

  SharedPreferences prefs;
  String? _lastLocale;
  
  LocaleProvider({required this.prefs}) {
    _lastLocale = prefs.getString("locale");

    // Initialize the GlobalLocalizationService for context-free localization access in UI-less elements
    GlobalLocalizationService localizationService = GlobalLocalizationService();
    localizationService.initialize(this);
    
    setLocale(_lastLocale); // Set locale on initial app launch
  }

  Locale? get locale {
    String? userValue = prefs.getString("locale");
    return (userValue == null) ? null : Locale(userValue);
  }

  String? get localeStringValue {
    String? userValue = prefs.getString("locale");
    return userValue;
  }

  // Update value in shared prefs and subscribe to the locale firebase topic for localized cloud messages
  Future<void> setLocale(String? stringValue) async {
    try {
      if (stringValue == null) {
        Locale deviceLocale = PlatformDispatcher.instance.locale;

        if (_lastLocale != null) {
          await CloudMessagingService.unsubscribeFromTopic("${Config.localeTopicPrefix}$_lastLocale");
        }

        await CloudMessagingService.subscribeToTopic("${Config.localeTopicPrefix}${deviceLocale.languageCode}");
        await prefs.remove("locale");

        _lastLocale = deviceLocale.languageCode;
      } else {
        await CloudMessagingService.subscribeToTopic("${Config.localeTopicPrefix}$stringValue");
        await prefs.setString("locale", stringValue);

        if (_lastLocale != null && _lastLocale != stringValue) {
          await CloudMessagingService.unsubscribeFromTopic("${Config.localeTopicPrefix}$_lastLocale");
        }

        _lastLocale = stringValue;
      }

      notifyListeners();
    } catch (e) {
      // This should be handled in the future by showing an error message.
    }
  }
}
