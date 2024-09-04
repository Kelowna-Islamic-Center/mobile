import "package:flutter/material.dart";

class AppTheme {
  static ThemeData _baseTheme(Brightness brightness) {
    return ThemeData(
      fontFamily: "Inter",
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: Colors.green,
      ),
      brightness: brightness,
    );
  }

  static final light = _baseTheme(Brightness.light);
  static final dark = _baseTheme(Brightness.dark);

  static const LinearGradient gradient = LinearGradient(colors: [
    Color.fromARGB(255, 29, 174, 82), Color.fromARGB(255, 9, 168, 152),
  ]);
}

