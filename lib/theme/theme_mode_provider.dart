import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider with ChangeNotifier {

  SharedPreferences prefs;
  ThemeModeProvider({ required this.prefs });

  ThemeMode get themeMode {
    String? userValue = prefs.getString("theme");
    return _stringToThemeMode(userValue);
  }

  String? get themeModeStringValue {
    String? userValue = prefs.getString("theme");
    return userValue;
  }

  setThemeMode(String? stringValue) {
    prefs.setString("theme", stringValue!).then((value) => 
      notifyListeners()
    );
  }
  
  ThemeMode _stringToThemeMode(String? textValue) {
    if (textValue == "Dark") {
      return ThemeMode.dark;
    } else if (textValue == "Light") {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }
}