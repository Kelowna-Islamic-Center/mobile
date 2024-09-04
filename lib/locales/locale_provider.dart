// ignore: prefer_double_quotes
import 'package:flutter/material.dart';
import "package:shared_preferences/shared_preferences.dart";

class LocaleProvider with ChangeNotifier {

  SharedPreferences prefs;
  LocaleProvider({required this.prefs});

  Locale? get locale {
    String? userValue = prefs.getString("locale");
    return (userValue == null) ? null : Locale(userValue);
  }

  String? get localeStringValue {
    String? userValue = prefs.getString("locale");
    return userValue;
  }

  setLocale(String? stringValue) {
    if (stringValue == null) {
      prefs.remove("locale").then((value) => notifyListeners());
    } else {
      prefs.setString("locale", stringValue).then((value) => notifyListeners());
    }
  }
}
