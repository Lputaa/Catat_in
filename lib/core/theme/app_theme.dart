import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  // Medieval Colors
  static const primaryColor = Color(0xFF4A7c59); // Forest green
  
  // Light Theme Colors
  static const parchmentBg = Color(0xFFEBE0C3);
  static const parchmentSurface = Color(0xFFF5EEDC);
  static const lightBorderColor = Color(0xFF4A3424); // Dark wood

  // Dark Theme Colors
  static const stoneBg = Color(0xFF1E2124);
  static const darkWoodSurface = Color(0xFF382A20);
  static const darkBorderColor = Color(0xFF120E0A); // Very dark brown

  static final lightTheme = ThemeData(
    useMaterial3: true,
    
    // Pixel Font
    textTheme: GoogleFonts.vt323TextTheme(ThemeData.light().textTheme),

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: parchmentBg,
      primaryContainer: parchmentSurface,
    ),

    scaffoldBackgroundColor: parchmentBg,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: parchmentBg,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: lightBorderColor),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: parchmentSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // 8-bit blocky look
        side: BorderSide(color: lightBorderColor, width: 3), // Thick borders
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: parchmentSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: lightBorderColor, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: lightBorderColor, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: primaryColor, width: 4),
      ),
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: lightBorderColor, width: 3),
      ),
    ),
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: parchmentSurface,
      indicatorColor: primaryColor.withValues(alpha: 0.3),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: lightBorderColor, width: 3),
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: lightBorderColor, width: 3),
        ),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,
    
    // Pixel Font
    textTheme: GoogleFonts.vt323TextTheme(ThemeData.dark().textTheme),

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: stoneBg,
      primaryContainer: darkWoodSurface,
    ),

    scaffoldBackgroundColor: stoneBg,
    
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: stoneBg,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkWoodSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: darkBorderColor, width: 3),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: darkWoodSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: darkBorderColor, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: darkBorderColor, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: primaryColor, width: 4),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: darkBorderColor, width: 3),
      ),
    ),
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkWoodSurface,
      indicatorColor: primaryColor.withValues(alpha: 0.3),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: darkBorderColor, width: 3),
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: darkBorderColor, width: 3),
        ),
      ),
    ),
  );
}