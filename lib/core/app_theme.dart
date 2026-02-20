import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryLight = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF6366F1);  // Indigo 500
  
  static const Color secondaryLight = Color(0xFF0D9488); // Teal 600
  static const Color secondaryDark = Color(0xFF14B8A6);  // Teal 500
  
  static const Color backgroundLight = Color(0xFFF3F4F6); // Gray 100
  static const Color backgroundDark = Color(0xFF111827);  // Gray 900
  
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1F2937);     // Gray 800

  // Compact Text Theme (Instagram/WhatsApp style)
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      // Headings - Compact
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      
      // Titles - Compact
      titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      
      // Body - Compact like modern apps
      bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
      
      // Labels - Small
      labelLarge: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
    );
  }

  // Light Theme
  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: Color(0xFFDC2626), // Red 600
      ),
      // TEXT THEME - Black text for light mode
      textTheme: _buildTextTheme(base.textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      
      // AppBar Theme - Minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceLight,
        foregroundColor: Colors.black87,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      
      // Card Theme - Round corners
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceLight,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      
      // Input Theme - Compact, wide, round
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // CRITICAL FIX: Explicit text colors for light mode
        labelStyle: const TextStyle(color: Colors.black87, fontSize: 15),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        floatingLabelStyle: const TextStyle(color: primaryLight, fontSize: 16),
        isDense: false,
      ),
      
      // Button Theme - Compact, round
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 2,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      // Floating Action Button - Round
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(color: primaryLight, size: 22),
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: Color(0xFFEF4444), // Red 500
      ),
      textTheme: _buildTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      
      // AppBar Theme - Minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Card Theme - Round corners
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceDark,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      
      // Input Theme - Compact, wide, round
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // Explicit text colors for dark mode
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryDark),
        isDense: true,
      ),
      
      // Button Theme - Compact, round
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 2,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      // Floating Action Button - Round
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
       // Icon Theme
      iconTheme: const IconThemeData(color: primaryDark, size: 22),
    );
  }
}
