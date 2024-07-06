import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData _baseTheme(Brightness brightness) {
    return ThemeData(
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
    Color(0xff128c3f), Color(0xff109e8e),
  ]);
}

