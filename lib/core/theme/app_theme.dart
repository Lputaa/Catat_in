import 'package:flutter/material.dart';

class AppTheme {

  static const primaryColor =
      Color(0xFF22C55E);

  static final lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor:
        const Color(0xFFF8FAFC),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      elevation: 0,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
    ),

    inputDecorationTheme:
        InputDecorationTheme(

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),

            borderSide: BorderSide.none,
          ),

      focusedBorder:
          OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),

            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor:
        const Color(0xFF0F172A),

    cardTheme: CardThemeData(
      elevation: 0,

      color: const Color(0xFF1E293B),

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
    ),

    inputDecorationTheme:
        InputDecorationTheme(

      filled: true,

      fillColor:
          const Color(0xFF1E293B),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),
    ),
  );
}