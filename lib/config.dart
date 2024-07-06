
import 'package:flutter/material.dart';

class Config {
  static String apiLink = "https://prayertimesfetch-ilgk6gl75q-uc.a.run.app";
  static String apiLinkForNextDay = "https://prayertimesfetch-ilgk6gl75q-uc.a.run.app?day=tomorrow";
}

class AppTheme {
  static final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.green,
      ),
      brightness: Brightness.light,
    );

  static final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: Colors.green,
      ),
      brightness: Brightness.dark,
    );
}