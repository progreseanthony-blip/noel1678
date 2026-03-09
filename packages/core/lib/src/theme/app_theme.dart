import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New primary palette (from design)
  static const Color primaryGreen = Color(0xFF11D411);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102210);

  // Legacy/Slate palette (kept for compatibility)
  static const Color primarySlate = Color(0xFF0F172A);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textGray = Color(0xFF475569);
  static const Color textGrayLight = Color(0xFF94A3B8);
  static const Color errorRed = Color(0xFFEF4444);

  // Slate shades for forms
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  static TextStyle get _manrope => GoogleFonts.manrope();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primarySlate,
        surface: Colors.white,
        background: backgroundLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: slate900,
        onBackground: slate900,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          color: slate900,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: GoogleFonts.manrope(
          color: slate900,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.manrope(
          color: slate900,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.manrope(
          color: slate900,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.manrope(
          color: textGray,
        ),
        bodyMedium: GoogleFonts.manrope(
          color: textGray,
        ),
        labelLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primarySlate,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: primaryGreen.withOpacity(0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.6), width: 2),
        ),
        labelStyle: GoogleFonts.manrope(color: slate700, fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle: GoogleFonts.manrope(color: slate400),
      ),
    );
  }
}

