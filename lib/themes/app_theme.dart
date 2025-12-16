import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFCD2970);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme(
        brightness: Brightness.light,

        primary: primary,
        onPrimary: Colors.white,

        secondary: primary,
        onSecondary: Colors.white,

        background: Colors.white,
        onBackground: Colors.black,

        surface: Colors.white,
        onSurface: Colors.black,

        error: Colors.red,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: GoogleFonts.rubikTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }

  // =========================
  // 🌙 DARK THEME
  // =========================
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,

        primary: primary,
        onPrimary: Colors.white,

        secondary: primary,
        onSecondary: Colors.white,

        background: const Color(0xFF121212),
        onBackground: Colors.white,

        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,

        error: Colors.red,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: GoogleFonts.rubikTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}