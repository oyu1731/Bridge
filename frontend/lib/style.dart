import 'package:flutter/material.dart';

class AppTheme {
  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errorOrange = Color.fromARGB(255, 239, 108, 0);
  static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);
  static const Color accentOrange = Color(0xFFFF9100);


  static const Color themeGray = Color(0xFF616161);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFFA000);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyanDark,
        primary: cyanDark,
        error: errorOrange,
      ),

      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: textCyanDark,
        displayColor: textCyanDark,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: cyanMedium,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: textCyanDark),
        hintStyle: TextStyle(color: textCyanDark),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cyanDark, width: 1.0),
        ),
        errorStyle: TextStyle(color: errorOrange),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorOrange),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorOrange, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // 独自のスタイルが必要な場合のみこれを使う（色は自動で textCyanDark になります）
  static const TextStyle mainTextStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle subTextStyle = TextStyle(fontSize: 15);
}